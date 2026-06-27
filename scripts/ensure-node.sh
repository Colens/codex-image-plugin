#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
NODE_VERSION="${NODE_VERSION:-20.18.0}"
TARGET_DIR="${REPO_ROOT}/packages/node"
NODE_BIN="${TARGET_DIR}/bin/node"

if [[ -x "${NODE_BIN}" ]]; then
  echo "  [OK] Bundled Node already exists: ${NODE_BIN}"
  exit 0
fi

echo "  >> Downloading Node.js v${NODE_VERSION} for macOS..."
TMP_ROOT="$(mktemp -d)"
cleanup() { rm -rf "${TMP_ROOT}"; }
trap cleanup EXIT

ARCH="$(uname -m)"
case "${ARCH}" in
  arm64) NODE_ARCH="arm64" ;;
  x86_64) NODE_ARCH="x64" ;;
  *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;;
esac

TAR_NAME="node-v${NODE_VERSION}-darwin-${NODE_ARCH}.tar.gz"
URL="https://nodejs.org/dist/v${NODE_VERSION}/${TAR_NAME}"

curl -fsSL "${URL}" -o "${TMP_ROOT}/${TAR_NAME}"
tar -xzf "${TMP_ROOT}/${TAR_NAME}" -C "${TMP_ROOT}"
EXTRACTED="${TMP_ROOT}/node-v${NODE_VERSION}-darwin-${NODE_ARCH}"
[[ -d "${EXTRACTED}" ]] || { echo "Unexpected archive layout" >&2; exit 1; }

mkdir -p "${TARGET_DIR}"
cp -R "${EXTRACTED}/." "${TARGET_DIR}/"
echo "  [OK] Node installed to ${TARGET_DIR}"
