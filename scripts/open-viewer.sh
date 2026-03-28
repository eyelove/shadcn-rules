#!/bin/bash
# Switch preview App.tsx to the comparison viewer.
# Usage: bash scripts/open-viewer.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREVIEW_DIR="${SCRIPT_DIR}/../preview"

cp "${PREVIEW_DIR}/src/App.viewer.tsx" "${PREVIEW_DIR}/src/App.tsx"
echo "Switched to viewer mode. Run 'cd preview && pnpm dev' to start."
