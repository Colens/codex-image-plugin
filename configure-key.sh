#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
ENV_FILE_PATH="${CODEX_HOME}/cobabaai-image.env"

write_utf8_file() {
  python3 - "$1" <<'PY'
import sys
from pathlib import Path
Path(sys.argv[1]).write_text(sys.stdin.read(), encoding="utf-8")
PY
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
    if value:
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

printf '\n  CobabaAi 生图 - API 密钥配置\n\n'

existing_key="$(read_key_from_env_file "${ENV_FILE_PATH}" || true)"
if [[ -z "${existing_key:-}" ]]; then
  existing_key="${COBABAAI_API_KEY:-}"
fi

if [[ -n "${existing_key:-}" ]]; then
  printf '  当前已配置: %s\n\n' "$(mask_key "${existing_key}")"
fi

printf '  从 cobabaai.com 控制台复制 sk- 开头的密钥\n'
printf '  粘贴 API 密钥（留空取消）: '
IFS= read -r input_key || true
input_key="$(echo "${input_key:-}" | xargs)"

if [[ -z "${input_key}" ]]; then
  printf '  已取消。\n'
  exit 0
fi

mkdir -p "$(dirname "${ENV_FILE_PATH}")"
write_utf8_file "${ENV_FILE_PATH}" <<EOF
# CobabaAi 生图插件配置
# 获取密钥: https://cobabaai.com/
COBABAAI_API_KEY=${input_key}
# 可选，默认 gpt-image-2
# COBABAAI_IMAGE_MODEL=gpt-image-2
EOF

# macOS/Linux: 写入当前 shell 配置文件，供 Codex env_vars 转发
profile_candidates=(
  "${HOME}/.zprofile"
  "${HOME}/.bash_profile"
  "${HOME}/.profile"
)
profile_updated=0
for profile in "${profile_candidates[@]}"; do
  if [[ -f "${profile}" ]]; then
    if grep -q '^export COBABAAI_API_KEY=' "${profile}" 2>/dev/null; then
      if [[ "$(uname -s)" == "Darwin" ]]; then
        sed -i '' "s|^export COBABAAI_API_KEY=.*|export COBABAAI_API_KEY=${input_key}|" "${profile}"
      else
        sed -i "s|^export COBABAAI_API_KEY=.*|export COBABAAI_API_KEY=${input_key}|" "${profile}"
      fi
    else
      printf '\n# CobabaAi 生图插件\nexport COBABAAI_API_KEY=%s\n' "${input_key}" >> "${profile}"
    fi
    profile_updated=1
    printf '  已同步到: %s\n' "${profile}"
    break
  fi
done
if [[ "${profile_updated}" -eq 0 ]]; then
  printf '  提示: 可将 export COBABAAI_API_KEY=... 加入 ~/.zprofile 后重启 Codex\n'
fi
export COBABAAI_API_KEY="${input_key}"

printf '\n  已保存到: %s\n' "${ENV_FILE_PATH}"
printf '  请重启 Codex 或新开对话后生效。\n\n'
