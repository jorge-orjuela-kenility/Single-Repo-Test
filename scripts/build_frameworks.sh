#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-TruvideoSDK.xcodeproj}"
RESOLVE_SCHEME="${RESOLVE_SCHEME:-DI}"
SIM_DEST="${SIM_DEST:-generic/platform=iOS Simulator}"
DERIVED_DATA="${DERIVED_DATA:-$PWD/DerivedData}"
SPM_CLONE_DIR="${SPM_CLONE_DIR:-$PWD/.spm-checkouts}"
RESOLVE_RETRIES="${RESOLVE_RETRIES:-3}"
MAKE_TARGET="${MAKE_TARGET:-xcframeworks}"

log() { printf "\n==> %s\n" "$*"; }

ensure_exists() {
  if [ ! -e "$1" ]; then
    echo "ERROR: Missing required path: $1"
    exit 1
  fi
}

diagnostics() {
  log "Environment"
  echo "PROJECT_PATH=$PROJECT_PATH"
  echo "RESOLVE_SCHEME=$RESOLVE_SCHEME"
  echo "SIM_DEST=$SIM_DEST"
  echo "DERIVED_DATA=$DERIVED_DATA"
  echo "SPM_CLONE_DIR=$SPM_CLONE_DIR"
  echo "RESOLVE_RETRIES=$RESOLVE_RETRIES"
  echo "MAKE_TARGET=$MAKE_TARGET"

  log "Xcode version"
  xcodebuild -version || true

  log "Swift version"
  swift --version || true
}

resolve_packages() {
  ensure_exists "$PROJECT_PATH"

  mkdir -p "$DERIVED_DATA"
  mkdir -p "$SPM_CLONE_DIR"
  
  export GIT_TERMINAL_PROMPT=0

  local attempt=1
  while [ "$attempt" -le "$RESOLVE_RETRIES" ]; do
    if xcodebuild \
      -resolvePackageDependencies \
      -project "$PROJECT_PATH" \
      -scheme "$RESOLVE_SCHEME" \
      -derivedDataPath "$DERIVED_DATA" \
      -clonedSourcePackagesDirPath "$SPM_CLONE_DIR" \
      | tee "$PWD/spm-resolve.log"; then
      log "SwiftPM resolve succeeded"
      return 0
    fi

    log "SwiftPM resolve failed (attempt $attempt). Cleaning only SPM dir and retrying..."
    rm -rf "$SPM_CLONE_DIR" || true
    mkdir -p "$SPM_CLONE_DIR"

    attempt=$((attempt + 1))
  done

  echo "ERROR: SwiftPM resolve failed after ${RESOLVE_RETRIES} attempts"
  exit 1
}

# Build XCFrameworks via Makefile, ensuring SIM_DEST is passed correctly
build_xcframeworks() {
  ensure_exists "$PROJECT_PATH"  

  make "$MAKE_TARGET" \
    SIM_DEST="$SIM_DEST"  
}

diagnostics
ensure_exists "$PROJECT_PATH"

resolve_packages
build_xcframeworks