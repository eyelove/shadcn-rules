#!/bin/bash
# Reset preview to clean state for eval.
# If preview/ doesn't exist, scaffolds a new Vite + shadcn project.
# If it exists, removes AI-generated files and re-initializes.
# Usage: bash scripts/reset-preview.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PREVIEW_DIR="${ROOT_DIR}/preview"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

echo "Resetting preview..."

# ── Scaffold preview if it doesn't exist ──
if [ ! -f "${PREVIEW_DIR}/package.json" ]; then
  echo "  preview/ not found. Scaffolding new Vite + shadcn project..."
  cd "$ROOT_DIR"
  npx shadcn@latest init --yes --preset nova -t vite --name preview 2>&1
  cd "${PREVIEW_DIR}" && pnpm install 2>&1
  echo "  ✓ preview scaffolded"
fi

# ── Remove AI-generated directories ──
rm -rf "${PREVIEW_DIR}/src/components"
rm -rf "${PREVIEW_DIR}/src/lib"
rm -rf "${PREVIEW_DIR}/src/hooks"
rm -rf "${PREVIEW_DIR}/src/pages"

# Remove old App.css (Vite default)
rm -f "${PREVIEW_DIR}/src/App.css"

# Remove shadcn checksum file
rm -f "${PREVIEW_DIR}/.ui-checksums"

# Restore empty shell App
cp "${TEMPLATES_DIR}/App.shell.tsx" "${PREVIEW_DIR}/src/App.tsx"

# Copy viewer template
cp "${TEMPLATES_DIR}/App.viewer.tsx" "${PREVIEW_DIR}/src/App.viewer.tsx"

# Reset index.css to Tailwind-only (clean slate for shadcn init)
cat > "${PREVIEW_DIR}/src/index.css" << 'CSSEOF'
@import "tailwindcss";
CSSEOF

echo "  ✓ preview reset to clean state"

# ── shadcn re-init (force on existing project) ──
echo "Running shadcn init..."
cd "${PREVIEW_DIR}"
npx shadcn@latest init --yes --force --no-reinstall --preset nova -t vite 2>&1
echo "  ✓ shadcn initialized"

# ── Inject custom tokens ──
CUSTOM_TOKENS="${TEMPLATES_DIR}/custom-tokens.css"

if [ ! -f "$CUSTOM_TOKENS" ]; then
  echo "  ⚠ custom-tokens.css not found, skipping token injection"
else
  python3 "${SCRIPT_DIR}/inject-custom-tokens.py" \
    "${PREVIEW_DIR}/src/index.css" \
    "$CUSTOM_TOKENS"
  echo "  ✓ custom tokens injected"
fi

# ── Install all shadcn components used in eval prompts ──
echo "Installing shadcn components..."
npx shadcn@latest add card badge input textarea select field chart separator --yes 2>&1
echo "  ✓ shadcn components installed"

# Save checksum of shadcn ui components for ENV-04
find "${PREVIEW_DIR}/src/components/ui" -name "*.tsx" -exec shasum {} \; 2>/dev/null \
  | sort | shasum | awk '{print $1}' > "${PREVIEW_DIR}/.ui-checksums"

echo ""
echo "Preview ready. Run page prompts next."
