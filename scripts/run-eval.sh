#!/bin/bash
# Eval orchestrator for shadcn-rules (v2 — snapshot-based)
# Full flow: reset → check pages → build → grep check → report → snapshot
#
# Usage:
#   bash scripts/run-eval.sh                     # all prompts
#   bash scripts/run-eval.sh dashboard-overview  # specific page
#   bash scripts/run-eval.sh --type adversarial  # specific type only
#   bash scripts/run-eval.sh --check-only        # skip reset, run checks on current preview

set -euo pipefail

PAGE_FILTER=""
TYPE_FILTER=""
CHECK_ONLY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --type)
      TYPE_FILTER="$2"
      shift 2
      ;;
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
EXPECTED_TMP=$(mktemp)

trap 'rm -f "$RESULTS_TMP" "$EXPECTED_TMP"' EXIT

echo "══════════════════════════════════════════"
echo " shadcn-rules Eval Runner v2"
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
PROMPTS=$(find "$PROMPT_DIR" -name "*.md" ! -name "setup.md" 2>/dev/null | sort)
if [ -z "$PROMPTS" ]; then
  echo "No prompt files found in ${PROMPT_DIR}/"
  exit 1
fi

# ── Step 3: Check for page files + run grep checks ──
echo "── Checking generated pages ──"
echo ""
MISSING=0
EVALUATED=0

for prompt_file in $PROMPTS; do
  filename=$(basename "$prompt_file")
  # Parse: {page}.{type}.md
  page=$(echo "$filename" | sed -E 's/\.(normal|adversarial)\.md$//')
  type=$(echo "$filename" | sed -E 's/.*\.(normal|adversarial)\.md$/\1/')

  # Apply filters
  if [ -n "$PAGE_FILTER" ] && [ "$page" != "$PAGE_FILTER" ]; then
    continue
  fi
  if [ -n "$TYPE_FILTER" ] && [ "$type" != "$TYPE_FILTER" ]; then
    continue
  fi

  page_file="${PREVIEW_DIR}/src/pages/${page}.${type}.tsx"

  echo "── ${page}.${type} ──"

  if [ ! -f "$page_file" ]; then
    echo "   ⚠ Page missing: ${page_file}"
    echo "   Generate it using the prompt: ${prompt_file}"
    echo ""
    MISSING=$((MISSING + 1))
    continue
  fi

  # Save checksum of shadcn ui components for ENV-04 (once)
  if [ -d "${PREVIEW_DIR}/src/components/ui" ] && [ ! -f "${PREVIEW_DIR}/.ui-checksums" ]; then
    find "${PREVIEW_DIR}/src/components/ui" -name "*.tsx" -exec shasum {} \; 2>/dev/null | sort | shasum | awk '{print $1}' > "${PREVIEW_DIR}/.ui-checksums"
  fi

  # Run check-rules.sh with ENV checks
  bash "${SCRIPT_DIR}/check-rules.sh" --format jsonl \
    --prompt "$prompt_file" \
    --preview-dir "$PREVIEW_DIR" \
    "$page_file" >> "$RESULTS_TMP" || true
  EVALUATED=$((EVALUATED + 1))

  # Extract expected_violations for adversarial prompts
  if [ "$type" = "adversarial" ]; then
    in_expected=0
    while IFS= read -r line; do
      if echo "$line" | grep -q "^expected_violations:"; then
        in_expected=1
        continue
      fi
      if [ "$in_expected" = "1" ]; then
        if echo "$line" | grep -q "^  - "; then
          rule=$(echo "$line" | sed 's/^  - //')
          echo "${page}.${type}:${rule}" >> "$EXPECTED_TMP"
        else
          in_expected=0
        fi
      fi
    done < "$prompt_file"
  fi

  echo "   ✓ Checked"
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
if [ -s "$EXPECTED_TMP" ]; then
  bash "${SCRIPT_DIR}/score-report.sh" "$RESULTS_TMP" "$EXPECTED_TMP" "$SNAP_DIR" "$BUILD_PASS"
else
  bash "${SCRIPT_DIR}/score-report.sh" "$RESULTS_TMP" "" "$SNAP_DIR" "$BUILD_PASS"
fi

# ── Step 7: Save snapshot ──
echo ""
echo "── Saving snapshot ──"
bash "${SCRIPT_DIR}/save-snapshot.sh" "$SNAP_DIR"

echo ""
echo "══════════════════════════════════════════"
echo " Snapshot saved to: ${SNAP_DIR}"
echo "══════════════════════════════════════════"
