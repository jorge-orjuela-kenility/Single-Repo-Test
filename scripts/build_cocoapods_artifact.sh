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
UTILS_LINK="${COCOAPODS_UTILS_LINK:-}"
UTILS_ZIP="$DIST_ROOT/utils.zip"

if [ -z "$UTILS_LINK" ]; then
  echo "ERROR: Missing COCOAPODS_UTILS_LINK" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is not installed." >&2
  exit 1
fi

mkdir -p "$DIST_ROOT"
rm -f "$UTILS_ZIP"

extract_google_drive_file_id() {
  local url="$1"
  local file_id=""

  file_id="$(printf '%s' "$url" | sed -n 's#.*\/file\/d\/\([^/]*\)\/.*#\1#p')"

  if [ -z "$file_id" ]; then
    file_id="$(printf '%s' "$url" | sed -n 's/.*[?&]id=\([^&]*\).*/\1/p')"
  fi

  printf '%s' "$file_id"
}

download_google_drive_file() {
  local file_id="$1"
  local output_path="$2"

  local cookie_file
  local confirm_page
  local confirm_token

  cookie_file="$(mktemp)"
  confirm_page="$(mktemp)"

  cleanup() {
    rm -f "$cookie_file" "$confirm_page"
  }
  trap cleanup RETURN

  echo "Downloading from Google Drive (file id: $file_id)"

  curl -fsSL -c "$cookie_file" \
    "https://drive.google.com/uc?export=download&id=${file_id}" \
    -o "$confirm_page"

  if file "$confirm_page" | grep -qi 'Zip archive'; then
    mv "$confirm_page" "$output_path"
    return 0
  fi

  confirm_token="$(sed -n 's/.*confirm=\([0-9A-Za-z_-]*\).*/\1/p' "$confirm_page" | head -n 1)"

  if [ -z "$confirm_token" ]; then
    echo "ERROR: Could not obtain Google Drive confirmation token." >&2
    exit 1
  fi

  curl -fsSL -Lb "$cookie_file" \
    "https://drive.google.com/uc?export=download&confirm=${confirm_token}&id=${file_id}" \
    -o "$output_path"
}

download_file() {
  local url="$1"
  local output="$2"

  if printf '%s' "$url" | grep -q "drive.google.com"; then
    file_id="$(extract_google_drive_file_id "$url")"

    if [ -z "$file_id" ]; then
      echo "ERROR: Could not extract Google Drive file id." >&2
      exit 1
    fi

    download_google_drive_file "$file_id" "$output"
  else
    echo "Downloading from direct URL"
    curl -fsSL "$url" -o "$output"
  fi
}

download_file "$UTILS_LINK" "$UTILS_ZIP"

if [ ! -f "$UTILS_ZIP" ]; then
  echo "ERROR: Download failed." >&2
  exit 1
fi

echo "✅ File downloaded successfully:"
echo "   $UTILS_ZIP"