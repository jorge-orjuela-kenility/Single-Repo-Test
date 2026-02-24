#!/usr/bin/env bash
set -euo pipefail

CUT="${CUT:-}"
if [ -z "$CUT" ]; then
  echo "CUT not provided (rc or prod)" >&2
  exit 1
fi

git fetch --tags --force >/dev/null 2>&1 || true

last_prod="$(
  git tag -l 2>/dev/null \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -n1 \
    || true
)"

latest_tag="$(
  git for-each-ref --sort=-creatordate refs/tags --format='%(refname:short)' 2>/dev/null \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(-RC\.[0-9]+)?$' \
    | head -n1 \
    || true
)"


since_ref=""
if [ -n "$latest_tag" ]; then
  since_ref="$(git rev-list -n1 "$latest_tag" 2>/dev/null || true)"
fi
RANGE="${since_ref:+${since_ref}..}HEAD"

bump_from_commits () {
  local last_base="$1"
  local range="$2"
  local bump="patch"

  if [ "$(git log --format=%B $range 2>/dev/null | grep -c -E 'BREAKING CHANGE|!:' || true)" -gt 0 ]; then
    bump="major"
  elif [ "$(git log --format=%s $range 2>/dev/null | grep -c -E '^feat(\(|:)|^feat!' || true)" -gt 0 ]; then
    bump="minor"
  fi

  if [ -z "$last_base" ]; then
    echo "0.1.0"
    return
  fi

  IFS='.' read -r major minor patch <<< "$last_base"
  case "$bump" in
    major) major=$((major+1)); minor=0; patch=0 ;;
    minor) minor=$((minor+1)); patch=0 ;;
    patch) patch=$((patch+1)) ;;
  esac
  echo "${major}.${minor}.${patch}"
}

next_rc_build () {
  local base="$1"
  local max=0
  local n

  while IFS= read -r t; do
    [ -z "$t" ] && continue
    n="${t##*-RC.}"
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -gt "$max" ]; then
      max="$n"
    fi
  done < <(git tag -l "${base}-RC.*" 2>/dev/null || true)

  echo $((max + 1))
}

rc_base_from_tag () {
  local t="$1"
  echo "$t" | sed -E 's/-RC\.[0-9]+$//'
}

CHANNEL=""
BASE=""
FULL=""
BUILD=""

if [ "$CUT" = "rc" ]; then
  CHANNEL="RC"

  if echo "$latest_tag" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+-RC\.[0-9]+$'; then
    # Continue RC series for same base
    BASE="$(rc_base_from_tag "$latest_tag")"
    BUILD="$(next_rc_build "$BASE")"
    FULL="${BASE}-RC.${BUILD}"
  else
    # Latest is PROD (or no tags): bump base from commits
    BASE="$(bump_from_commits "$last_prod" "$RANGE")"
    BUILD="1"
    FULL="${BASE}-RC.${BUILD}"
  fi

elif [ "$CUT" = "prod" ]; then
  CHANNEL="PROD"

  # If latest tag is RC, promote its base; else bump from commits
  if echo "$latest_tag" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+-RC\.[0-9]+$'; then
    BASE="$(rc_base_from_tag "$latest_tag")"
    FULL="$BASE"
  else
    BASE="$(bump_from_commits "$last_prod" "$RANGE")"
    FULL="$BASE"
  fi

  BUILD="1"
else
  echo "Invalid CUT type. Use rc or prod." >&2
  exit 1
fi

cat <<EOF
{
  "base": "${BASE}",
  "full": "${FULL}",
  "channel": "${CHANNEL}",
  "build": "${BUILD}",
  "range": "${RANGE}",
  "cut_type": "${CUT}"
}
EOF