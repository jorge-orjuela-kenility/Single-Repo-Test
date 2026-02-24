#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR=""
VERSION=""
CHECKSUMS=""
PACKAGE_PATH="Package.swift"
DOWNLOAD_BASE=""
ALLOW_MISSING="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --repo-dir) REPO_DIR="${2:-}"; shift 2 ;;
    --version) VERSION="${2:-}"; shift 2 ;;
    --checksums) CHECKSUMS="${2:-}"; shift 2 ;;
    --package-path) PACKAGE_PATH="${2:-}"; shift 2 ;;
    --download-base) DOWNLOAD_BASE="${2:-}"; shift 2 ;;
    --allow-missing) ALLOW_MISSING="true"; shift 1 ;;
    -h|--help)
      echo "Usage: $0 --repo-dir <dir> --version <tag> --checksums <json> [--package-path <path>] [--download-base <url>] [--allow-missing]"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

: "${REPO_DIR:?--repo-dir is required}"
: "${VERSION:?--version is required}"
: "${CHECKSUMS:?--checksums is required}"

PKG_FILE="$REPO_DIR/$PACKAGE_PATH"

if [ ! -d "$REPO_DIR" ]; then
  echo "ERROR: repo dir not found: $REPO_DIR" >&2
  exit 1
fi

if [ ! -f "$PKG_FILE" ]; then
  echo "ERROR: Package.swift not found at: $PKG_FILE" >&2
  exit 1
fi

if [ ! -f "$CHECKSUMS" ]; then
  echo "ERROR: checksums file not found: $CHECKSUMS" >&2
  exit 1
fi

DOWNLOAD_BASE="${DOWNLOAD_BASE%/}"

echo "== Updating Package.swift =="
echo "  repo-dir:       $REPO_DIR"
echo "  package:        $PACKAGE_PATH"
echo "  version(tag):   $VERSION"
echo "  checksums:      $CHECKSUMS"
echo "  download-base:  ${DOWNLOAD_BASE:-<not set>}"
echo "  allow-missing:  $ALLOW_MISSING"

python3 - "$PKG_FILE" "$CHECKSUMS" "$VERSION" "$DOWNLOAD_BASE" "$ALLOW_MISSING" <<'PY'
import json, re, sys
from pathlib import Path

pkg_path = Path(sys.argv[1])
checksums_path = Path(sys.argv[2])
version = sys.argv[3]
download_base = sys.argv[4].rstrip("/")
allow_missing = (sys.argv[5].lower() == "true")

data = json.loads(checksums_path.read_text(encoding="utf-8"))
text = pkg_path.read_text(encoding="utf-8")

def make_pattern(name: str) -> re.Pattern:
    # Robust multiline matcher for:
    # .binaryTarget(name: "X", url: "...", checksum: "...")
    # Named groups avoid index errors.
    return re.compile(
        r'(?P<head>\.binaryTarget\s*\(\s*'
        r'(?:name\s*:\s*"' + re.escape(name) + r'")\s*,\s*'
        r'url\s*:\s*")'
        r'(?P<url>[^"]*)'
        r'(?P<middle>"\s*,\s*checksum\s*:\s*")'
        r'(?P<checksum>[^"]*)'
        r'(?P<tail>"\s*\))',
        re.DOTALL
    )

def inject_tag_into_download_url(old_url: str, tag: str) -> str:    
    return re.sub(r"(releases/download/)([^/]*)(/)", r"\1" + tag + r"\3", old_url, count=1)

updated, missing = [], []

for name, meta in data.items():
    file = meta.get("file")
    checksum = meta.get("checksum")
    if not file or not checksum:
        raise SystemExit(f"checksums.json missing file/checksum for '{name}'")

    pat = make_pattern(name)
    m = pat.search(text)
    if not m:
        missing.append(name)
        continue

    old_url = m.group("url")

    # URL update priority:
    # 1) If it has "<version>", replace placeholder
    # 2) Else if it looks like a GitHub releases/download URL (even empty tag), inject tag
    # 3) Else if download_base provided, reconstruct base/tag/file
    # 4) Else keep old url
    if "<version>" in old_url:
        new_url = old_url.replace("<version>", version)
    elif "releases/download/" in old_url:
        new_url = inject_tag_into_download_url(old_url, version)
    elif download_base:
        new_url = f"{download_base}/{version}/{file}"
    else:
        new_url = old_url

    def repl(match: re.Match) -> str:
        return (
            match.group("head")
            + new_url
            + match.group("middle")
            + checksum
            + match.group("tail")
        )

    text = pat.sub(repl, text, count=1)
    updated.append(name)

pkg_path.write_text(text, encoding="utf-8")

print("Updated targets:", ", ".join(updated) if updated else "(none)")

if missing:
    msg = "Missing binaryTarget definitions for: " + ", ".join(missing)
    if allow_missing:
        print("WARN:", msg)
    else:
        print("ERROR:", msg, file=sys.stderr)
        sys.exit(2)
PY

echo "Package.swift updated."
(
  cd "$REPO_DIR"
  git diff -- "$PACKAGE_PATH" || true
)