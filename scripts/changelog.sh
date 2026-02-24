#!/usr/bin/env bash
set -Eeuo pipefail

VERSION_FULL="${VERSION_FULL:?VERSION_FULL not set}"
CHANNEL="${CHANNEL:-}"

git fetch --tags --force >/dev/null 2>&1 || true

CURRENT_TAG="$VERSION_FULL"

pattern="*"
case "${CHANNEL}" in
  RC) pattern="*.RC-*" ;;
  BETA) pattern="*.BETA-*" ;;
  PROD) pattern="*" ;;
esac

PREV_TAG="$(
  git tag --list "$pattern" --sort=-creatordate \
    | grep -v "^${CURRENT_TAG}$" \
    | head -n 1 || true
)"

if [ -n "$PREV_TAG" ]; then
  RANGE="${PREV_TAG}..HEAD"
else
  RANGE="HEAD"
  echo "⚠️ No previous tag found for pattern '$pattern'. Using full history." >&2
fi

echo "Generating changelog for range: $RANGE" >&2

COMMITS="$(git log --no-merges --pretty=format:'%s' $RANGE || true)"

extract_type() {
  local type="$1"
  echo "$COMMITS" | grep -E "^${type}(\([^)]+\))?(!)?: " || true
}

to_bullets() {
  sed -E 's/^[a-z]+(\([^)]+\))?(!)?: /- /'
}

BREAKING="$(echo "$COMMITS" | grep -E '^[a-z]+(\([^)]+\))?!: ' | to_bullets || true)"
FEATS="$(extract_type feat | to_bullets)"
FIXES="$(extract_type fix | to_bullets)"
PERF="$(extract_type perf | to_bullets)"
REFACTOR="$(extract_type refactor | to_bullets)"
DOCS="$(extract_type docs | to_bullets)"
TESTS="$(extract_type test | to_bullets)"
BUILD="$(extract_type build | to_bullets)"
CI="$(extract_type ci | to_bullets)"
CHORE="$(extract_type chore | to_bullets)"
STYLE="$(extract_type style | to_bullets)"
REVERTS="$(extract_type revert | to_bullets)"

OTHER="$(
  echo "$COMMITS" \
    | grep -Ev '^(feat|fix|perf|refactor|docs|test|build|ci|chore|style|revert)(\([^)]+\))?(!)?: ' \
    | sed '/^\s*$/d' \
    | sed 's/^/- /' \
    || true
)"

OUT_FILE="CHANGELOG.md"

{
  echo "## Release ${VERSION_FULL}"
  [ -n "$PREV_TAG" ] && echo "" && echo "_Changes since \`$PREV_TAG\`_"
  echo ""

  if [ -n "$BREAKING" ]; then
    echo "### ⚠️ Breaking Changes"
    echo "$BREAKING"
    echo ""
  fi

  if [ -n "$FEATS" ]; then
    echo "### ✨ Features"
    echo "$FEATS"
    echo ""
  fi

  if [ -n "$FIXES" ]; then
    echo "### 🐛 Fixes"
    echo "$FIXES"
    echo ""
  fi

  if [ -n "$PERF" ]; then
    echo "### 🚀 Performance"
    echo "$PERF"
    echo ""
  fi

  if [ -n "$REFACTOR" ]; then
    echo "### 🧹 Refactors"
    echo "$REFACTOR"
    echo ""
  fi

  if [ -n "$DOCS" ]; then
    echo "### 📚 Docs"
    echo "$DOCS"
    echo ""
  fi

  if [ -n "$TESTS" ]; then
    echo "### ✅ Tests"
    echo "$TESTS"
    echo ""
  fi

  if [ -n "$BUILD" ] || [ -n "$CI" ]; then
    echo "### 🏗️ Build / CI"
    [ -n "$BUILD" ] && echo "$BUILD"
    [ -n "$CI" ] && echo "$CI"
    echo ""
  fi

  if [ -n "$CHORE" ] || [ -n "$STYLE" ] || [ -n "$REVERTS" ]; then
    echo "### 🔧 Maintenance"
    [ -n "$CHORE" ] && echo "$CHORE"
    [ -n "$STYLE" ] && echo "$STYLE"
    [ -n "$REVERTS" ] && echo "$REVERTS"
    echo ""
  fi

  if [ -n "$OTHER" ]; then
    echo "### 📝 Other"
    echo "$OTHER"
    echo ""
  fi

  if [ -z "$COMMITS" ]; then
    echo "_No changes found in range._"
    echo ""
  fi
} > "$OUT_FILE"

echo "✅ Wrote $OUT_FILE" >&2

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "changelog_file=$OUT_FILE" >> "$GITHUB_OUTPUT"
  {
    echo "changelog_md<<EOF"
    cat "$OUT_FILE"
    echo "EOF"
  } >> "$GITHUB_OUTPUT"
fi