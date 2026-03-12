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
XCROOT="${XCROOT:-$WORKSPACE/DerivedData/XCFrameworks}"
DIST_ROOT="${DIST_ROOT:-$WORKSPACE/dist}"
UTILS_LINK="${COCOAPODS_UTILS_LINK:-}"
OUTPUT_NAME="${OUTPUT_NAME:-TruvideoSdk.zip}"

PODROOT="$DIST_ROOT/cocoapods"
FRAMEWORKS_DIR="$PODROOT/Frameworks"
OUTPUT_ZIP="$DIST_ROOT/$OUTPUT_NAME"

UTILS_ZIP="$DIST_ROOT/utils.zip"
UTILS_EXTRACT_DIR="$DIST_ROOT/utils"

if [ ! -d "$XCROOT" ]; then
  echo "ERROR: Missing xcframework output folder: $XCROOT" >&2
  exit 1
fi

if [ -z "$UTILS_LINK" ]; then
  echo "ERROR: Missing COCOAPODS_UTILS_LINK" >&2
  exit 1
fi

if ! command -v gdown >/dev/null 2>&1; then
  echo "ERROR: gdown is not installed. Install it before running this script." >&2
  exit 1
fi

rm -rf "$PODROOT" "$UTILS_EXTRACT_DIR"
rm -f "$UTILS_ZIP" "$OUTPUT_ZIP"
mkdir -p "$FRAMEWORKS_DIR" "$UTILS_EXTRACT_DIR"

echo "== Copying generated SDK xcframeworks =="
mapfile -t SDK_FRAMEWORKS < <(find "$XCROOT" -maxdepth 1 -type d -name "*.xcframework" | sort)

if [ "${#SDK_FRAMEWORKS[@]}" -eq 0 ]; then
  echo "ERROR: No SDK xcframeworks found in $XCROOT" >&2
  exit 1
fi

for fw in "${SDK_FRAMEWORKS[@]}"; do
  echo "  -> $(basename "$fw")"
  cp -R "$fw" "$FRAMEWORKS_DIR"/
done

FILE_ID="$(printf '%s' "$UTILS_LINK" | sed -n 's/.*id=\([^&]*\).*/\1/p')"

if [ -z "$FILE_ID" ]; then
  echo "ERROR: Could not extract Google Drive file id from COCOAPODS_UTILS_LINK" >&2
  exit 1
fi

gdown "$FILE_ID" -O "$UTILS_ZIP"

if [ ! -f "$UTILS_ZIP" ]; then
  echo "ERROR: Failed to download utils zip: $UTILS_ZIP" >&2
  exit 1
fi

unzip -q "$UTILS_ZIP" -d "$UTILS_EXTRACT_DIR"

echo "== Copying utils xcframeworks =="
mapfile -t UTILS_FRAMEWORKS < <(find "$UTILS_EXTRACT_DIR" -type d -name "*.xcframework" | sort)

if [ "${#UTILS_FRAMEWORKS[@]}" -eq 0 ]; then
  echo "ERROR: No .xcframework directories found in downloaded utils artifact" >&2
  find "$UTILS_EXTRACT_DIR" -maxdepth 5 | sort >&2 || true
  exit 1
fi

for fw in "${UTILS_FRAMEWORKS[@]}"; do
  echo "  -> $(basename "$fw")"
  cp -R "$fw" "$FRAMEWORKS_DIR"/
done

find "$FRAMEWORKS_DIR" -type d -name "_CodeSignature" -prune -exec rm -rf {} +
find "$FRAMEWORKS_DIR" -name ".DS_Store" -delete || true

(
  cd "$PODROOT"
  /usr/bin/zip -qry "$OUTPUT_ZIP" Frameworks
)

ls -la "$OUTPUT_ZIP"
