#!/usr/bin/env bash

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

codex_home() {
  echo "${CODEX_HOME:-${HOME}/.codex}"
}

bundled_node_exe() {
  local root="$1"
  local candidate
  for candidate in \
    "${root}/packages/node/bin/node" \
    "${root}/packages/node/node"; do
    if [[ -x "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done
  return 1
}

codex_installed_node_exe() {
  local candidate
  for candidate in \
    "$(codex_home)/packages/node/bin/node" \
    "$(codex_home)/packages/node/node"; do
    if [[ -x "${candidate}" ]]; then
      echo "${candidate}"
      return 0
    fi
  done
  return 1
}

install_node_to_codex_home() {
  local source_root="$1"
  local source_dir="${source_root}/packages/node"
  local dest_dir
  dest_dir="$(codex_home)/packages/node"

  [[ -d "${source_dir}" ]] || return 1
  rm -rf "${dest_dir}"
  mkdir -p "${dest_dir}"
  cp -R "${source_dir}/." "${dest_dir}/"
  codex_installed_node_exe
}

use_portable_node() {
  local node_exe="$1"
  export PATH="$(dirname "${node_exe}"):${PATH}"
}

invoke_plugin_npm_install() {
  local plugin_dir="$1"
  local node_exe="$2"
  local npm_cli
  npm_cli="$(dirname "${node_exe}")/npm"
  use_portable_node "${node_exe}"
  (
    cd "${plugin_dir}"
    if [[ -x "${npm_cli}" ]]; then
      "${npm_cli}" install --omit=dev
      "${npm_cli}" run build
    else
      npm install --omit=dev
      npm run build
    fi
  )
}

resolve_node_for_install() {
  local repo_root="$1"
  local mode="${2:-Auto}"
  local node_exe

  if node_exe="$(bundled_node_exe "${repo_root}")"; then
    echo "bundled"
    echo "${node_exe}"
    return 0
  fi

  if [[ "${mode}" == "BundledOnly" ]]; then
    echo "未找到内置 Node。网盘版请确认 packages/node/bin/node 存在。" >&2
    return 1
  fi

  "$(dirname "${BASH_SOURCE[0]}")/ensure-node.sh" "${repo_root}"
  node_exe="$(bundled_node_exe "${repo_root}")" || {
    echo "自动下载 Node 失败。" >&2
    return 1
  }
  echo "downloaded"
  echo "${node_exe}"
}

format_toml_path() {
  echo "$1"
}
