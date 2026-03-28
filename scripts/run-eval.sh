#!/bin/bash
# Eval orchestrator for shadcn-rules (headless A/B test)
# Full flow: reset → claude -p (Arm A/B) → check → build → report → snapshot
#
# Usage:
#   bash scripts/run-eval.sh                     # all prompts
#   bash scripts/run-eval.sh dashboard-overview  # specific page
#   bash scripts/run-eval.sh --check-only        # skip reset + generation, check only

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
RULES_DIR="${ROOT_DIR}/.claude/rules"
DATE=$(date +%Y-%m-%d)

RESULTS_TMP=$(mktemp)
LOG_DIR=$(mktemp -d)
trap 'rm -f "$RESULTS_TMP"' EXIT

echo "══════════════════════════════════════════"
echo " shadcn-rules Eval Runner (Headless A/B)"
echo " Date: ${DATE}"
echo "══════════════════════════════════════════"
echo ""

# ── Step 1: Reset preview ──
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

# ── Step 3: Generate pages (headless A/B) ──
if [ "$CHECK_ONLY" = false ]; then
  echo "── Step 2: Generate pages (headless) ──"
  echo ""

  # Collect rule file paths for Arm A system prompt
  RULES_CONTENT=""
  for rule_file in "${RULES_DIR}"/*.md; do
    RULES_CONTENT="${RULES_CONTENT}
--- $(basename "$rule_file") ---
$(cat "$rule_file")
"
  done

  mkdir -p "${PREVIEW_DIR}/src/pages"

  for prompt_file in $PROMPTS; do
    filename=$(basename "$prompt_file")
    page="${filename%.md}"

    # Apply filter
    if [ -n "$PAGE_FILTER" ] && [ "$page" != "$PAGE_FILTER" ]; then
      continue
    fi

    PROMPT_CONTENT=$(cat "$prompt_file")

    echo "  ── ${page} ──"

    # Arm A — with_rules
    echo "    [A] with_rules: generating..."
    if claude -p "$(cat <<PROMPT_A
다음 규칙을 모두 읽고, 프롬프트의 요구사항대로 페이지를 생성하세요.
shadcn 컴포넌트는 이미 설치되어 있습니다.
Composed 컴포넌트와 유틸리티가 필요하면 생성하세요.
preview/vite.config.ts와 preview/src/App.tsx는 절대 수정하지 마세요.

출력 파일: preview/src/pages/${page}.with_rules.tsx

## 규칙

${RULES_CONTENT}

## 프롬프트

${PROMPT_CONTENT}
PROMPT_A
)" \
      --allowedTools "Read,Write,Edit,Bash(mkdir *),Glob,Grep" \
      --max-turns 30 \
      --output-format text \
      > "${LOG_DIR}/${page}.arm_a.log" 2>&1; then
      echo "    [A] ✓ done"
    else
      echo "    [A] ✗ failed (log: ${LOG_DIR}/${page}.arm_a.log)"
    fi

    # Arm B — without_rules (bare mode: no CLAUDE.md, no rules)
    echo "    [B] without_rules: generating..."
    if claude --bare -p "$(cat <<PROMPT_B
프롬프트의 요구사항대로 React 대시보드 페이지를 생성하세요.
shadcn/ui와 Tailwind CSS를 사용하세요.
shadcn 컴포넌트는 이미 설치되어 있습니다.
필요한 컴포넌트와 유틸리티는 자유롭게 생성하세요.
preview/vite.config.ts와 preview/src/App.tsx는 절대 수정하지 마세요.

출력 파일: preview/src/pages/${page}.without_rules.tsx

## 프롬프트

${PROMPT_CONTENT}
PROMPT_B
)" \
      --allowedTools "Read,Write,Edit,Bash(mkdir *),Glob,Grep" \
      --max-turns 30 \
      --output-format text \
      > "${LOG_DIR}/${page}.arm_b.log" 2>&1; then
      echo "    [B] ✓ done"
    else
      echo "    [B] ✗ failed (log: ${LOG_DIR}/${page}.arm_b.log)"
    fi
    echo ""
  done
fi

# ── Step 4: Check generated pages ──
echo "── Step 3: Check generated pages ──"
echo ""
MISSING=0
EVALUATED=0

for prompt_file in $PROMPTS; do
  filename=$(basename "$prompt_file")
  page="${filename%.md}"

  if [ -n "$PAGE_FILTER" ] && [ "$page" != "$PAGE_FILTER" ]; then
    continue
  fi

  page_file_a="${PREVIEW_DIR}/src/pages/${page}.with_rules.tsx"
  page_file_b="${PREVIEW_DIR}/src/pages/${page}.without_rules.tsx"

  echo "  ── ${page} ──"

  # Save checksum (once)
  if [ -d "${PREVIEW_DIR}/src/components/ui" ] && [ ! -f "${PREVIEW_DIR}/.ui-checksums" ]; then
    find "${PREVIEW_DIR}/src/components/ui" -name "*.tsx" -exec shasum {} \; 2>/dev/null \
      | sort | shasum | awk '{print $1}' > "${PREVIEW_DIR}/.ui-checksums"
  fi

  arm_found=false

  if [ -f "$page_file_a" ]; then
    echo "    [A] with_rules: checking..."
    bash "${SCRIPT_DIR}/check-rules.sh" --format jsonl \
      --prompt "$prompt_file" \
      --preview-dir "$PREVIEW_DIR" \
      "$page_file_a" >> "$RESULTS_TMP" || true
    arm_found=true
  else
    echo "    [A] ⚠ missing: ${page_file_a}"
    MISSING=$((MISSING + 1))
  fi

  if [ -f "$page_file_b" ]; then
    echo "    [B] without_rules: checking..."
    bash "${SCRIPT_DIR}/check-rules.sh" --format jsonl \
      "$page_file_b" >> "$RESULTS_TMP" || true
    arm_found=true
  else
    echo "    [B] ⚠ missing: ${page_file_b}"
    MISSING=$((MISSING + 1))
  fi

  if [ "$arm_found" = true ]; then
    EVALUATED=$((EVALUATED + 1))
    echo "    ✓ checked"
  fi
  echo ""
done

if [ "$MISSING" -gt 0 ]; then
  echo "  ${MISSING} page(s) missing."
  echo ""
fi

if [ "$EVALUATED" -eq 0 ]; then
  echo "No pages to evaluate."
  exit 0
fi

# ── Step 5: Build check ──
echo "── Step 4: Build check ──"
BUILD_PASS=true
cd "$PREVIEW_DIR"
if npx tsc -b 2>&1; then
  echo "  ✓ Build passed"
else
  echo "  ✗ Build failed"
  BUILD_PASS=false
fi
cd "$ROOT_DIR"
echo ""

# ── Step 6: Snapshot ──
N=1
while [ -d "${ROOT_DIR}/tests/snapshots/${DATE}-run${N}" ]; do
  N=$((N + 1))
done
SNAP_DIR="${ROOT_DIR}/tests/snapshots/${DATE}-run${N}"
mkdir -p "$SNAP_DIR"

# ── Step 7: Report ──
echo ""
bash "${SCRIPT_DIR}/score-report.sh" "$RESULTS_TMP" "$SNAP_DIR" "$BUILD_PASS"

# ── Step 8: Save snapshot ──
echo ""
echo "── Saving snapshot ──"
bash "${SCRIPT_DIR}/save-snapshot.sh" "$SNAP_DIR"

# ── Step 9: Switch to viewer mode ──
echo "── Switching to viewer mode ──"
cp "${PREVIEW_DIR}/src/App.viewer.tsx" "${PREVIEW_DIR}/src/App.tsx"
echo "  ✓ Viewer mode activated"

# Save generation logs to snapshot
if [ -d "$LOG_DIR" ] && ls "${LOG_DIR}"/*.log 1>/dev/null 2>&1; then
  cp "${LOG_DIR}"/*.log "${SNAP_DIR}/"
  echo "  ✓ Generation logs saved to ${SNAP_DIR}/"
fi

echo ""
echo "══════════════════════════════════════════"
echo " Snapshot: ${SNAP_DIR}"
echo " Viewer:   cd preview && pnpm dev"
echo "══════════════════════════════════════════"
