#!/bin/bash
# Eval orchestrator for shadcn-rules
# Collects prompts, checks for samples, runs validation, generates report
#
# Usage:
#   bash scripts/run-eval.sh                     # all prompts
#   bash scripts/run-eval.sh dashboard-overview  # specific page
#   bash scripts/run-eval.sh --type adversarial  # specific type only

PAGE_FILTER=""
TYPE_FILTER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --type)
      TYPE_FILTER="$2"
      shift 2
      ;;
    *)
      PAGE_FILTER="$1"
      shift
      ;;
  esac
done

PROMPT_DIR="tests/prompts"
SAMPLE_DIR="tests/samples"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATE=$(date +%Y-%m-%d)
RESULTS_TMP=$(mktemp)
EXPECTED_TMP=$(mktemp)

trap 'rm -f "$RESULTS_TMP" "$EXPECTED_TMP"' EXIT

echo "══════════════════════════════════════════"
echo " shadcn-rules Eval Runner"
echo " Date: ${DATE}"
echo "══════════════════════════════════════════"
echo ""

# Collect prompts
PROMPTS=$(find "$PROMPT_DIR" -name "*.md" 2>/dev/null | sort)
if [ -z "$PROMPTS" ]; then
  echo "No prompt files found in ${PROMPT_DIR}/"
  exit 1
fi

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

  sample_file="${SAMPLE_DIR}/${page}.${type}.tsx"

  echo "── ${page}.${type} ──"

  if [ ! -f "$sample_file" ]; then
    echo "   ⚠ Sample missing: ${sample_file}"
    echo "   Generate it using the prompt: ${prompt_file}"
    echo ""
    MISSING=$((MISSING + 1))
    continue
  fi

  # Run check-rules.sh in jsonl mode
  bash "${SCRIPT_DIR}/check-rules.sh" --format jsonl "$sample_file" >> "$RESULTS_TMP"
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
  echo " ${MISSING} sample(s) missing. Generate them first."
  echo "══════════════════════════════════════════"
  echo ""
fi

if [ "$EVALUATED" -eq 0 ]; then
  echo "No samples to evaluate."
  rm -f "$RESULTS_TMP" "$EXPECTED_TMP"
  exit 0
fi

# Generate report
echo ""
if [ -s "$EXPECTED_TMP" ]; then
  bash "${SCRIPT_DIR}/score-report.sh" "$RESULTS_TMP" "$EXPECTED_TMP"
else
  bash "${SCRIPT_DIR}/score-report.sh" "$RESULTS_TMP"
fi
