#!/usr/bin/env bash
set -Eeuo pipefail

DIR="dist"
OUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="${2:-}"; shift 2 ;;
    --out) OUT="${2:-}"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--dir <dir>] [--out <file>]"
      exit 0
      ;;
    *)
      if [ "$DIR" = "dist" ] && [ -n "$1" ] && [ "${1#--}" = "$1" ]; then
        DIR="$1"
        shift 1
      else
        echo "Unknown arg: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [ ! -d "$DIR" ]; then
  echo "ERROR: Directory not found: $DIR" >&2
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "ERROR: swift not found in PATH. Required for 'swift package compute-checksum'." >&2
  exit 1
fi

# String list (newline-separated), bash-3 safe
ZIPS="$(find "$DIR" -type f -name "*.xcframework.zip" | sort || true)"

if [ -z "$ZIPS" ]; then
  echo "ERROR: No *.xcframework.zip files found under: $DIR" >&2
  exit 1
fi

json_escape() {
  printf "%s" "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

buf="{"
first="true"

echo "== Computing SwiftPM checksums ==" >&2
echo "Directory: $DIR" >&2

# Avoid piping into while (subshell). Use a temp file.
tmp="$(mktemp)"
printf "%s\n" "$ZIPS" > "$tmp"

while IFS= read -r zip; do
  [ -z "$zip" ] && continue

  file="$(basename "$zip")"
  name="${file%.xcframework.zip}"

  echo "  - $file" >&2

  if [ ! -f "$zip" ]; then
    echo "ERROR: Missing file: $zip" >&2
    rm -f "$tmp"
    exit 1
  fi

  checksum="$(swift package compute-checksum "$zip" 2>/dev/null || true)"
  if [ -z "$checksum" ]; then
    echo "ERROR: Failed to compute checksum for: $zip" >&2
    echo "       Ensure the file is a valid zip and swift toolchain is available." >&2
    rm -f "$tmp"
    exit 1
  fi

  esc_name="$(json_escape "$name")"
  esc_file="$(json_escape "$file")"
  esc_sum="$(json_escape "$checksum")"

  if [ "$first" = "true" ]; then
    first="false"
  else
    buf+=","
  fi

  buf+="\"${esc_name}\":{\"file\":\"${esc_file}\",\"checksum\":\"${esc_sum}\"}"
done < "$tmp"

rm -f "$tmp"
buf+="}"

if [ -n "$OUT" ]; then
  mkdir -p "$(dirname "$OUT")" 2>/dev/null || true
  printf "%s\n" "$buf" > "$OUT"
  echo "✅ Wrote checksums JSON to $OUT" >&2
else
  printf "%s\n" "$buf"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  if [ -n "$OUT" ]; then
    echo "checksums_file=$OUT" >> "$GITHUB_OUTPUT"
  fi

  {
    echo "checksums_json<<EOF"
    printf "%s\n" "$buf"
    echo "EOF"
  } >> "$GITHUB_OUTPUT"
fi