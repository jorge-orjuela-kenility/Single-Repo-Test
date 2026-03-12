#!/usr/bin/env bash
set -Eeuo pipefail
set -o errtrace

if [ "${DEBUG:-0}" = "1" ]; then
  set -x
fi

on_err() {
  local exit_code=$?
  echo "❌ ERROR (exit=$exit_code) at line $1" >&2
  echo "   Command: $2" >&2
}
trap 'on_err $LINENO "$BASH_COMMAND"' ERR

WORKSPACE="${WORKSPACE:-$PWD}"
DIST_ROOT="${DIST_ROOT:-$WORKSPACE/dist}"
UTILS_LINK="${COCOAPODS_UTILS_LINK:-https://github.com/jorge-orjuela-kenility/video-utils/releases/download/1.0.0/utils.zip}"
UTILS_ZIP="${OUTPUT_PATH:-$DIST_ROOT/utils.zip}"

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is not installed." >&2
  exit 1
fi

if ! command -v file >/dev/null 2>&1; then
  echo "ERROR: file is not installed." >&2
  exit 1
fi

mkdir -p "$DIST_ROOT"
rm -f "$UTILS_ZIP"

echo "== Downloading utils artifact =="
echo "   URL: $UTILS_LINK"

curl -fL "$UTILS_LINK" -o "$UTILS_ZIP"

if [ ! -f "$UTILS_ZIP" ] || [ ! -s "$UTILS_ZIP" ]; then
  echo "ERROR: Download failed or produced an empty file." >&2
  exit 1
fi

if ! file "$UTILS_ZIP" | grep -qi 'Zip archive'; then
  echo "ERROR: Downloaded file is not a zip." >&2
  echo "Detected type: $(file "$UTILS_ZIP")" >&2
  exit 1
fi

echo "✅ File downloaded successfully:"
echo "   $UTILS_ZIP"