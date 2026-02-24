#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR=""
PACKAGE_FILE="Package.swift"
VERSION_TAG=""
CHECKSUMS_FILE=""
DOWNLOAD_BASE="https://github.com/Truvideo/truvideo-sdk-ios-core/releases/download"
ALLOW_MISSING="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --repo-dir)      REPO_DIR="${2:-}"; shift 2 ;;
    --package)       PACKAGE_FILE="${2:-}"; shift 2 ;;
    --version|--tag) VERSION_TAG="${2:-}"; shift 2 ;;
    --checksums)     CHECKSUMS_FILE="${2:-}"; shift 2 ;;
    --download-base) DOWNLOAD_BASE="${2:-}"; shift 2 ;;
    --allow-missing) ALLOW_MISSING="${2:-false}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$REPO_DIR" ] || [ -z "$VERSION_TAG" ] || [ -z "$CHECKSUMS_FILE" ]; then
  echo "Missing required arguments" >&2
  exit 1
fi

PKG_PATH="$REPO_DIR/$PACKAGE_FILE"

echo "== Updating Package.swift =="
echo "  repo-dir:       $REPO_DIR"
echo "  package:        $PACKAGE_FILE"
echo "  version(tag):   $VERSION_TAG"
echo "  checksums:      $CHECKSUMS_FILE"
echo "  download-base:  $DOWNLOAD_BASE"
echo "  allow-missing:  $ALLOW_MISSING"

if [ ! -f "$PKG_PATH" ]; then
  echo "Package.swift not found: $PKG_PATH" >&2
  exit 1
fi

if [ ! -f "$CHECKSUMS_FILE" ]; then
  echo "checksums.json not found: $CHECKSUMS_FILE" >&2
  exit 1
fi

REPO_DIR="$REPO_DIR" \
PKG_PATH="$PKG_PATH" \
VERSION_TAG="$VERSION_TAG" \
CHECKSUMS_FILE="$CHECKSUMS_FILE" \
DOWNLOAD_BASE="$DOWNLOAD_BASE" \
ALLOW_MISSING="$ALLOW_MISSING" \
python3 <<'PY'
import json
import os
import re
import sys

pkg_path       = os.environ["PKG_PATH"]
version_tag    = os.environ["VERSION_TAG"]
checksums_file = os.environ["CHECKSUMS_FILE"]
download_base  = os.environ["DOWNLOAD_BASE"].rstrip("/")
allow_missing  = os.environ["ALLOW_MISSING"].lower() == "true"

def die(msg):
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)

def inject_tag_into_download_url(text: str, base: str, tag: str) -> str:
    # FIX: use \g<1> instead of \1 to prevent \17 issue
    pattern = rf"({re.escape(base)}/)([^/]+)(/)"
    return re.sub(pattern, rf"\g<1>{tag}\g<3>", text)

def update_checksums(text: str, checksums: dict) -> str:
    for name, info in checksums.items():
        file = info.get("file")
        checksum = info.get("checksum")
        if not file or not checksum:
            continue

        file_pat = re.escape(file)
        block_pat = rf"({file_pat}.*?checksum:\s*\")([^\"]+)(\")"
        new_text, n = re.subn(block_pat, rf"\g<1>{checksum}\g<3>", text, flags=re.DOTALL)

        if n == 0 and not allow_missing:
            die(f"Checksum field not found for '{file}'")

        text = new_text
    return text

with open(pkg_path, "r", encoding="utf-8") as f:
    original = f.read()

with open(checksums_file, "r", encoding="utf-8") as f:
    checksums = json.load(f)

updated = inject_tag_into_download_url(original, download_base, version_tag)
updated = update_checksums(updated, checksums)

if updated != original:
    with open(pkg_path, "w", encoding="utf-8") as f:
        f.write(updated)
    print("Package.swift updated.")
else:
    print("No changes needed.")
PY

echo "Package.swift updated."
(
  cd "$REPO_DIR"
  git diff -- "$PACKAGE_PATH" || true
)