#!/bin/bash
# Score report generator for shadcn-rules (v3 — A/B comparison)
# Reads JSONL from check-rules.sh and produces A/B comparison report
#
# Usage:
#   bash scripts/score-report.sh results.jsonl [output-dir] [build-pass]

set -euo pipefail

# --- Arguments ---
INPUT="${1:?Usage: score-report.sh <results.jsonl> [output-dir] [build-pass]}"
OUTPUT_DIR="${2:-}"
BUILD_PASS="${3:-true}"
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
TMP_AB=$(mktemp /tmp/score-report-ab.XXXXXX)
trap 'rm -f "$TMPFILE" "$TMP_SUMMARY" "$TMP_HEATMAP" "$TMP_AB"' EXIT

cp "$INPUT" "$TMPFILE"

if [ ! -s "$TMPFILE" ]; then
  echo "Error: No JSONL data received."
  exit 1
fi

# --- Step 1: Per-file summary (only page files) ---
awk '
BEGIN { nfiles = 0 }
{
  line = $0
  # Extract file field
  file = line
  sub(/.*"file":"/, "", file)
  sub(/".*/, "", file)

  # Only include page files
  if (file !~ /\/pages\//) next

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

# --- Step 2: Rule violation heatmap (only without_rules arm for comparison) ---
awk '
{
  line = $0
  file = line; sub(/.*"file":"/, "", file); sub(/".*/, "", file)
  result = line; sub(/.*"result":"/, "", result); sub(/".*/, "", result)
  if (result != "FAIL") next
  if (file !~ /\/pages\//) next
  if (file !~ /\.without_rules\./) next

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

# --- Step 3: A/B comparison ---
awk '
{
  line = $0
  file = line; sub(/.*"file":"/, "", file); sub(/".*/, "", file)
  if (file !~ /\/pages\//) next

  result = line; sub(/.*"result":"/, "", result); sub(/".*/, "", result)

  # Determine arm (with_rules or without_rules)
  arm = "unknown"
  if (file ~ /\.with_rules\./) arm = "with_rules"
  else if (file ~ /\.without_rules\./) arm = "without_rules"
  else next

  # Extract page name (strip arm suffix and .tsx)
  n = split(file, parts, "/")
  bname = parts[n]
  sub(/\.(with|without)_rules\.tsx$/, "", bname)

  key = bname "|" arm
  if (!(key in pass_c)) { pass_c[key] = 0; fail_c[key] = 0 }
  if (result == "PASS") pass_c[key]++
  else if (result == "FAIL") fail_c[key]++

  pages[bname] = 1
}
END {
  for (p in pages) {
    ka = p "|with_rules"
    kb = p "|without_rules"

    pa = pass_c[ka] + 0; fa = fail_c[ka] + 0
    pb = pass_c[kb] + 0; fb = fail_c[kb] + 0

    ta = pa + fa; tb = pb + fb
    sa = (ta > 0) ? int((pa * 100) / ta) : 0
    sb = (tb > 0) ? int((pb * 100) / tb) : 0
    delta = sa - sb

    printf "%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", p, pa, fa, sa, pb, fb, sb, delta
  }
}
' "$TMPFILE" | sort > "$TMP_AB"

# =============================================
# Terminal Output
# =============================================
echo ""
echo "══════════════════════════════════════════"
echo " Score Report — ${TODAY} (A/B Test)"
echo "══════════════════════════════════════════"
echo ""

# Per-file scores
printf " %-45s %5s %5s %6s\n" "Page" "PASS" "FAIL" "Score"
echo " ─────────────────────────────────────────────────────────────"

while IFS='	' read -r fname pass fail score; do
  printf " %-45s %5d %5d  %4d%%\n" "$fname" "$pass" "$fail" "$score"
done < "$TMP_SUMMARY"

# A/B Comparison
if [ -s "$TMP_AB" ]; then
  echo ""
  echo " A/B Comparison:"
  echo " ─────────────────────────────────────────────────────────────"
  printf " %-25s %12s %15s %7s %10s\n" "Page" "with_rules" "without_rules" "delta" "verdict"
  echo " ─────────────────────────────────────────────────────────────"

  while IFS='	' read -r page pa fa sa pb fb sb delta; do
    if [ "$delta" -ge 20 ]; then
      verdict="EFFECTIVE"
    elif [ "$delta" -ge 5 ]; then
      verdict="MARGINAL"
    elif [ "$delta" -ge 0 ]; then
      verdict="NO DIFF"
    else
      verdict="NEGATIVE"
    fi
    printf " %-25s %10d%%  %13d%%  %+5d%%  %10s\n" "$page" "$sa" "$sb" "$delta" "$verdict"
  done < "$TMP_AB"
fi

# Heatmap
if [ -s "$TMP_HEATMAP" ]; then
  echo ""
  echo " Rule Violation Heatmap:"
  echo " ─────────────────────────────────────────────────────────────"

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

echo ""

# =============================================
# Markdown Report
# =============================================
mkdir -p "$REPORT_DIR"

{
  echo "# Score Report — ${TODAY} (A/B Test)"
  echo ""

  # A/B Comparison section (primary metric)
  if [ -s "$TMP_AB" ]; then
    echo "## A/B Comparison"
    echo ""
    echo "| Page | with_rules | without_rules | delta | verdict |"
    echo "|------|-----------|--------------|-------|---------|"
    while IFS='	' read -r page pa fa sa pb fb sb delta; do
      if [ "$delta" -ge 20 ]; then
        verdict="EFFECTIVE"
      elif [ "$delta" -ge 5 ]; then
        verdict="MARGINAL"
      elif [ "$delta" -ge 0 ]; then
        verdict="NO DIFF"
      else
        verdict="NEGATIVE"
      fi
      delta_fmt=$(printf "%+d" "$delta")
      echo "| ${page} | ${sa}% | ${sb}% | ${delta_fmt}% | ${verdict} |"
    done < "$TMP_AB"
    echo ""
  fi

  # Per-file detail
  echo "## Per-File Scores"
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

  # Failure Details — only page files
  fail_lines=$(grep '"result":"FAIL"' "$TMPFILE" | grep '/pages/' || true)

  if [ -n "$fail_lines" ]; then
    echo "## Failure Details"
    echo ""

    echo "$fail_lines" | while IFS= read -r line; do
      rule=$(echo "$line" | sed 's/.*"rule":"\([^"]*\)".*/\1/')
      desc=$(echo "$line" | sed 's/.*"desc":"\([^"]*\)".*/\1/')
      file=$(echo "$line" | sed 's/.*"file":"\([^"]*\)".*/\1/')

      # Show only basename for readability
      bname=$(basename "$file")

      echo "### ${rule} — ${desc}"
      echo ""
      echo "**File:** \`${bname}\`"
      echo ""

      # Extract matches array if present
      if echo "$line" | grep -q '"matches"'; then
        echo "**Matches:**"
        echo "\`\`\`"
        echo "$line" | sed 's/.*"matches":\[//; s/\]}.*//' | \
          sed 's/","/\
/g' | sed 's/^"//; s/"$//' | sed 's/\\"/"/g'
        echo "\`\`\`"
      fi
      echo ""
    done
  fi

  # Improvement Actions
  echo "## Improvement Actions"
  echo ""

  has_a_failures=false
  if [ -n "$fail_lines" ]; then
    a_failures=$(echo "$fail_lines" | grep 'with_rules' || true)
    if [ -n "$a_failures" ]; then
      has_a_failures=true
      echo "### Rule Document Improvements"
      echo ""
      echo "with_rules arm failures indicate rules that need clearer documentation:"
      echo ""
      echo "$a_failures" | while IFS= read -r line; do
        rule=$(echo "$line" | sed 's/.*"rule":"\([^"]*\)".*/\1/')
        desc=$(echo "$line" | sed 's/.*"desc":"\([^"]*\)".*/\1/')
        file=$(echo "$line" | sed 's/.*"file":"\([^"]*\)".*/\1/')
        bname=$(basename "$file")
        echo "- **${rule}** (${desc}) in \`${bname}\`"
      done
      echo ""
    fi
  fi

  has_no_diff=false
  if [ -s "$TMP_AB" ]; then
    while IFS='	' read -r page pa fa sa pb fb sb delta; do
      if [ "$delta" -lt 5 ]; then
        has_no_diff=true
        break
      fi
    done < "$TMP_AB"
  fi

  if [ "$has_no_diff" = true ]; then
    echo "### Low-Impact Rules"
    echo ""
    echo "Pages where rules showed minimal improvement:"
    echo ""
    while IFS='	' read -r page pa fa sa pb fb sb delta; do
      if [ "$delta" -lt 5 ]; then
        echo "- **${page}**: delta=${delta}% — rules may need strengthening or prompt is too simple"
      fi
    done < "$TMP_AB"
    echo ""
  fi

  if [ "$has_a_failures" = false ] && [ "$has_no_diff" = false ]; then
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

  # Build scores JSON from A/B data
  SCORES_JSON="{"
  first=true
  while IFS='	' read -r page pa fa sa pb fb sb delta; do
    if [ "$first" = true ]; then first=false; else SCORES_JSON="${SCORES_JSON},"; fi
    SCORES_JSON="${SCORES_JSON}\"${page}\":{\"with_rules\":{\"pass\":${pa},\"fail\":${fa},\"score\":${sa}},\"without_rules\":{\"pass\":${pb},\"fail\":${fb},\"score\":${sb}},\"delta\":${delta}}"
  done < "$TMP_AB"
  SCORES_JSON="${SCORES_JSON}}"

  # Build prompts array (deduplicated page names)
  PROMPTS_JSON="["
  first=true
  while IFS='	' read -r page rest; do
    if [ "$first" = true ]; then first=false; else PROMPTS_JSON="${PROMPTS_JSON},"; fi
    PROMPTS_JSON="${PROMPTS_JSON}\"${page}\""
  done < "$TMP_AB"
  PROMPTS_JSON="${PROMPTS_JSON}]"

  cat > "${OUTPUT_DIR}/meta.json" << METAEOF
{
  "id": "${SNAP_ID}",
  "date": "${SNAP_DATE}",
  "run": ${SNAP_RUN},
  "mode": "ab",
  "prompts": ${PROMPTS_JSON},
  "scores": ${SCORES_JSON},
  "buildPass": ${BUILD_PASS}
}
METAEOF

  # Copy JSONL as report.json
  cp "$TMPFILE" "${OUTPUT_DIR}/report.json"

  echo "Meta saved to ${OUTPUT_DIR}/meta.json"
fi
