#!/usr/bin/env bash
set -euo pipefail

CUT="${CUT:-}"
DRY="${DRY:-false}"

if [ -z "$CUT" ]; then
  echo "CUT not provided (rc or prod)"
  exit 1
fi

bump_from_commits () {
  local last_base_version="$1"
  local range="$2"
  local bump="patch"

  if git log --format=%B $range 2>/dev/null | grep -Eq 'BREAKING CHANGE|!:' || false; then
    bump="major"
  elif git log --format=%s $range 2>/dev/null | grep -Eq '^feat(\(|:)|^feat!' || false; then
    bump="minor"
  elif git log --format=%s $range 2>/dev/null | grep -Eq '^fix(\(|:)|^fix!|^perf(\(|:)|^perf!' || false; then
    bump="patch"
  fi

  if [ -z "$last_base_version" ]; then
    echo "0.1.0"
    return
  fi

  IFS='.' read -r major minor patch <<< "$last_base_version"

  case "$bump" in
    major) major=$((major+1)); minor=0; patch=0 ;;
    minor) minor=$((minor+1)); patch=0 ;;
    patch) patch=$((patch+1)) ;;
  esac

  echo "${major}.${minor}.${patch}"
}

rc_build_for_base_all() {
  local base="$1"
  local max=0
  while read -r t; do
    [ -z "$t" ] && continue
    n="${t##*RC-}"
    [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -gt "$max" ] && max="$n"
  done < <( git tag -l "${base}.RC-*" 2>/dev/null )

  echo $((max + 1))
}

last_base_version=$(
  git tag -l 2>/dev/null \
  | sed 's/\.RC-[0-9]*$//' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
  | sort -V | tail -n1
)

latest_tag=$( git for-each-ref --sort=-creatordate refs/tags \
  --format='%(refname:short)' 2>/dev/null \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' \
  | head -n1 )

since_ref=""
[ -n "$latest_tag" ] && since_ref="$(git rev-list -n1 "$latest_tag")"
RANGE="${since_ref:+${since_ref}..}HEAD"


if [ "$CUT" = "rc" ]; then
  CHANNEL="RC"

  if [[ "$latest_tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    BASE="$(bump_from_commits "$last_base_version" "$RANGE")"
    BUILD="1"
    FULL="${BASE}.RC-${BUILD}"
  else
    BASE="${last_base_version:-0.1.0}"
    BUILD="$(rc_build_for_base_all "$BASE")"
    FULL="${BASE}.RC-${BUILD}"
  fi

elif [ "$CUT" = "prod" ]; then
  CHANNEL="PROD"

  if [[ "$latest_tag" =~ \.RC-[0-9]+$ ]]; then
    BASE="${last_base_version:-0.1.0}"
    FULL="${BASE}"
  else
    BASE="$(bump_from_commits "$last_base_version" "$RANGE")"
    FULL="${BASE}"
  fi

  BUILD="1"

else
  echo "Invalid CUT type. Use rc or prod."
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