#!/usr/bin/env bash
set -Eeuo pipefail

UTILS_LINK="${COCOAPODS_UTILS_LINK:-}"
OUTPUT="${OUTPUT_PATH:-dist/utils.zip}"

if [ -z "$UTILS_LINK" ]; then
  echo "ERROR: Missing COCOAPODS_UTILS_LINK" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

curl -fL "$UTILS_LINK" -o "$OUTPUT"

test -s "$OUTPUT" || {
  echo "ERROR: Download failed or produced an empty file." >&2
  exit 1
}

echo "Downloaded to $OUTPUT"