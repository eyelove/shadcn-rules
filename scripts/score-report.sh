#!/bin/bash
# Score report generator for shadcn-rules
# Reads JSONL from check-rules.sh and produces terminal summary + markdown report
#
# Usage:
#   bash scripts/score-report.sh results.jsonl [expected_violations.txt]
#   cat results.jsonl | bash scripts/score-report.sh - [expected_violations.txt]

set -euo pipefail

# --- Arguments ---
INPUT="${1:?Usage: score-report.sh <results.jsonl | -> [expected_violations.txt]}"
EXPECTED="${2:-}"
OUTPUT_DIR="${3:-}"
BUILD_PASS="${4:-true}"
TODAY=$(date +%Y-%m-%d)

if [ -n "$OUTPUT_DIR" ]; then
  REPORT_DIR="$OUTPUT_DIR"
  REPORT_FILE="${OUTPUT_DIR}/report.md"
else
  REPORT_DIR="tests/reports"
  REPORT_FILE="${REPORT_DIR}/${TODAY}-report.md"
fi

# --- Temp files ---
TMPFILE=$(mktemp /tmp/score-report-input.XXXXXX)
TMP_SUMMARY=$(mktemp /tmp/score-report-summary.XXXXXX)
TMP_HEATMAP=$(mktemp /tmp/score-report-heatmap.XXXXXX)
TMP_DETECTION=$(mktemp /tmp/score-report-detection.XXXXXX)
trap 'rm -f "$TMPFILE" "$TMP_SUMMARY" "$TMP_HEATMAP" "$TMP_DETECTION" "${TMP_DETECTION}.detected" "${TMP_DETECTION}.missed"' EXIT

if [ "$INPUT" = "-" ]; then
  cat > "$TMPFILE"
else
  cp "$INPUT" "$TMPFILE"
fi

if [ ! -s "$TMPFILE" ]; then
  echo "Error: No JSONL data received."
  exit 1
fi

# --- Step 1: Per-file summary ---
awk '
BEGIN { nfiles = 0 }
{
  line = $0
  # Extract file field
  file = line
  sub(/.*"file":"/, "", file)
  sub(/".*/, "", file)
  # Extract result field
  result = line
  sub(/.*"result":"/, "", result)
  sub(/".*/, "", result)

  # Get basename
  n = split(file, parts, "/")
  bname = parts[n]
  if (bname == "") bname = file

  if (!(bname in seen)) {
    seen[bname] = 1
    order[nfiles++] = bname
    pass_count[bname] = 0
    fail_count[bname] = 0
  }

  if (result == "PASS") pass_count[bname]++
  else if (result == "FAIL") fail_count[bname]++
}
END {
  for (i = 0; i < nfiles; i++) {
    f = order[i]
    p = pass_count[f]
    fl = fail_count[f]
    total = p + fl
    score = (total > 0) ? int((p * 100) / total) : 0
    printf "%s\t%d\t%d\t%d\n", f, p, fl, score
  }
}
' "$TMPFILE" > "$TMP_SUMMARY"

# --- Step 2: Rule violation heatmap (sorted desc) ---
awk '
{
  line = $0
  result = line; sub(/.*"result":"/, "", result); sub(/".*/, "", result)
  if (result != "FAIL") next

  rule = line; sub(/.*"rule":"/, "", rule); sub(/".*/, "", rule)
  desc = line; sub(/.*"desc":"/, "", desc); sub(/".*/, "", desc)

  count[rule]++
  if (!(rule in descs)) descs[rule] = desc
}
END {
  for (r in count) {
    printf "%d\t%s\t%s\n", count[r], r, descs[r]
  }
}
' "$TMPFILE" | sort -rn -t'	' -k1 > "$TMP_HEATMAP"

# --- Step 3: Detection rate (if expected_violations provided) ---
expected_count=0
detected_count=0
missed_count=0

if [ -n "$EXPECTED" ] && [ -f "$EXPECTED" ]; then
  # Build detected file:rule pairs
  awk '
  {
    line = $0
    result = line; sub(/.*"result":"/, "", result); sub(/".*/, "", result)
    if (result != "FAIL") next
    rule = line; sub(/.*"rule":"/, "", rule); sub(/".*/, "", rule)
    file = line; sub(/.*"file":"/, "", file); sub(/".*/, "", file)
    n = split(file, parts, "/")
    bname = parts[n]
    sub(/\.tsx$/, "", bname)
    print bname ":" rule
  }
  ' "$TMPFILE" | sort -u > "${TMP_DETECTION}.detected"

  > "${TMP_DETECTION}.missed"

  while IFS= read -r exp_line; do
    [ -z "$exp_line" ] && continue
    case "$exp_line" in \#*) continue ;; esac
    expected_count=$((expected_count + 1))
    if grep -qxF "$exp_line" "${TMP_DETECTION}.detected"; then
      detected_count=$((detected_count + 1))
    else
      missed_count=$((missed_count + 1))
      echo "$exp_line" >> "${TMP_DETECTION}.missed"
    fi
  done < "$EXPECTED"

  if [ "$expected_count" -gt 0 ]; then
    rate=$(( (detected_count * 100) / expected_count ))
  else
    rate=0
  fi
fi

# =============================================
# Terminal Output
# =============================================
echo ""
echo "══════════════════════════════════════════"
echo " Score Report — ${TODAY}"
echo "══════════════════════════════════════════"
echo ""

printf " %-40s %5s %5s %6s\n" "Page" "PASS" "FAIL" "Score"
echo " ──────────────────────────────────────────────────────────"

while IFS='	' read -r fname pass fail score; do
  printf " %-40s %5d %5d  %4d%%\n" "$fname" "$pass" "$fail" "$score"
done < "$TMP_SUMMARY"

# Heatmap
if [ -s "$TMP_HEATMAP" ]; then
  echo ""
  echo " Rule Violation Heatmap:"
  echo " ──────────────────────────────────────────────────────────"

  max_count=$(head -1 "$TMP_HEATMAP" | cut -f1)
  max_bar=40

  while IFS='	' read -r count rule desc; do
    if [ "$max_count" -gt "$max_bar" ]; then
      bar_len=$(( (count * max_bar) / max_count ))
    else
      bar_len=$count
    fi
    [ "$bar_len" -lt 1 ] && bar_len=1
    bar=$(printf '█%.0s' $(seq 1 "$bar_len"))
    label="${rule} (${desc})"
    if [ ${#label} -gt 45 ]; then
      label="$(printf '%.42s' "$label")..."
    fi
    printf " %-48s %s  %d\n" "$label" "$bar" "$count"
  done < "$TMP_HEATMAP"
fi

# Detection rate
if [ -n "$EXPECTED" ] && [ -f "$EXPECTED" ] && [ "$expected_count" -gt 0 ]; then
  echo ""
  echo " Detection Rate (adversarial):"
  echo " ──────────────────────────────────────────────────────────"
  printf " Expected: %d  Detected: %d  Missed: %d\n" "$expected_count" "$detected_count" "$missed_count"
  printf " Rate: %d%%\n" "$rate"

  if [ -s "${TMP_DETECTION}.missed" ]; then
    echo ""
    echo " Missed violations:"
    while IFS= read -r item; do
      echo "   - $item"
    done < "${TMP_DETECTION}.missed"
  fi
fi

echo ""

# =============================================
# Markdown Report
# =============================================
mkdir -p "$REPORT_DIR"

{
  echo "# Score Report — ${TODAY}"
  echo ""
  echo "## Summary"
  echo ""
  echo "| Page | PASS | FAIL | Score |"
  echo "|------|------|------|-------|"

  while IFS='	' read -r fname pass fail score; do
    echo "| ${fname} | ${pass} | ${fail} | ${score}% |"
  done < "$TMP_SUMMARY"

  echo ""

  # Heatmap table
  if [ -s "$TMP_HEATMAP" ]; then
    echo "## Rule Violation Heatmap"
    echo ""
    echo "| Rule | Description | Count |"
    echo "|------|-------------|-------|"
    while IFS='	' read -r count rule desc; do
      echo "| ${rule} | ${desc} | ${count} |"
    done < "$TMP_HEATMAP"
    echo ""
  fi

  # Failure Details — parse each FAIL line from the JSONL directly
  fail_count_total=$(grep -c '"result":"FAIL"' "$TMPFILE" 2>/dev/null || true)
  if [ "$fail_count_total" -gt 0 ]; then
    echo "## Failure Details"
    echo ""

    grep '"result":"FAIL"' "$TMPFILE" | while IFS= read -r line; do
      rule=$(echo "$line" | sed 's/.*"rule":"\([^"]*\)".*/\1/')
      desc=$(echo "$line" | sed 's/.*"desc":"\([^"]*\)".*/\1/')
      file=$(echo "$line" | sed 's/.*"file":"\([^"]*\)".*/\1/')

      echo "### ${rule} — ${desc}"
      echo ""
      echo "**File:** \`${file}\`"
      echo ""

      # Extract matches array if present
      if echo "$line" | grep -q '"matches"'; then
        echo "**Matches:**"
        echo "\`\`\`"
        # Extract content between "matches":[ and ]}
        # Then split on "," boundaries and clean up quotes
        echo "$line" | sed 's/.*"matches":\[//; s/\]}.*//' | \
          sed 's/","/\
/g' | sed 's/^"//; s/"$//' | sed 's/\\"/"/g'
        echo "\`\`\`"
      fi
      echo ""
    done
  fi

  # Detection Rate
  if [ -n "$EXPECTED" ] && [ -f "$EXPECTED" ] && [ "$expected_count" -gt 0 ]; then
    echo "## Detection Rate"
    echo ""
    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "| Expected | ${expected_count} |"
    echo "| Detected | ${detected_count} |"
    echo "| Missed | ${missed_count} |"
    echo "| Rate | ${rate}% |"
    echo ""

    if [ -s "${TMP_DETECTION}.missed" ]; then
      echo "### Missed Violations"
      echo ""
      while IFS= read -r item; do
        echo "- \`${item}\`"
      done < "${TMP_DETECTION}.missed"
      echo ""
    fi
  fi

  # Improvement Actions
  echo "## Improvement Actions"
  echo ""

  has_normal_failures=false
  if [ "$fail_count_total" -gt 0 ]; then
    normal_lines=$(grep '"result":"FAIL"' "$TMPFILE" | grep -v 'adversarial' || true)
    if [ -n "$normal_lines" ]; then
      has_normal_failures=true
      echo "### Rule Document Improvements"
      echo ""
      echo "Normal sample files with failures indicate rules that need clearer documentation:"
      echo ""
      echo "$normal_lines" | while IFS= read -r line; do
        rule=$(echo "$line" | sed 's/.*"rule":"\([^"]*\)".*/\1/')
        desc=$(echo "$line" | sed 's/.*"desc":"\([^"]*\)".*/\1/')
        file=$(echo "$line" | sed 's/.*"file":"\([^"]*\)".*/\1/')
        echo "- **${rule}** (${desc}) in \`${file}\`"
      done
      echo ""
    fi
  fi

  has_missed=false
  if [ -n "$EXPECTED" ] && [ -f "$EXPECTED" ] && [ -s "${TMP_DETECTION}.missed" 2>/dev/null ]; then
    has_missed=true
    echo "### Check Tool Improvements"
    echo ""
    echo "Expected violations that were not detected indicate gaps in check-rules.sh:"
    echo ""
    while IFS= read -r item; do
      echo "- \`${item}\`"
    done < "${TMP_DETECTION}.missed"
    echo ""
  fi

  if [ "$has_normal_failures" = false ] && [ "$has_missed" = false ]; then
    echo "No improvement actions needed."
    echo ""
  fi

} > "$REPORT_FILE"

echo "Report saved to ${REPORT_FILE}"

# Generate meta.json when output dir is specified
if [ -n "$OUTPUT_DIR" ]; then
  SNAP_ID=$(basename "$OUTPUT_DIR")
  SNAP_DATE=$(echo "$SNAP_ID" | sed 's/-run[0-9]*$//')
  SNAP_RUN=$(echo "$SNAP_ID" | grep -oE '[0-9]+$' || echo "1")

  # Build scores JSON from summary
  SCORES_JSON="{"
  first=true
  while IFS='	' read -r fname pass fail score; do
    page=$(echo "$fname" | sed 's/\.tsx$//')
    if [ "$first" = true ]; then first=false; else SCORES_JSON="${SCORES_JSON},"; fi
    SCORES_JSON="${SCORES_JSON}\"${page}\":{\"pass\":${pass},\"fail\":${fail},\"score\":${score}}"
  done < "$TMP_SUMMARY"
  SCORES_JSON="${SCORES_JSON}}"

  # Build prompts array
  PROMPTS_JSON="["
  first=true
  while IFS='	' read -r fname pass fail score; do
    page=$(echo "$fname" | sed 's/\.tsx$//')
    if [ "$first" = true ]; then first=false; else PROMPTS_JSON="${PROMPTS_JSON},"; fi
    PROMPTS_JSON="${PROMPTS_JSON}\"${page}\""
  done < "$TMP_SUMMARY"
  PROMPTS_JSON="${PROMPTS_JSON}]"

  DETECTION_RATE_VAL="${rate:-0}"

  cat > "${OUTPUT_DIR}/meta.json" << METAEOF
{
  "id": "${SNAP_ID}",
  "date": "${SNAP_DATE}",
  "run": ${SNAP_RUN},
  "prompts": ${PROMPTS_JSON},
  "scores": ${SCORES_JSON},
  "detectionRate": ${DETECTION_RATE_VAL},
  "buildPass": ${BUILD_PASS}
}
METAEOF

  # Copy JSONL as report.json
  cp "$TMPFILE" "${OUTPUT_DIR}/report.json"

  echo "Meta saved to ${OUTPUT_DIR}/meta.json"
fi
