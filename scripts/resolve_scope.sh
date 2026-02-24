#!/usr/bin/env bash
set -euo pipefail

LBL_RC="${LBL_RC:-cut-rc}"

EVENT_FILE="${GITHUB_EVENT_PATH:-}"
EVENT_NAME="${GITHUB_EVENT_NAME:-}"

safe_trim() {
  printf "%s" "$1" \
    | tr '\t' ' ' \
    | tr -s ' ' \
    | sed 's/^ *//; s/ *$//'
}

labels=""
if [ -n "${EVENT_FILE}" ] && [ -f "${EVENT_FILE}" ]; then
  labels="$(jq -r '.pull_request.labels[].name // empty' "$EVENT_FILE" 2>/dev/null | sed '/^\s*$/d' || true)"
fi

cut=""
if [ "$EVENT_NAME" = "workflow_dispatch" ] && [ -n "${EVENT_FILE}" ] && [ -f "${EVENT_FILE}" ]; then
  cut="$(jq -r '.inputs.cut // empty' "$EVENT_FILE" 2>/dev/null || true)"
fi

if [ -z "$cut" ]; then
  if grep -Fxq "${LBL_RC}" <<< "$labels"; then
    cut="rc"
  fi
fi

allow="$(grep -B 1 'type: framework' "$GITHUB_WORKSPACE/project.yml" 2>/dev/null \
  | grep -E '^  [A-Za-z0-9]+:' \
  | sed 's/^  //; s/:$//' \
  | tr '\n' ' ' \
  | sed 's/ $//' || true)"

allow="$(safe_trim "$allow")"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "cut=$cut" >> "$GITHUB_OUTPUT"
  echo "aff=$allow" >> "$GITHUB_OUTPUT"
fi

SCOPE_FILE="$GITHUB_WORKSPACE/.cut_release_scope"
{
  echo "CUT=$cut"
  echo "AFF=\"$allow\""
} > "$SCOPE_FILE"

echo "Resolved scope:"
cat "$SCOPE_FILE"