#!/bin/bash
# Eval orchestrator for shadcn-rules (v3 — A/B test based)
# Full flow: reset → check pages (with_rules vs without_rules) → build → report → snapshot
#
# Usage:
#   bash scripts/run-eval.sh                     # all prompts
#   bash scripts/run-eval.sh dashboard-overview  # specific page
#   bash scripts/run-eval.sh --check-only        # skip reset, run checks on current preview

set -euo pipefail

PAGE_FILTER=""
CHECK_ONLY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --check-only)
      CHECK_ONLY=true
      shift
      ;;
    *)
      PAGE_FILTER="$1"
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."
PROMPT_DIR="${ROOT_DIR}/tests/prompts"
PREVIEW_DIR="${ROOT_DIR}/preview"
DATE=$(date +%Y-%m-%d)

RESULTS_TMP=$(mktemp)
trap 'rm -f "$RESULTS_TMP"' EXIT

echo "══════════════════════════════════════════"
echo " shadcn-rules Eval Runner v3 (A/B Test)"
echo " Date: ${DATE}"
echo "══════════════════════════════════════════"
echo ""

# ── Step 1: Reset preview (skip in check-only mode) ──
if [ "$CHECK_ONLY" = false ]; then
  echo "── Step 1: Reset preview ──"
  bash "${SCRIPT_DIR}/reset-preview.sh"
  echo ""
fi

# ── Step 2: Collect prompts ──
PROMPTS=$(find "$PROMPT_DIR" -name "*.md" 2>/dev/null | sort)
if [ -z "$PROMPTS" ]; then
  echo "No prompt files found in ${PROMPT_DIR}/"
  exit 1
fi

# ── Step 3: Check generated pages (A/B) ──
echo "── Checking generated pages (A/B) ──"
echo ""
MISSING=0
EVALUATED=0

for prompt_file in $PROMPTS; do
  filename=$(basename "$prompt_file")
  page="${filename%.md}"

  # Apply filter
  if [ -n "$PAGE_FILTER" ] && [ "$page" != "$PAGE_FILTER" ]; then
    continue
  fi

  page_file_a="${PREVIEW_DIR}/src/pages/${page}.with_rules.tsx"
  page_file_b="${PREVIEW_DIR}/src/pages/${page}.without_rules.tsx"

  echo "── ${page} ──"

  # Save checksum of shadcn ui components for ENV-04 (once)
  if [ -d "${PREVIEW_DIR}/src/components/ui" ] && [ ! -f "${PREVIEW_DIR}/.ui-checksums" ]; then
    find "${PREVIEW_DIR}/src/components/ui" -name "*.tsx" -exec shasum {} \; 2>/dev/null | sort | shasum | awk '{print $1}' > "${PREVIEW_DIR}/.ui-checksums"
  fi

  arm_found=false

  # Check arm A (with_rules) — includes ENV checks
  if [ -f "$page_file_a" ]; then
    echo "   [A] with_rules: checking..."
    bash "${SCRIPT_DIR}/check-rules.sh" --format jsonl \
      --prompt "$prompt_file" \
      --preview-dir "$PREVIEW_DIR" \
      "$page_file_a" >> "$RESULTS_TMP" || true
    arm_found=true
  else
    echo "   [A] with_rules: ⚠ Page missing: ${page_file_a}"
    MISSING=$((MISSING + 1))
  fi

  # Check arm B (without_rules) — NO ENV checks (B may not have Composed/lib)
  if [ -f "$page_file_b" ]; then
    echo "   [B] without_rules: checking..."
    bash "${SCRIPT_DIR}/check-rules.sh" --format jsonl \
      "$page_file_b" >> "$RESULTS_TMP" || true
    arm_found=true
  else
    echo "   [B] without_rules: ⚠ Page missing: ${page_file_b}"
    MISSING=$((MISSING + 1))
  fi

  if [ "$arm_found" = true ]; then
    EVALUATED=$((EVALUATED + 1))
    echo "   ✓ Checked"
  fi
  echo ""
done

if [ "$MISSING" -gt 0 ]; then
  echo "══════════════════════════════════════════"
  echo " ${MISSING} page(s) missing. Generate them first."
  echo "══════════════════════════════════════════"
  echo ""
fi

if [ "$EVALUATED" -eq 0 ]; then
  echo "No pages to evaluate."
  exit 0
fi

# ── Step 4: Build check ──
echo "── Build check ──"
BUILD_PASS=true
cd "$PREVIEW_DIR"
if npx tsc -b 2>&1; then
  echo "   ✓ Build passed"
else
  echo "   ✗ Build failed"
  BUILD_PASS=false
fi
cd "$ROOT_DIR"
echo ""

# ── Step 5: Determine snapshot dir ──
N=1
while [ -d "${ROOT_DIR}/tests/snapshots/${DATE}-run${N}" ]; do
  N=$((N + 1))
done
SNAP_DIR="${ROOT_DIR}/tests/snapshots/${DATE}-run${N}"
mkdir -p "$SNAP_DIR"

# ── Step 6: Generate report ──
echo ""
bash "${SCRIPT_DIR}/score-report.sh" "$RESULTS_TMP" "$SNAP_DIR" "$BUILD_PASS"

# ── Step 7: Save snapshot ──
echo ""
echo "── Saving snapshot ──"
bash "${SCRIPT_DIR}/save-snapshot.sh" "$SNAP_DIR"

echo ""
echo "══════════════════════════════════════════"
echo " Snapshot saved to: ${SNAP_DIR}"
echo "══════════════════════════════════════════"
