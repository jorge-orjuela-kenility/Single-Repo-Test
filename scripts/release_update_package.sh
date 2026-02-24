#!/usr/bin/env bash
#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR=""
PACKAGE="Package.swift"
VERSION=""
CHECKSUMS=""
DOWNLOAD_BASE="https://github.com/Truvideo/truvideo-sdk-ios-core/releases/download"
ALLOW_MISSING="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir) REPO_DIR="$2"; shift 2 ;;
    --package) PACKAGE="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --checksums) CHECKSUMS="$2"; shift 2 ;;
    --download-base) DOWNLOAD_BASE="$2"; shift 2 ;;
    --allow-missing) ALLOW_MISSING="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

PACKAGE_PATH="$REPO_DIR/$PACKAGE"

echo "== Updating Package.swift =="
echo "  repo-dir:       $REPO_DIR"
echo "  package:        $PACKAGE"
echo "  version(tag):   $VERSION"
echo "  checksums:      $CHECKSUMS"
echo "  download-base:  $DOWNLOAD_BASE"
echo "  allow-missing:  $ALLOW_MISSING"

if [[ ! -f "$PACKAGE_PATH" ]]; then
  echo "Package file not found: $PACKAGE_PATH"
  exit 1
fi

if [[ ! -f "$CHECKSUMS" ]]; then
  echo "Checksums file not found: $CHECKSUMS"
  exit 1
fi

python3 <<PY
import json
import re
import sys

package_path = "$PACKAGE_PATH"
version = "$VERSION"
checksums_path = "$CHECKSUMS"
download_base = "$DOWNLOAD_BASE".rstrip("/")
allow_missing = "$ALLOW_MISSING".lower() == "true"

def inject_tag_into_download_url(content):
    # FIXED: use \g<1> to prevent invalid group reference (e.g. \17)
    pattern = rf"({re.escape(download_base)}/)([^/]+)(/)"
    return re.sub(pattern, rf"\g<1>{version}\g<3>", content)

def update_checksums(content, checksums):
    for name, info in checksums.items():
        file_name = info.get("file")
        checksum = info.get("checksum")

        if not file_name or not checksum:
            continue

        file_pattern = re.escape(file_name)
        pattern = rf"({file_pattern}.*?checksum:\s*\")([^\"]+)(\")"

        new_content, count = re.subn(
            pattern,
            rf"\g<1>{checksum}\g<3>",
            content,
            flags=re.DOTALL
        )

        if count == 0 and not allow_missing:
            print(f"Checksum not updated for {file_name}", file=sys.stderr)
            sys.exit(1)

        content = new_content

    return content

with open(package_path, "r", encoding="utf-8") as f:
    original = f.read()

with open(checksums_path, "r", encoding="utf-8") as f:
    checksums = json.load(f)

updated = inject_tag_into_download_url(original)
updated = update_checksums(updated, checksums)

if updated != original:
    with open(package_path, "w", encoding="utf-8") as f:
        f.write(updated)
    print("Package.swift updated.")
else:
    print("No changes made.")
PY

echo "Package.swift updated."
(
  cd "$REPO_DIR"
  git diff -- "$PACKAGE_PATH" || true
)