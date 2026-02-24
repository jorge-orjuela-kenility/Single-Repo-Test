#!/usr/bin/env bash
set -Eeuo pipefail

REPO=""
VERSION=""
NOTES_FILE=""
ASSETS_GLOB=""
IS_PRERELEASE="false"
IS_DRAFT="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --version) VERSION="${2:-}"; shift 2 ;;
    --notes-file) NOTES_FILE="${2:-}"; shift 2 ;;
    --assets-glob) ASSETS_GLOB="${2:-}"; shift 2 ;;
    --prerelease) IS_PRERELEASE="true"; shift 1 ;;
    --draft) IS_DRAFT="true"; shift 1 ;;
    -h|--help)
      echo "Usage: $0 --repo <OWNER/REPO> --version <TAG> --notes-file <PATH> [--assets-glob <GLOB>] [--prerelease] [--draft]"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

: "${REPO:?--repo is required (OWNER/REPO)}"
: "${VERSION:?--version is required}"
: "${NOTES_FILE:?--notes-file is required}"

if [ ! -f "$NOTES_FILE" ]; then
  echo "ERROR: notes file not found: $NOTES_FILE" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found. Use actions/checkout on GitHub-hosted runner or install gh." >&2
  exit 1
fi

if [ -z "${GH_TOKEN:-}" ] && [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "ERROR: GH_TOKEN or GITHUB_TOKEN must be set in env." >&2
  exit 1
fi

export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

echo "== Creating GitHub Release =="
echo "  repo:        $REPO"
echo "  tag:         $VERSION"
echo "  notes-file:  $NOTES_FILE"
echo "  assets-glob: ${ASSETS_GLOB:-<none>}"
echo "  prerelease:  $IS_PRERELEASE"
echo "  draft:       $IS_DRAFT"

if ! gh api "repos/${REPO}/git/ref/tags/${VERSION}" >/dev/null 2>&1; then
  echo "ERROR: Tag '${VERSION}' not found in repo ${REPO}. Tag must be pushed before release creation." >&2
  exit 2
fi

if gh release view "$VERSION" --repo "$REPO" >/dev/null 2>&1; then
  echo "ERROR: Release already exists for tag: $VERSION" >&2
  exit 3
fi

TITLE="$VERSION"
args=(release create "$VERSION" --repo "$REPO" --title "$TITLE" --notes-file "$NOTES_FILE")

if [ "$IS_PRERELEASE" = "true" ]; then
  args+=(--prerelease)
fi

if [ "$IS_DRAFT" = "true" ]; then
  args+=(--draft)
fi

assets=()
if [ -n "$ASSETS_GLOB" ]; then
  shopt -s nullglob
  for f in $ASSETS_GLOB; do
    assets+=("$f")
  done
  shopt -u nullglob

  if [ "${#assets[@]}" -gt 0 ]; then
    args+=("${assets[@]}")
  else
    echo "⚠️ No assets matched glob: $ASSETS_GLOB (continuing without assets)" >&2
  fi
fi

echo "Running: gh ${args[*]}" >&2
gh "${args[@]}"

echo "✅ Release created: ${REPO} @ ${VERSION}"