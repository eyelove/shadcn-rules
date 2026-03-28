#!/bin/bash
# Reset preview to clean Vite + Tailwind state.
# Removes AI-generated files, restores App.shell.tsx.
# Usage: bash scripts/reset-preview.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREVIEW_DIR="${SCRIPT_DIR}/../preview"

echo "Resetting preview..."

# Remove AI-generated directories
rm -rf "${PREVIEW_DIR}/src/components"
rm -rf "${PREVIEW_DIR}/src/lib"
rm -rf "${PREVIEW_DIR}/src/hooks"
rm -rf "${PREVIEW_DIR}/src/pages"

# Remove old App.css (Vite default)
rm -f "${PREVIEW_DIR}/src/App.css"

# Remove shadcn checksum file
rm -f "${PREVIEW_DIR}/.ui-checksums"

# Restore empty shell App
cp "${SCRIPT_DIR}/templates/App.shell.tsx" "${PREVIEW_DIR}/src/App.tsx"

# Reset index.css to Tailwind-only
cat > "${PREVIEW_DIR}/src/index.css" << 'CSSEOF'
@import "tailwindcss";
CSSEOF

echo "  ✓ preview reset to clean state"
