#!/bin/bash
# Reset preview to clean state for eval.
# If preview/ doesn't exist, scaffolds from scratch.
# If it exists, removes only AI-generated files (pages, composed, lib) and reapplies templates.
# Usage:
#   bash scripts/reset-preview.sh            # default: clean AI-generated files only
#   bash scripts/reset-preview.sh --fresh    # delete preview/ entirely and scaffold from scratch

set -euo pipefail

FRESH=false
while [ $# -gt 0 ]; do
  case "$1" in
    --fresh) FRESH=true; shift ;;
    *) shift ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PREVIEW_DIR="${ROOT_DIR}/preview"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

echo "Resetting preview..."

# ── Fresh mode: delete entire preview/ to force full scaffold ──
if [ "$FRESH" = true ] && [ -d "${PREVIEW_DIR}" ]; then
  echo "  --fresh: removing preview/ entirely..."
  rm -rf "${PREVIEW_DIR}"
  echo "  ✓ preview/ removed"
fi

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
  npx shadcn@latest add card badge input textarea select field chart separator popover calendar switch radio-group combobox --yes 2>&1
  echo "  ✓ shadcn components installed"

  # Install runtime dependencies used by eval-generated pages and composed components.
  # These are imported by AI-generated pages (react-hook-form, lucide-react, recharts)
  # and by composed components (DataTable uses @tanstack/react-table).
  # optimizeDeps.include alone is not enough — packages must actually be installed.
  echo "Installing runtime dependencies..."
  cd "${PREVIEW_DIR}" && pnpm add react-hook-form lucide-react recharts @tanstack/react-table 2>&1
  echo "  ✓ runtime dependencies installed"

  # Patch vite.config.ts — optimizeDeps for snapshot imports
  # App.viewer.tsx uses import.meta.glob to load snapshot pages outside preview/.
  # Problem: Vite's dep scanner follows those imports into tests/snapshots/ and fails
  # because node_modules is in preview/, not in the snapshot directory.
  # Fix: entries limits the scan to preview/src only, include forces pre-bundling
  # of packages that snapshot files import (resolved from preview/node_modules).
  if [ -f "${PREVIEW_DIR}/vite.config.ts" ]; then
    sed -i '' 's/plugins: \[react(), tailwindcss()\],/plugins: [react(), tailwindcss()],\
  optimizeDeps: {\
    entries: ["src\/main.tsx"],\
    include: ["react-hook-form", "lucide-react", "recharts", "@tanstack\/react-table"],\
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
mkdir -p "${PREVIEW_DIR}/src/lib"
cp "${TEMPLATES_DIR}/utils.ts" "${PREVIEW_DIR}/src/lib/utils.ts"
cp "${TEMPLATES_DIR}/format.ts" "${PREVIEW_DIR}/src/lib/format.ts"
mkdir -p "${PREVIEW_DIR}/src/components/composed"
cp -r "${TEMPLATES_DIR}/composed/" "${PREVIEW_DIR}/src/components/composed/"
echo "  ✓ eval templates applied"

echo ""
echo "Preview ready. Run page prompts next."
