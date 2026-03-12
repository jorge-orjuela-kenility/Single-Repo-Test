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

if [ -z "$UTILS_LINK" ]; then
  echo "ERROR: Missing COCOAPODS_UTILS_LINK" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is not installed." >&2
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

download_google_drive_file() {
  local file_id="$1"
  local output_path="$2"
  local cookie_file
  local confirm_file
  local confirm_token

  cookie_file="$(mktemp)"
  confirm_file="$(mktemp)"

  cleanup() {
    rm -f "$cookie_file" "$confirm_file"
  }
  trap cleanup RETURN

  echo "== Downloading Google Drive artifact =="

  curl -fsSL -c "$cookie_file" \
    "https://drive.google.com/uc?export=download&id=${file_id}" \
    -o "$confirm_file"

  if file "$confirm_file" | grep -qi 'Zip archive'; then
    mv "$confirm_file" "$output_path"
    return 0
  fi

  confirm_token="$(sed -n 's/.*confirm=\([0-9A-Za-z_-]*\).*/\1/p' "$confirm_file" | head -n 1)"

  if [ -z "$confirm_token" ]; then
    echo "ERROR: Could not obtain Google Drive confirmation token." >&2
    echo "Make sure the file is shared correctly and the link is valid." >&2
    return 1
  fi

  curl -fsSL -Lb "$cookie_file" \
    "https://drive.google.com/uc?export=download&confirm=${confirm_token}&id=${file_id}" \
    -o "$output_path"
}

download_file() {
  local url="$1"
  local output_path="$2"
  local file_id=""

  if printf '%s' "$url" | grep -q 'drive.google.com'; then
    file_id="$(printf '%s' "$url" | sed -n 's#.*\/file\/d\/\([^/]*\)\/.*#\1#p')"

    if [ -z "$file_id" ]; then
      file_id="$(printf '%s' "$url" | sed -n 's/.*[?&]id=\([^&]*\).*/\1/p')"
    fi

    if [ -z "$file_id" ]; then
      echo "ERROR: Could not extract Google Drive file id from COCOAPODS_UTILS_LINK" >&2
      return 1
    fi

    download_google_drive_file "$file_id" "$output_path"
  else
    echo "== Downloading artifact from direct URL =="
    curl -fsSL "$url" -o "$output_path"
  fi
}

download_file "$UTILS_LINK" "$UTILS_ZIP"

if [ ! -f "$UTILS_ZIP" ]; then
  echo "ERROR: Failed to download utils zip: $UTILS_ZIP" >&2
  exit 1
fi

unzip -q "$UTILS_ZIP" -d "$UTILS_EXTRACT_DIR"