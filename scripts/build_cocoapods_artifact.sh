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

if ! command -v unzip >/dev/null 2>&1; then
  echo "ERROR: unzip is not installed." >&2
  exit 1
fi

rm -rf "$PODROOT" "$UTILS_EXTRACT_DIR"
rm -f "$UTILS_ZIP" "$OUTPUT_ZIP"
mkdir -p "$FRAMEWORKS_DIR" "$UTILS_EXTRACT_DIR" "$DIST_ROOT"

echo "== Copying generated SDK xcframeworks =="

SDK_FRAMEWORKS="$(find "$XCROOT" -maxdepth 1 -type d -name "*.xcframework" | sort)"

download_google_drive_file() {
  local file_id="$1"
  local output_path="$2"
  local cookie_file
  local first_response
  local confirm_token

  cookie_file="$(mktemp)"
  first_response="$(mktemp)"

  cleanup_download_temp_files() {
    rm -f "$cookie_file" "$first_response"
  }

  trap cleanup_download_temp_files RETURN

  echo "== Downloading Google Drive artifact =="
  echo "   file id: $file_id"

  curl -fsSL -c "$cookie_file" \
    "https://drive.google.com/uc?export=download&id=${file_id}" \
    -o "$first_response"

  if file "$first_response" | grep -qi 'Zip archive'; then
    mv "$first_response" "$output_path"
    return 0
  fi

  confirm_token="$(sed -n 's/.*confirm=\([0-9A-Za-z_-]*\).*/\1/p' "$first_response" | head -n 1)"

  if [ -z "$confirm_token" ]; then
    echo "ERROR: Could not obtain Google Drive confirmation token." >&2
    echo "Make sure the file is publicly accessible or shared correctly." >&2
    return 1
  fi

  curl -fsSL -Lb "$cookie_file" \
    "https://drive.google.com/uc?export=download&confirm=${confirm_token}&id=${file_id}" \
    -o "$output_path"
}

extract_google_drive_file_id() {
  local url="$1"
  local file_id=""

  file_id="$(printf '%s' "$url" | sed -n 's#.*\/file\/d\/\([^/]*\)\/.*#\1#p')"

  if [ -z "$file_id" ]; then
    file_id="$(printf '%s' "$url" | sed -n 's/.*[?&]id=\([^&]*\).*/\1/p')"
  fi

  printf '%s' "$file_id"
}

download_file() {
  local url="$1"
  local output_path="$2"
  local file_id=""

  if printf '%s' "$url" | grep -q 'drive.google.com'; then
    file_id="$(extract_google_drive_file_id "$url")"

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

echo "== Extracting utils zip =="
unzip -q "$UTILS_ZIP" -d "$UTILS_EXTRACT_DIR"

echo "== Validating extracted utils content =="
if [ -z "$(find "$UTILS_EXTRACT_DIR" -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
  echo "ERROR: Utils zip was extracted but appears to be empty." >&2
  exit 1
fi

echo "== Copying extracted utils into CocoaPods package =="
find "$UTILS_EXTRACT_DIR" -mindepth 1 -maxdepth 1 | while IFS= read -r item; do
  [ -n "$item" ] || continue
  echo "  -> $(basename "$item")"
  cp -R "$item" "$PODROOT"/
done

echo "== Creating output archive =="
(
  cd "$DIST_ROOT"
  zip -qry "$(basename "$OUTPUT_ZIP")" "$(basename "$PODROOT")"
)

if [ ! -f "$OUTPUT_ZIP" ]; then
  echo "ERROR: Failed to create output zip: $OUTPUT_ZIP" >&2
  exit 1
fi

echo "✅ CocoaPods artifact created successfully:"
echo "   $OUTPUT_ZIP"