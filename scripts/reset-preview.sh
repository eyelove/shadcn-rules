#!/bin/bash
# Reset preview to clean state for eval.
# If preview/ doesn't exist, scaffolds from scratch.
# If it exists, removes only AI-generated files (pages, composed, lib) and reapplies templates.
# Usage: bash scripts/reset-preview.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PREVIEW_DIR="${ROOT_DIR}/preview"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

echo "Resetting preview..."

# ── Scaffold if preview doesn't exist ──
if [ ! -f "${PREVIEW_DIR}/package.json" ]; then
  echo "  preview/ not found. Scaffolding..."
  cd "$ROOT_DIR"
  npx shadcn@latest init --yes --preset nova -t vite --name preview 2>&1
  cd "${PREVIEW_DIR}" && pnpm install 2>&1

  # Inject custom tokens
  CUSTOM_TOKENS="${TEMPLATES_DIR}/custom-tokens.css"
  if [ -f "$CUSTOM_TOKENS" ]; then
    python3 "${SCRIPT_DIR}/inject-custom-tokens.py" \
      "${PREVIEW_DIR}/src/index.css" \
      "$CUSTOM_TOKENS"
    echo "  ✓ custom tokens injected"
  fi

  # Install shadcn components used in eval
  echo "Installing shadcn components..."
  npx shadcn@latest add card badge input textarea select field chart separator --yes 2>&1
  echo "  ✓ shadcn components installed"

  # Patch vite.config.ts — add optimizeDeps for snapshot imports
  # App.viewer.tsx uses import.meta.glob to load snapshot pages outside preview/.
  # Vite's dep scanner can't resolve dependencies from those external paths.
  # Declaring them in optimizeDeps.include forces pre-bundling without path resolution.
  if [ -f "${PREVIEW_DIR}/vite.config.ts" ]; then
    sed -i '' 's/plugins: \[react(), tailwindcss()\],/plugins: [react(), tailwindcss()],\
  optimizeDeps: {\
    include: ["react-hook-form", "lucide-react", "recharts"],\
  },/' "${PREVIEW_DIR}/vite.config.ts"
    echo "  ✓ vite.config.ts patched (optimizeDeps)"
  fi

  # Save checksum for ENV-04
  find "${PREVIEW_DIR}/src/components/ui" -name "*.tsx" -exec shasum {} \; 2>/dev/null \
    | sort | shasum | awk '{print $1}' > "${PREVIEW_DIR}/.ui-checksums"

  echo "  ✓ preview scaffolded"
fi

# ── Remove AI-generated files only ──
rm -rf "${PREVIEW_DIR}/src/pages"
rm -rf "${PREVIEW_DIR}/src/components/composed"
rm -rf "${PREVIEW_DIR}/src/lib"
rm -rf "${PREVIEW_DIR}/src/hooks"
echo "  ✓ AI-generated files removed"

# ── Reapply eval templates ──
cp "${TEMPLATES_DIR}/App.shell.tsx" "${PREVIEW_DIR}/src/App.tsx"
cp "${TEMPLATES_DIR}/App.viewer.tsx" "${PREVIEW_DIR}/src/App.viewer.tsx"
echo "  ✓ eval templates applied"

echo ""
echo "Preview ready. Run page prompts next."
