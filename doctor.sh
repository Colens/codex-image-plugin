#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib-node.sh
source "${SCRIPT_DIR}/scripts/lib-node.sh"

CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
PLUGIN_DIR="${CODEX_HOME}/marketplaces/cobabaai/plugins/cobabaai-image"
CONFIG_PATH="${CODEX_HOME}/config.toml"
ENV_FILE_PATH="${CODEX_HOME}/cobabaai-image.env"

check() {
  local ok="$1"
  local msg="$2"
  if [[ "${ok}" == "1" ]]; then
    printf '  \033[32m[OK]\033[0m %s\n' "${msg}"
  else
    printf '  \033[31m[!!]\033[0m %s\n' "${msg}"
  fi
  return $((1 - ok))
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

mask_key() {
  local key="$1"
  local len="${#key}"
  if (( len > 8 )); then
    printf '%s****%s\n' "${key:0:4}" "${key: -4}"
  else
    printf '****\n'
  fi
}

printf '\n  CobabaAi 生图 - 环境自检\n\n'

all_ok=1

if [[ -d "${PLUGIN_DIR}" ]]; then
  check 1 "插件目录: ${PLUGIN_DIR}" || all_ok=0
else
  check 0 "插件目录不存在: ${PLUGIN_DIR}" || all_ok=0
fi

if [[ -f "${PLUGIN_DIR}/server/index.js" ]]; then
  check 1 "MCP 服务入口 server/index.js" || all_ok=0
else
  check 0 "MCP 服务入口缺失" || all_ok=0
fi

runtime_node="$(codex_installed_node_exe || true)"
if [[ -n "${runtime_node}" ]]; then
  check 1 "便携 Node: ${runtime_node}" || all_ok=0
else
  check 0 "便携 Node 未安装（请运行 ./install.sh）" || all_ok=0
fi

if [[ -f "${CONFIG_PATH}" ]] && grep -qE 'cobabaai-image@(cobabaai-local|cobabaai)' "${CONFIG_PATH}" && grep -q 'cobabaai-image"' "${CONFIG_PATH}"; then
  check 1 "config.toml MCP 配置" || all_ok=0
else
  check 0 "config.toml 缺少 MCP 配置（请运行 ./install.sh）" || all_ok=0
fi

file_key="$(read_key_from_env_file "${ENV_FILE_PATH}" || true)"
env_key="${COBABAAI_API_KEY:-}"
key="${file_key:-${env_key}}"
key_source="cobabaai-image.env"
if [[ -z "${file_key}" && -n "${env_key}" ]]; then
  key_source="环境变量"
fi

if [[ -n "${key}" ]]; then
  check 1 "API 密钥已配置 (${key_source}): $(mask_key "${key}")" || all_ok=0
else
  check 0 "未配置 API 密钥（请运行 ./configure-key.sh）" || all_ok=0
fi

if [[ -n "${runtime_node}" && -f "${SCRIPT_DIR}/scripts/test-mcp-load.js" ]]; then
  load_result="$("${runtime_node}" "${SCRIPT_DIR}/scripts/test-mcp-load.js" 2>/dev/null || echo missing)"
  if [[ "${load_result}" == "loaded" ]]; then
    check 1 "MCP 进程可读密钥（loadLocalConfig）" || all_ok=0
  else
    check 0 "MCP 密钥加载失败" || all_ok=0
  fi
fi

printf '\n'
if [[ "${all_ok}" -eq 1 ]]; then
  printf '  \033[32m全部通过。请重启 Codex → 新对话 → @ CobabaAi 生图 → 说「画一只在月球上喝酒的猫」\033[0m\n\n'
  exit 0
fi

printf '  \033[33m存在问题。请运行 ./install.sh 修复，配置密钥后完全重启 Codex。\033[0m\n\n'
exit 1
