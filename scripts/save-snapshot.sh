#!/bin/bash
# Save current preview state as a snapshot.
# Copies AI-generated files (composed, lib, pages, App.tsx) into an existing snapshot dir.
# Usage: bash scripts/save-snapshot.sh <snapshot-dir>
#
# Arguments:
#   $1 — snapshot directory (must already exist, created by run-eval.sh)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREVIEW_DIR="${SCRIPT_DIR}/../preview"
SNAP_DIR="${1:?Usage: save-snapshot.sh <snapshot-dir>}"

echo "Saving snapshot to ${SNAP_DIR}..."

mkdir -p "${SNAP_DIR}/samples/src"

# Copy AI-generated files only (not shadcn ui components)
if [ -d "${PREVIEW_DIR}/src/components/composed" ]; then
  mkdir -p "${SNAP_DIR}/samples/src/components"
  cp -r "${PREVIEW_DIR}/src/components/composed" "${SNAP_DIR}/samples/src/components/"
fi

if [ -d "${PREVIEW_DIR}/src/lib" ]; then
  cp -r "${PREVIEW_DIR}/src/lib" "${SNAP_DIR}/samples/src/"
fi

if [ -d "${PREVIEW_DIR}/src/pages" ]; then
  cp -r "${PREVIEW_DIR}/src/pages" "${SNAP_DIR}/samples/src/"
fi

if [ -f "${PREVIEW_DIR}/src/App.tsx" ]; then
  cp "${PREVIEW_DIR}/src/App.tsx" "${SNAP_DIR}/samples/src/"
fi

echo "  ✓ Snapshot saved"
