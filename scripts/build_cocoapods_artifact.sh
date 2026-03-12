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

if ! file "$OUTPUT" | grep -qi 'Zip archive'; then
  echo "ERROR: Downloaded file is not a zip. Google Drive returned something else." >&2
  echo "Detected type: $(file "$OUTPUT")" >&2
  exit 1
fi

echo "Downloaded valid zip to $OUTPUT"