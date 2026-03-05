#!/bin/bash
set -e

# ------------------------------------------------------------
# Krisp static library names
# ------------------------------------------------------------
KRISP_STATIC_LIBRARY=libkrisp-audio-sdk.a
KRISP_STATIC_LIBRARY_IPHONE_DEBUG=libkrisp-audio-sdk-iphoneos-debug.a
KRISP_STATIC_LIBRARY_SIMULATOR_DEBUG=libkrisp-audio-sdk-simulator-debug.a
KRISP_STATIC_LIBRARY_IPHONE_RELEASE=libkrisp-audio-sdk-iphoneos-release.a
KRISP_STATIC_LIBRARY_SIMULATOR_RELEASE=libkrisp-audio-sdk-simulator-release.a

# ------------------------------------------------------------
# Base paths
# ------------------------------------------------------------
KRISP_ROOT="${SRCROOT}/Libraries/Plugins/External/Video/Krisp/krisp-audio-sdk"

KRISP_STATIC_LIBRARY_FINAL_NAME="${KRISP_ROOT}/${KRISP_STATIC_LIBRARY}"

DEBUG_STATIC_LIBRARY_FILE="${KRISP_ROOT}/Debug/iphoneos/${KRISP_STATIC_LIBRARY_IPHONE_DEBUG}"
DEBUG_SIMULATOR_STATIC_LIBRARY_FILE="${KRISP_ROOT}/Debug/simulator/${KRISP_STATIC_LIBRARY_SIMULATOR_DEBUG}"

RELEASE_STATIC_LIBRARY_FILE="${KRISP_ROOT}/Release/iphoneos/${KRISP_STATIC_LIBRARY_IPHONE_RELEASE}"
RELEASE_SIMULATOR_STATIC_LIBRARY_FILE="${KRISP_ROOT}/Release/simulator/${KRISP_STATIC_LIBRARY_SIMULATOR_RELEASE}"

# ------------------------------------------------------------
# Info
# ------------------------------------------------------------
echo "Building Krisp for configuration: ${CONFIGURATION}"
echo "Platform suffix: ${EFFECTIVE_PLATFORM_SUFFIX}"
echo "Effective platform name: ${EFFECTIVE_PLATFORM_NAME}"
echo "Platform name: ${PLATFORM_NAME}"
echo "SDK name: ${SDK_NAME}"
echo "Krisp root: ${KRISP_ROOT}"

# ------------------------------------------------------------
# Sanity checks
# ------------------------------------------------------------
if [ ! -f "${DEBUG_STATIC_LIBRARY_FILE}" ]; then
  echo "❌ Debug iPhoneOS library not found: ${DEBUG_STATIC_LIBRARY_FILE}"
  exit 1
fi

if [ ! -f "${DEBUG_SIMULATOR_STATIC_LIBRARY_FILE}" ]; then
  echo "❌ Debug Simulator library not found: ${DEBUG_SIMULATOR_STATIC_LIBRARY_FILE}"
  exit 2
fi

if [ ! -f "${RELEASE_STATIC_LIBRARY_FILE}" ]; then
  echo "❌ Release iPhoneOS library not found: ${RELEASE_STATIC_LIBRARY_FILE}"
  exit 3
fi

if [ ! -f "${RELEASE_SIMULATOR_STATIC_LIBRARY_FILE}" ]; then
  echo "❌ Release Simulator library not found: ${RELEASE_SIMULATOR_STATIC_LIBRARY_FILE}"
  exit 4
fi

# ------------------------------------------------------------
# Select correct binary
# ------------------------------------------------------------
# Do not use EFFECTIVE_PLATFORM_SUFFIX here: for archive it can be empty/ambiguous.
if [[ "${PLATFORM_NAME}" == "iphoneos" ]] || [[ "${EFFECTIVE_PLATFORM_NAME}" == "-iphoneos" ]] || [[ "${SDK_NAME}" == iphoneos* ]]; then
  BUILD_FOR_DEVICE=true
else
  BUILD_FOR_DEVICE=false
fi

if [[ "${CONFIGURATION}" == *"Debug"* ]]; then
  if [[ "${BUILD_FOR_DEVICE}" == true ]]; then
    SELECTED_LIBRARY="${DEBUG_STATIC_LIBRARY_FILE}"
  else
    SELECTED_LIBRARY="${DEBUG_SIMULATOR_STATIC_LIBRARY_FILE}"
  fi
else
  if [[ "${BUILD_FOR_DEVICE}" == true ]]; then
    SELECTED_LIBRARY="${RELEASE_STATIC_LIBRARY_FILE}"
  else
    SELECTED_LIBRARY="${RELEASE_SIMULATOR_STATIC_LIBRARY_FILE}"
  fi
fi

# ------------------------------------------------------------
# Copy & rename
# ------------------------------------------------------------
echo "✅ Using Krisp binary: ${SELECTED_LIBRARY}"
echo "➡️  Copying to: ${KRISP_STATIC_LIBRARY_FINAL_NAME}"

cp -f "${SELECTED_LIBRARY}" "${KRISP_STATIC_LIBRARY_FINAL_NAME}"
