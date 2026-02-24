#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR=""
VERSION=""
BRANCH="main"
PACKAGE_PATH="Package.swift"
GIT_NAME="kenility-bot"
GIT_EMAIL="bot@kenility.com"
ALLOW_NO_CHANGES="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --repo-dir) REPO_DIR="${2:-}"; shift 2 ;;
    --version) VERSION="${2:-}"; shift 2 ;;
    --branch) BRANCH="${2:-}"; shift 2 ;;
    --package-path) PACKAGE_PATH="${2:-}"; shift 2 ;;
    --git-name) GIT_NAME="${2:-}"; shift 2 ;;
    --git-email) GIT_EMAIL="${2:-}"; shift 2 ;;
    --allow-no-changes) ALLOW_NO_CHANGES="true"; shift 1 ;;
    -h|--help)
      echo "Usage: $0 --repo-dir <dir> --version <tag> --branch <branch> [--package-path <path>] [--git-name <name>] [--git-email <email>] [--allow-no-changes]"
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
: "${BRANCH:?--branch is required}"

if [ ! -d "$REPO_DIR" ]; then
  echo "ERROR: repo dir not found: $REPO_DIR" >&2
  exit 1
fi

cd "$REPO_DIR"

echo "== Commit + tag + push =="
echo "  repo:    $(pwd)"
echo "  branch:  $BRANCH"
echo "  version: $VERSION"
echo "  file:    $PACKAGE_PATH"

git remote -v
git fetch origin --tags --force >/dev/null 2>&1 || true

git checkout "$BRANCH" >/dev/null 2>&1 || git checkout -b "$BRANCH"

if [ ! -f "$PACKAGE_PATH" ]; then
  echo "ERROR: $PACKAGE_PATH not found in $REPO_DIR" >&2
  exit 1
fi

if git diff --quiet -- "$PACKAGE_PATH"; then
  if [ "$ALLOW_NO_CHANGES" = "true" ]; then
    echo "No changes detected in $PACKAGE_PATH (allowed)."
  else
    echo "ERROR: No changes detected in $PACKAGE_PATH. Refusing to tag a no-op release." >&2
    echo "Tip: check that release_update_package.sh actually updated URLs/checksums." >&2
    exit 2
  fi
fi

git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"

git add "$PACKAGE_PATH"

if git diff --cached --quiet; then
  if [ "$ALLOW_NO_CHANGES" = "true" ]; then
    echo "⚠️ Nothing staged to commit (allowed)."
  else
    echo "ERROR: Nothing staged to commit." >&2
    exit 3
  fi
else
  COMMIT_MSG="chore(release): ${VERSION}"
  git commit -m "$COMMIT_MSG"
  echo "✅ Committed: $COMMIT_MSG"
fi

TAG="$VERSION"

if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "ERROR: Tag already exists locally: $TAG" >&2
  exit 4
fi

if git ls-remote --tags origin "refs/tags/$TAG" | grep -q "$TAG"; then
  echo "ERROR: Tag already exists on origin: $TAG" >&2
  exit 5
fi

TAG_MSG="chore(release): ${VERSION}"
git tag -a "$TAG" -m "$TAG_MSG"

git push origin "$BRANCH"
git push origin "$TAG"

echo "✅ Pushed branch + tag:"
echo "  branch: $BRANCH"
echo "  tag:    $TAG"