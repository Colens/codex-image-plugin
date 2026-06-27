#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib-node.sh
source "${SCRIPT_DIR}/scripts/lib-node.sh"

PLUGIN_SRC="${SCRIPT_DIR}/cobabaai-image-plugin"
REPO_ROOT="${SCRIPT_DIR}"
CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
MARKETPLACE_ROOT="${CODEX_HOME}/marketplaces/cobabaai-local"
PLUGIN_DEST="${MARKETPLACE_ROOT}/plugins/cobabaai-image"
CONFIG_PATH="${CODEX_HOME}/config.toml"
ENV_FILE_PATH="${CODEX_HOME}/cobabaai-image.env"

step() { printf '  >> %s\n' "$1"; }
ok() { printf '  [OK] %s\n' "$1"; }
warn() { printf '  [!!] %s\n' "$1"; }

write_utf8_file() {
  python3 - "$1" <<'PY'
import sys
from pathlib import Path
Path(sys.argv[1]).write_text(sys.stdin.read(), encoding="utf-8")
PY
}

find_codex_cli() {
  if [[ -n "${CODEX_BIN:-}" && -x "${CODEX_BIN}" ]]; then
    echo "${CODEX_BIN}"
    return 0
  fi
  if command -v codex >/dev/null 2>&1; then
    command -v codex
    return 0
  fi
  local mac_codex="/Applications/Codex.app/Contents/Resources/codex"
  if [[ -x "${mac_codex}" ]]; then
    echo "${mac_codex}"
    return 0
  fi
  return 1
}

read_key_from_env_file() {
  local path="$1"
  [[ -f "${path}" ]] || return 1
  python3 - "${path}" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
for line in path.read_text(encoding="utf-8").splitlines():
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        continue
    match = re.match(r"^COBABAAI_API_KEY\s*=\s*(.+)$", stripped)
    if not match:
        continue
    value = match.group(1).strip().strip('"').strip("'")
    if value and "你的密钥" not in value:
        print(value)
        break
PY
}

save_key_to_env_file() {
  local path="$1"
  local key="$2"
  mkdir -p "$(dirname "${path}")"
  write_utf8_file "${path}" <<EOF
# CobabaAi 生图插件配置
# 获取密钥: https://cobabaai.com/
COBABAAI_API_KEY=${key}
# 可选，默认 gpt-image-2
# COBABAAI_IMAGE_MODEL=gpt-image-2
EOF
}

printf '\n  ========================================\n'
printf '     CobabaAi Image Plugin Installer\n'
printf '  ========================================\n\n'

[[ -d "${PLUGIN_SRC}" ]] || {
  echo "Plugin directory not found: ${PLUGIN_SRC}" >&2
  exit 1
}

step 'Resolving Node.js (bundled or auto-download)...'
install_mode="Auto"
if [[ "${INSTALL_MODE:-}" == "netdisk" ]]; then
  install_mode="BundledOnly"
fi
mapfile -t node_lines < <(resolve_node_for_install "${REPO_ROOT}" "${install_mode}")
node_source="${node_lines[0]}"
node_exe="${node_lines[1]}"
ok "Using Node: ${node_exe} (${node_source})"

step 'Installing MCP dependencies...'
if [[ -d "${PLUGIN_SRC}/node_modules" ]]; then
  ok 'node_modules already present (netdisk release), running build only'
  use_portable_node "${node_exe}"
  (
    cd "${PLUGIN_SRC}"
    npm run build
  )
else
  invoke_plugin_npm_install "${PLUGIN_SRC}" "${node_exe}"
fi
ok 'Dependencies ready'

step 'Installing portable Node to ~/.codex/packages/node...'
runtime_node_exe="$(install_node_to_codex_home "${REPO_ROOT}")"
ok "Runtime Node: ${runtime_node_exe}"

step 'Deploying plugin to Codex...'
mkdir -p "$(dirname "${PLUGIN_DEST}")"
rm -rf "${PLUGIN_DEST}"
cp -R "${PLUGIN_SRC}" "${PLUGIN_DEST}"
ok "Plugin copied to ${PLUGIN_DEST}"

step 'Creating marketplace manifest...'
MARKETPLACE_MANIFEST="${MARKETPLACE_ROOT}/.agents/plugins/marketplace.json"
mkdir -p "$(dirname "${MARKETPLACE_MANIFEST}")"
write_utf8_file "${MARKETPLACE_MANIFEST}" <<'JSON'
{
  "name": "cobabaai-local",
  "interface": {
    "displayName": "CobabaAi Local"
  },
  "plugins": [
    {
      "name": "cobabaai-image",
      "source": {
        "source": "local",
        "path": "./plugins/cobabaai-image"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Creative"
    }
  ]
}
JSON
[[ -f "${MARKETPLACE_ROOT}/marketplace.json" ]] && rm -f "${MARKETPLACE_ROOT}/marketplace.json"
ok 'marketplace manifest created'

step 'Checking COBABAAI_API_KEY...'
existing_key="$(read_key_from_env_file "${ENV_FILE_PATH}" || true)"
if [[ -z "${existing_key:-}" ]]; then
  existing_key="${COBABAAI_API_KEY:-}"
fi

if [[ -z "${existing_key:-}" ]]; then
  warn 'COBABAAI_API_KEY not found'
  if [[ "${SKIP_KEY_PROMPT:-}" == "1" ]]; then
    warn 'SKIP_KEY_PROMPT=1, skipping key input'
  else
    printf '  Get your sk- key from cobabaai.com console\n'
    printf '  You can also run ./configure-key.sh later to configure the key.\n'
    printf '  Paste API key (leave empty to skip): '
    IFS= read -r input_key || true
    input_key="$(echo "${input_key:-}" | xargs)"
    if [[ -n "${input_key}" ]]; then
      save_key_to_env_file "${ENV_FILE_PATH}" "${input_key}"
      ok "API key saved to ${ENV_FILE_PATH}"
    else
      warn 'Skipped key setup. Run ./configure-key.sh later.'
    fi
  fi
else
  if [[ -z "$(read_key_from_env_file "${ENV_FILE_PATH}" || true)" ]]; then
    save_key_to_env_file "${ENV_FILE_PATH}" "${existing_key}"
    ok "Existing key copied to ${ENV_FILE_PATH}"
  else
    ok 'API key already configured in cobabaai-image.env'
  fi
fi

step 'Registering plugin with Codex CLI...'
if codex_cli="$(find_codex_cli)"; then
  ok "Codex CLI: ${codex_cli}"
  marketplace_status=0
  marketplace_add="$("${codex_cli}" plugin marketplace add "${MARKETPLACE_ROOT}" --enable plugins 2>&1)" || marketplace_status=$?
  if [[ "${marketplace_status}" -ne 0 ]] && [[ "${marketplace_add}" != *already\ added* ]]; then
    echo "${marketplace_add}" >&2
    exit 1
  fi
  "${codex_cli}" plugin add cobabaai-image@cobabaai-local --enable plugins
  ok 'Plugin registered and installed'
else
  warn 'Codex CLI not found. Restart Codex and run: codex plugin add cobabaai-image@cobabaai-local'
fi

step 'Updating Codex config.toml...'
mkdir -p "${CODEX_HOME}"
if [[ ! -f "${CONFIG_PATH}" ]] || ! grep -Fq '[plugins."cobabaai-image@cobabaai-local".mcp_servers.cobabaai-image]' "${CONFIG_PATH}"; then
  {
    [[ -f "${CONFIG_PATH}" && -s "${CONFIG_PATH}" ]] && printf '\n'
    cat <<TOML

[plugins."cobabaai-image@cobabaai-local".mcp_servers.cobabaai-image]
enabled = true
command = "${runtime_node_exe}"
args = ["server/index.js"]
default_tools_approval_mode = "prompt"
tool_timeout_sec = 600
env_vars = ["COBABAAI_API_KEY", "COBABAAI_IMAGE_MODEL"]
TOML
  } >> "${CONFIG_PATH}"
  ok 'MCP settings added to config.toml'
else
  ok 'MCP settings already in config.toml, skipped'
fi

printf '\n  ========================================\n'
printf '           Installation complete!\n'
printf '  ========================================\n\n'
printf '  Next steps:\n'
printf '  1. Restart Codex or start a new conversation\n'
printf '  2. Check @ Plugins -> CobabaAi 生图 is installed\n'
printf '  3. Try: use gpt-image-2 to generate a cat on the moon\n'
printf '  4. To change API key later, run ./configure-key.sh\n\n'
