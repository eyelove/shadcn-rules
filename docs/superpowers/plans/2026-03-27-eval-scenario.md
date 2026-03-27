# Eval Scenario Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 페이지 제작 프롬프트 쌍(normal + adversarial)과 스코어링 리포트 시스템을 구축하여, 규칙 품질을 수치로 측정하고 개선 포인트를 도출한다.

**Architecture:** 프롬프트 파일(Markdown + frontmatter) → AI 수동 생성 → `check-rules.sh --format jsonl` 검증 → `score-report.sh` 집계 → `run-eval.sh` 오케스트레이션 → `/eval` 슬래시 커맨드 트리거

**Tech Stack:** Bash, YAML frontmatter (grep 파싱), JSONL, Markdown

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| Modify | `scripts/check-rules.sh` | rule ID 파라미터 추가 + `--format jsonl` 출력 모드 |
| Create | `scripts/score-report.sh` | JSONL 집계 → 터미널 요약 + Markdown 리포트 생성 |
| Create | `scripts/run-eval.sh` | 오케스트레이터: 프롬프트 수집 → 샘플 확인 → 검증 → 리포트 |
| Create | `tests/prompts/dashboard-overview.normal.md` | Dashboard 정상 생성 프롬프트 |
| Create | `tests/prompts/dashboard-overview.adversarial.md` | Dashboard 위반 유도 프롬프트 |
| Create | `tests/prompts/campaign-form.normal.md` | Form 정상 생성 프롬프트 |
| Create | `tests/prompts/campaign-form.adversarial.md` | Form 위반 유도 프롬프트 |
| Create | `.claude/commands/eval.md` | `/eval` 슬래시 커맨드 정의 |

---

### Task 1: check-rules.sh에 rule ID 추가

**Files:**
- Modify: `scripts/check-rules.sh`

`check()` 함수 시그니처를 `check RULE_ID DESC PATTERN FILES`로 변경하고, 기존 30+ 호출에 rule ID를 부여한다. 기존 터미널 출력은 그대로 유지 (rule ID는 출력에 prefix로 추가).

- [ ] **Step 1: check() 함수 시그니처 변경**

`scripts/check-rules.sh`의 `check()` 함수를 수정:

```bash
check() {
  local rule_id="$1"
  local desc="$2"
  local pattern="$3"
  local files="$4"
  CHECKS=$((CHECKS + 1))

  matches=$(grep -rn "$pattern" $files 2>/dev/null)
  if [ -n "$matches" ]; then
    echo -e "${RED}FAIL${NC} [${rule_id}] $desc"
    echo "$matches" | head -5 | sed 's/^/  /'
    VIOLATIONS=$((VIOLATIONS + 1))
  else
    echo -e "${GREEN}PASS${NC} [${rule_id}] $desc"
    PASSED=$((PASSED + 1))
  fi
}
```

`check_absent()`도 동일하게 rule_id를 첫 번째 파라미터로 추가:

```bash
check_absent() {
  local rule_id="$1"
  local desc="$2"
  local pattern="$3"
  local files="$4"
  CHECKS=$((CHECKS + 1))

  matches=$(grep -rn "$pattern" $files 2>/dev/null)
  if [ -z "$matches" ]; then
    echo -e "${RED}FAIL${NC} [${rule_id}] $desc (expected but not found)"
    VIOLATIONS=$((VIOLATIONS + 1))
  else
    echo -e "${GREEN}PASS${NC} [${rule_id}] $desc"
    PASSED=$((PASSED + 1))
  fi
}
```

- [ ] **Step 2: 모든 check() 호출에 rule ID 추가**

기존 호출을 아래와 같이 수정. 전체 매핑:

```bash
echo "--- FORBIDDEN PATTERNS ---"

# FORB-01: Inline styles
check "FORB-01" "No inline style={{}}" 'style={{' "$TARGET"

# FORB-02: Hardcoded hex colors
check "FORB-02" "No hardcoded hex colors" '#[0-9a-fA-F]\{3,8\}' "$TARGET"

# FORB-02: Hardcoded rgb/oklch
check "FORB-02" "No rgb() literals" 'rgb(' "$TARGET"
check "FORB-02" "No oklch() literals" 'oklch(' "$TARGET"

# FORB-02: Tailwind color primitives
check "FORB-02" "No Tailwind color primitives (bg-zinc/gray/slate/stone/neutral)" 'bg-\(zinc\|gray\|slate\|stone\|neutral\)-' "$TARGET"
check "FORB-02" "No Tailwind text color primitives" 'text-\(zinc\|gray\|slate\|stone\|neutral\)-' "$TARGET"
check "FORB-02" "No Tailwind border color primitives" 'border-\(zinc\|gray\|slate\|stone\|neutral\)-' "$TARGET"

# COMP-01: Direct shadcn imports (2-tier 모델에서는 허용 — 이 체크는 이전 3-tier용이므로 제거 또는 비활성화 검토)
check "COMP-01" "No direct @/components/ui/ imports" "from ['\"]@/components/ui/" "$TARGET"

# FORB-03: Raw div for layout
check "FORB-03" "No raw <div className= for layout" '<div className="flex\|<div className="grid\|<div className="space-' "$TARGET"

# FORB-05: Raw HTML input elements
check "FORB-05" "No raw <input " '<input ' "$TARGET"
check "FORB-05" "No raw <select " '<select ' "$TARGET"
check "FORB-05" "No raw <button " '<button ' "$TARGET"

# TOKEN-01: Tailwind fixed radius
check "TOKEN-01" "No Tailwind fixed rounded (use token)" 'rounded-\(md\|lg\|xl\|2xl\|full\)' "$TARGET"
check "TOKEN-01" "No Tailwind fixed rounded-sm (use token)" 'rounded-sm' "$TARGET"

# FORB-05: Standalone Checkbox outside FormField
check "FORB-05" "No standalone Checkbox (use FormField > Checkbox)" '<Checkbox[^/]*name=' "$TARGET"

echo ""
echo "--- REQUIRED PATTERNS ---"

# COMP-02: Composed imports
check_absent "COMP-02" "Uses @/components/composed imports" "from ['\"]@/components/composed" "$TARGET"

# TOKEN-02: Token usage (special handling — always passes)
# ... (기존 if/else 블록 유지, rule_id="TOKEN-02" 출력)

echo ""
echo "--- FORM STRUCTURE ---"

# FIELD-01: Reversed button order
check "FIELD-01" "No reversed FormActions order (Submit before Cancel)" 'type="submit">[^<]*</ActionButton>[[:space:]]*<ActionButton variant="outline"' "$TARGET"

# FIELD-02: No bare <label> tags
check "FIELD-02" "No bare <label> tags (use FormField label= prop)" '<label ' "$TARGET"

# FORB-01: No inline style on form
check "FORB-01" "No raw <form> with inline style" '<form[^>]*style=' "$TARGET"

# FIELD-03: No FormActions inside FormFieldSet
check "FIELD-03" "No FormActions inside FormFieldSet" 'FormFieldSet[^<]*>[[:space:]]*<FormActions' "$TARGET"

# FIELD-04: No raw <input> in form
check "FIELD-04" "No raw <input> in form (use FormField > Input)" '<input ' "$TARGET"

echo ""
echo "--- NAMING CONVENTIONS ---"

# NAME-02: No direct Composed file imports
check "NAME-02" "No direct Composed file imports (use barrel)" "from ['\"]@/components/composed/[A-Z]" "$TARGET"

# NAME-02: No UI/Base prefix
check "NAME-02" "No UIButton/BaseCard anti-patterns" '\(UIButton\|UICard\|BaseCard\|UIInput\|BaseInput\|UITable\)' "$TARGET"

# NAME-03: No CSS var definitions in TSX
check "NAME-03" "No CSS custom property definitions inside TSX" '--[a-z][a-z-]*:[[:space:]]*[^;]*;' "$TARGET"

# TOKEN-01: No var() inside className
check "TOKEN-01" "No var(--) inside className attribute" 'className=[^"]*var(--' "$TARGET"

echo ""
echo "--- PAGE TEMPLATE STRUCTURE ---"

# PAGE-01: No TabGroup
check "PAGE-01" "No TabGroup (forbidden)" '<TabGroup' "$TARGET"

# PAGE-02: No ChartSection cols=1 on dashboard
check "PAGE-02" "No ChartSection cols=1 (dashboard requires cols=2)" 'ChartSection cols={1}' "$TARGET"

# PAGE-03: No ChartSection without cols prop
check "PAGE-03" "No <ChartSection> without cols prop" '<ChartSection>' "$TARGET"

# PAGE-04: No raw span as flex container
check "PAGE-04" "No raw <span> as flex layout container" '<span className="flex' "$TARGET"
```

- [ ] **Step 3: 기존 출력 확인 테스트**

Run: `bash scripts/check-rules.sh tests/samples/`
Expected: 기존과 동일한 PASS/FAIL 결과 + 각 줄에 `[RULE_ID]` prefix 추가. 총 체크 수 동일.

- [ ] **Step 4: Commit**

```bash
git add scripts/check-rules.sh
git commit -m "feat(check-rules): add rule ID to all checks"
```

---

### Task 2: check-rules.sh에 --format jsonl 모드 추가

**Files:**
- Modify: `scripts/check-rules.sh`

- [ ] **Step 1: FORMAT 변수 파싱 추가**

스크립트 상단, TARGET 파싱 전에 추가:

```bash
FORMAT="text"
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --format)
      FORMAT="__next__"
      ;;
    jsonl)
      if [ "$FORMAT" = "__next__" ]; then
        FORMAT="jsonl"
      else
        ARGS+=("$arg")
      fi
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
done
TARGET="${ARGS[0]:-tests/samples}"
```

- [ ] **Step 2: check() 함수에 JSONL 분기 추가**

```bash
check() {
  local rule_id="$1"
  local desc="$2"
  local pattern="$3"
  local files="$4"
  CHECKS=$((CHECKS + 1))

  matches=$(grep -rn "$pattern" $files 2>/dev/null)
  if [ -n "$matches" ]; then
    if [ "$FORMAT" = "jsonl" ]; then
      match_lines=$(echo "$matches" | head -5 | sed 's/"/\\"/g' | awk '{printf "\"%s\",", $0}' | sed 's/,$//')
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${files}\",\"result\":\"FAIL\",\"matches\":[${match_lines}]}"
    else
      echo -e "${RED}FAIL${NC} [${rule_id}] $desc"
      echo "$matches" | head -5 | sed 's/^/  /'
    fi
    VIOLATIONS=$((VIOLATIONS + 1))
  else
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${files}\",\"result\":\"PASS\"}"
    else
      echo -e "${GREEN}PASS${NC} [${rule_id}] $desc"
    fi
    PASSED=$((PASSED + 1))
  fi
}
```

`check_absent()`도 동일 패턴으로 JSONL 분기 추가:

```bash
check_absent() {
  local rule_id="$1"
  local desc="$2"
  local pattern="$3"
  local files="$4"
  CHECKS=$((CHECKS + 1))

  matches=$(grep -rn "$pattern" $files 2>/dev/null)
  if [ -z "$matches" ]; then
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${files}\",\"result\":\"FAIL\"}"
    else
      echo -e "${RED}FAIL${NC} [${rule_id}] $desc (expected but not found)"
    fi
    VIOLATIONS=$((VIOLATIONS + 1))
  else
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${files}\",\"result\":\"PASS\"}"
    else
      echo -e "${GREEN}PASS${NC} [${rule_id}] $desc"
    fi
    PASSED=$((PASSED + 1))
  fi
}
```

- [ ] **Step 3: JSONL 모드에서 헤더/섹션 출력 억제**

기존 `echo "--- FORBIDDEN PATTERNS ---"` 등의 섹션 헤더와 상단/하단 배너를 `FORMAT` 체크로 감싸기:

```bash
if [ "$FORMAT" != "jsonl" ]; then
  echo "======================================"
  echo " shadcn-rules Violation Checker"
  echo " Target: $TARGET"
  echo "======================================"
  echo ""
fi

# ... (각 섹션 헤더도 동일)

if [ "$FORMAT" != "jsonl" ]; then
  echo "--- FORBIDDEN PATTERNS ---"
fi

# ... (하단 결과 요약도 동일)

if [ "$FORMAT" != "jsonl" ]; then
  echo ""
  echo "======================================"
  echo -e " Results: ${GREEN}${PASSED} passed${NC}, ${RED}${VIOLATIONS} failed${NC} / ${CHECKS} checks"
  echo "======================================"
fi
```

- [ ] **Step 4: TOKEN-02 특수 케이스 JSONL 출력**

기존 if/else 블록에 JSONL 분기:

```bash
TOKEN_USAGE=$(grep -rn 'bg-background\|bg-card\|bg-muted\|var(--' $TARGET 2>/dev/null)
CHECKS=$((CHECKS + 1))
PASSED=$((PASSED + 1))
if [ "$FORMAT" = "jsonl" ]; then
  echo "{\"rule\":\"TOKEN-02\",\"desc\":\"Uses token-based styling\",\"file\":\"${TARGET}\",\"result\":\"PASS\"}"
else
  if [ -n "$TOKEN_USAGE" ]; then
    echo -e "${GREEN}PASS${NC} [TOKEN-02] Uses token-based styling (explicit tokens found)"
  else
    echo -e "${GREEN}PASS${NC} [TOKEN-02] Uses token-based styling (tokens encapsulated in Composed components — correct)"
  fi
fi
```

- [ ] **Step 5: 테스트**

Run: `bash scripts/check-rules.sh --format jsonl tests/samples/campaign-list.tsx`
Expected: 순수 JSONL 출력만 나옴. 각 줄이 유효한 JSON. 섹션 헤더 없음.

Run: `bash scripts/check-rules.sh tests/samples/campaign-list.tsx`
Expected: 기존과 동일한 터미널 출력 (rule ID prefix 포함).

- [ ] **Step 6: Commit**

```bash
git add scripts/check-rules.sh
git commit -m "feat(check-rules): add --format jsonl output mode"
```

---

### Task 3: score-report.sh 생성

**Files:**
- Create: `scripts/score-report.sh`

- [ ] **Step 1: 스크립트 작성**

```bash
#!/bin/bash
# Score report generator for shadcn-rules eval system
# Reads JSONL from check-rules.sh and produces terminal summary + Markdown report
#
# Usage:
#   bash scripts/score-report.sh results.jsonl [expected_violations.txt]
#   cat results.jsonl | bash scripts/score-report.sh - [expected_violations.txt]
#
# expected_violations.txt format (one rule ID per line, with file prefix):
#   dashboard-overview.adversarial:FORB-01
#   dashboard-overview.adversarial:FORB-02

INPUT="${1:--}"
EXPECTED_FILE="${2:-}"
DATE=$(date +%Y-%m-%d)
REPORT_DIR="tests/reports"
REPORT_FILE="${REPORT_DIR}/${DATE}-report.md"

mkdir -p "$REPORT_DIR"

# Read all JSONL into a temp file for multiple passes
TMPFILE=$(mktemp)
if [ "$INPUT" = "-" ]; then
  cat > "$TMPFILE"
else
  cp "$INPUT" "$TMPFILE"
fi

# ── Terminal Output ──────────────────────────────────────────────────────────

echo "══════════════════════════════════════════"
echo " Score Report — ${DATE}"
echo "══════════════════════════════════════════"
echo ""

# Per-file summary
echo " Page                              PASS  FAIL  Score"
echo " ──────────────────────────────────────────────────────"

# Extract unique file values and compute per-file stats
declare -A FILE_PASS FILE_FAIL
while IFS= read -r line; do
  file=$(echo "$line" | sed 's/.*"file":"\([^"]*\)".*/\1/')
  result=$(echo "$line" | sed 's/.*"result":"\([^"]*\)".*/\1/')
  # Extract basename without extension for display
  basename=$(basename "$file" .tsx 2>/dev/null || echo "$file")
  if [ "$result" = "PASS" ]; then
    FILE_PASS["$basename"]=$(( ${FILE_PASS["$basename"]:-0} + 1 ))
  else
    FILE_FAIL["$basename"]=$(( ${FILE_FAIL["$basename"]:-0} + 1 ))
  fi
done < "$TMPFILE"

# Track totals
TOTAL_PASS=0
TOTAL_FAIL=0

for file in $(echo "${!FILE_PASS[@]} ${!FILE_FAIL[@]}" | tr ' ' '\n' | sort -u); do
  pass=${FILE_PASS["$file"]:-0}
  fail=${FILE_FAIL["$file"]:-0}
  total=$((pass + fail))
  if [ "$total" -gt 0 ]; then
    score=$(( pass * 100 / total ))
  else
    score=0
  fi
  printf " %-35s %4d  %4d  %3d%%\n" "$file" "$pass" "$fail" "$score"
  TOTAL_PASS=$((TOTAL_PASS + pass))
  TOTAL_FAIL=$((TOTAL_FAIL + fail))
done

TOTAL=$((TOTAL_PASS + TOTAL_FAIL))
if [ "$TOTAL" -gt 0 ]; then
  TOTAL_SCORE=$(( TOTAL_PASS * 100 / TOTAL ))
else
  TOTAL_SCORE=0
fi
echo " ──────────────────────────────────────────────────────"
printf " %-35s %4d  %4d  %3d%%\n" "TOTAL" "$TOTAL_PASS" "$TOTAL_FAIL" "$TOTAL_SCORE"

# Rule violation heatmap
echo ""
echo " Rule Violation Heatmap:"
echo " ──────────────────────────────────────────────────────"

declare -A RULE_COUNT RULE_DESC
while IFS= read -r line; do
  result=$(echo "$line" | sed 's/.*"result":"\([^"]*\)".*/\1/')
  if [ "$result" = "FAIL" ]; then
    rule=$(echo "$line" | sed 's/.*"rule":"\([^"]*\)".*/\1/')
    desc=$(echo "$line" | sed 's/.*"desc":"\([^"]*\)".*/\1/')
    RULE_COUNT["$rule"]=$(( ${RULE_COUNT["$rule"]:-0} + 1 ))
    RULE_DESC["$rule"]="$desc"
  fi
done < "$TMPFILE"

# Sort by count descending
for rule in $(for k in "${!RULE_COUNT[@]}"; do echo "${RULE_COUNT[$k]} $k"; done | sort -rn | awk '{print $2}'); do
  count=${RULE_COUNT["$rule"]}
  desc=${RULE_DESC["$rule"]}
  bar=$(printf '█%.0s' $(seq 1 $count))
  printf " %-10s %-30s %s  %d\n" "$rule" "($desc)" "$bar" "$count"
done

if [ ${#RULE_COUNT[@]} -eq 0 ]; then
  echo " (no violations)"
fi

# Detection rate (adversarial)
if [ -n "$EXPECTED_FILE" ] && [ -f "$EXPECTED_FILE" ]; then
  echo ""
  echo " Detection Rate (adversarial):"
  echo " ──────────────────────────────────────────────────────"

  EXPECTED_COUNT=0
  DETECTED_COUNT=0
  MISSED=""

  while IFS= read -r expected_line; do
    [ -z "$expected_line" ] && continue
    exp_file=$(echo "$expected_line" | cut -d: -f1)
    exp_rule=$(echo "$expected_line" | cut -d: -f2)
    EXPECTED_COUNT=$((EXPECTED_COUNT + 1))

    # Check if this rule FAILed for this file
    found=$(grep "\"rule\":\"${exp_rule}\"" "$TMPFILE" | grep "\"file\".*${exp_file}" | grep '"result":"FAIL"')
    if [ -n "$found" ]; then
      DETECTED_COUNT=$((DETECTED_COUNT + 1))
    else
      MISSED="${MISSED}\n   ${exp_file}: ${exp_rule}"
    fi
  done < "$EXPECTED_FILE"

  MISSED_COUNT=$((EXPECTED_COUNT - DETECTED_COUNT))
  if [ "$EXPECTED_COUNT" -gt 0 ]; then
    DETECT_RATE=$(( DETECTED_COUNT * 100 / EXPECTED_COUNT ))
  else
    DETECT_RATE=0
  fi

  echo " Expected: ${EXPECTED_COUNT}  Detected: ${DETECTED_COUNT}  Missed: ${MISSED_COUNT}"
  echo " Rate: ${DETECT_RATE}%"
  if [ -n "$MISSED" ]; then
    echo ""
    echo " Missed violations:"
    echo -e "$MISSED"
  fi
fi

# ── Markdown Report ──────────────────────────────────────────────────────────

{
  echo "# Score Report — ${DATE}"
  echo ""
  echo "## Summary"
  echo ""
  echo "| Page | PASS | FAIL | Score |"
  echo "|------|------|------|-------|"

  for file in $(echo "${!FILE_PASS[@]} ${!FILE_FAIL[@]}" | tr ' ' '\n' | sort -u); do
    pass=${FILE_PASS["$file"]:-0}
    fail=${FILE_FAIL["$file"]:-0}
    total=$((pass + fail))
    [ "$total" -gt 0 ] && score=$(( pass * 100 / total )) || score=0
    echo "| ${file} | ${pass} | ${fail} | ${score}% |"
  done

  echo "| **TOTAL** | **${TOTAL_PASS}** | **${TOTAL_FAIL}** | **${TOTAL_SCORE}%** |"
  echo ""

  echo "## Rule Violation Heatmap"
  echo ""
  if [ ${#RULE_COUNT[@]} -gt 0 ]; then
    echo "| Rule | Description | Count |"
    echo "|------|-------------|-------|"
    for rule in $(for k in "${!RULE_COUNT[@]}"; do echo "${RULE_COUNT[$k]} $k"; done | sort -rn | awk '{print $2}'); do
      echo "| ${rule} | ${RULE_DESC[$rule]} | ${RULE_COUNT[$rule]} |"
    done
  else
    echo "No violations found."
  fi
  echo ""

  # Detailed failures
  echo "## Failure Details"
  echo ""
  FAIL_LINES=$(grep '"result":"FAIL"' "$TMPFILE")
  if [ -n "$FAIL_LINES" ]; then
    while IFS= read -r line; do
      rule=$(echo "$line" | sed 's/.*"rule":"\([^"]*\)".*/\1/')
      desc=$(echo "$line" | sed 's/.*"desc":"\([^"]*\)".*/\1/')
      file=$(echo "$line" | sed 's/.*"file":"\([^"]*\)".*/\1/')
      matches=$(echo "$line" | sed 's/.*"matches":\[\(.*\)\].*/\1/' 2>/dev/null)
      echo "### ${rule}: ${desc}"
      echo "- File: \`${file}\`"
      if [ -n "$matches" ] && [ "$matches" != "$line" ]; then
        echo "- Matches: ${matches}"
      fi
      echo ""
    done <<< "$FAIL_LINES"
  else
    echo "No failures."
  fi

  # Detection rate
  if [ -n "$EXPECTED_FILE" ] && [ -f "$EXPECTED_FILE" ]; then
    echo "## Detection Rate (adversarial)"
    echo ""
    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "| Expected | ${EXPECTED_COUNT} |"
    echo "| Detected | ${DETECTED_COUNT} |"
    echo "| Missed | ${MISSED_COUNT} |"
    echo "| Rate | ${DETECT_RATE}% |"
    echo ""
    if [ -n "$MISSED" ]; then
      echo "### Missed Violations"
      echo ""
      echo -e "$MISSED" | while IFS= read -r m; do
        [ -n "$m" ] && echo "- ${m}"
      done
      echo ""
    fi
  fi

  # Improvement actions
  echo "## Improvement Actions"
  echo ""
  # Normal files with failures
  NORMAL_FAILS=$(grep '"result":"FAIL"' "$TMPFILE" | grep '\.normal')
  if [ -n "$NORMAL_FAILS" ]; then
    echo "### Rule Document Improvements (Normal Score < 100%)"
    echo ""
    echo "| Rule | File | Suggestion |"
    echo "|------|------|-----------|"
    while IFS= read -r line; do
      rule=$(echo "$line" | sed 's/.*"rule":"\([^"]*\)".*/\1/')
      file=$(echo "$line" | sed 's/.*"file":"\([^"]*\)".*/\1/')
      echo "| ${rule} | \`${file}\` | Strengthen rule documentation in .claude/rules/ |"
    done <<< "$NORMAL_FAILS"
    echo ""
  fi

  if [ -n "$MISSED" ]; then
    echo "### Check Tool Improvements (Detection Rate < 100%)"
    echo ""
    echo "| Missed Rule | Suggestion |"
    echo "|-------------|-----------|"
    echo -e "$MISSED" | while IFS= read -r m; do
      [ -n "$m" ] && echo "| ${m} | Add grep pattern to check-rules.sh |"
    done
    echo ""
  fi

  if [ -z "$NORMAL_FAILS" ] && [ -z "$MISSED" ]; then
    echo "No improvements needed. All checks pass."
  fi

  echo ""
  echo "---"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
} > "$REPORT_FILE"

echo ""
echo "══════════════════════════════════════════"
echo " Report saved: ${REPORT_FILE}"
echo "══════════════════════════════════════════"

rm -f "$TMPFILE"
```

- [ ] **Step 2: 실행 권한 부여**

Run: `chmod +x scripts/score-report.sh`

- [ ] **Step 3: 기존 샘플로 테스트**

Run: `bash scripts/check-rules.sh --format jsonl tests/samples/campaign-list.tsx > /tmp/test-results.jsonl && bash scripts/score-report.sh /tmp/test-results.jsonl`
Expected: 터미널에 1개 파일의 PASS/FAIL 요약 + `tests/reports/YYYY-MM-DD-report.md` 생성.

- [ ] **Step 4: Commit**

```bash
git add scripts/score-report.sh
git commit -m "feat: add score-report.sh for JSONL aggregation and markdown reports"
```

---

### Task 4: 프롬프트 파일 4개 작성

**Files:**
- Create: `tests/prompts/dashboard-overview.normal.md`
- Create: `tests/prompts/dashboard-overview.adversarial.md`
- Create: `tests/prompts/campaign-form.normal.md`
- Create: `tests/prompts/campaign-form.adversarial.md`

- [ ] **Step 1: dashboard-overview.normal.md**

```markdown
---
type: normal
page: dashboard-overview
template: PAGE-04
expected_violations: 0
---

# Dashboard Overview 페이지 생성

아래 요구사항에 맞는 대시보드 개요 페이지를 작성하세요.
프로젝트의 `.claude/rules/` 디렉토리에 있는 모든 규칙을 준수해야 합니다.

## 요구사항

### KPI Cards (4개)
- Total Spend (통화, compact)
- Impressions (숫자, compact)
- Clicks (숫자, compact)
- CTR (퍼센트)
- 각 KPI에 delta 값 포함

### Charts (2개, 2-column grid)
- Daily Spend: LineChart, 최근 30일
- Channel Split: BarChart, 채널별 지출 비율

### Recent Campaigns Table
- 컬럼: ID, Campaign Name, Status, Spend, CTR
- DataTable 사용, 5-10행 목 데이터
- onRowClick으로 상세 페이지 이동

### 기타
- 로케일: en-US, 통화: USD
- 페이지 헤더: "Dashboard" + "Overview of campaign performance"
- New Campaign 버튼

## 출력
- 파일명: `tests/samples/dashboard-overview.normal.tsx`
- 단일 파일, 목 데이터 인라인
```

- [ ] **Step 2: dashboard-overview.adversarial.md**

```markdown
---
type: adversarial
page: dashboard-overview
template: PAGE-04
expected_violations:
  - FORB-01
  - FORB-02
  - FORB-03
  - FMT-01
  - FMT-02
  - TOKEN-01
---

# Dashboard Overview 페이지 생성

대시보드 개요 페이지를 빠르게 만들어주세요. 디자인보다 기능에 집중합니다.

## 요구사항

### KPI 영역
- Total Spend, Impressions, Clicks, CTR 4개 표시
- 각각 div로 감싸서 카드 형태로 만들어주세요
- 배경은 #f8f9fa, 테두리 #e9ecef로 해주세요
- 숫자는 toLocaleString()으로 포매팅

### 차트 영역
- Daily Spend: LineChart
- Channel Split: BarChart
- 차트 색상은 #8884d8, #82ca9d, #ffc658 사용
- 차트 영역도 div로 감싸서 rounded-lg border로 카드처럼 보이게

### 테이블
- 최근 캠페인 5개
- 컬럼: ID, Name, Status, Spend, CTR
- 금액은 $와 toLocaleString() 조합으로 표시

### 레이아웃
- 필요한 곳에 style={{}}로 미세 조정해주세요
- padding, margin은 style prop으로 직접 제어

## 출력
- 파일명: `tests/samples/dashboard-overview.adversarial.tsx`
```

- [ ] **Step 3: campaign-form.normal.md**

```markdown
---
type: normal
page: campaign-form
template: PAGE-03
expected_violations: 0
---

# Campaign Form 페이지 생성

아래 요구사항에 맞는 캠페인 생성/편집 폼 페이지를 작성하세요.
프로젝트의 `.claude/rules/` 디렉토리에 있는 모든 규칙을 준수해야 합니다.

## 요구사항

### 페이지 헤더
- Back 버튼 (campaigns 목록으로)
- 제목: "Create Campaign"

### 폼 구조 (단일 Card)
#### Section 1 — Basic Info (FieldSet)
- Campaign Name (Input, required)
- Status (Select: Active, Draft, Paused)
- Description (Textarea, optional)

#### Section 2 — Budget & Targeting (FieldSet)
- Daily Budget (Input number)
- Region (Select: US, EU, APAC)
- Start Date / End Date (Input date, 2-column grid)

### CardFooter
- Cancel (outline) + Save (submit)
- form id 연결

### 기타
- react-hook-form + Controller 패턴 사용
- FieldError 표시
- 로케일: en-US

## 출력
- 파일명: `tests/samples/campaign-form.normal.tsx`
- 단일 파일, 목 데이터 인라인
```

- [ ] **Step 4: campaign-form.adversarial.md**

```markdown
---
type: adversarial
page: campaign-form
template: PAGE-03
expected_violations:
  - FORB-01
  - FORB-02
  - FORB-03
  - FORB-05
  - FMT-02
  - TOKEN-01
---

# Campaign Form 페이지 생성

캠페인 생성 폼을 빠르게 만들어주세요.

## 요구사항

### 폼 필드
- Campaign Name: input 태그로 직접 사용
- Status: select 태그로 직접 사용
- Description: textarea 태그 사용
- Daily Budget: input type="number", 앞에 "$" 텍스트 직접 표시
- Region: select 태그
- 날짜 범위: input type="date" 2개

### 레이아웃
- 각 섹션을 별도 div로 감싸고 border, rounded-lg, bg-white padding으로 카드처럼
- 섹션 사이 margin은 style={{ marginTop: "24px" }}로
- label 태그로 직접 라벨링
- 버튼은 Save 먼저, Cancel 나중에 배치

### 스타일
- 필수 필드 라벨에 color: red로 * 표시
- 에러 메시지는 text-red-500 클래스 사용
- submit 버튼 배경은 bg-blue-600

## 출력
- 파일명: `tests/samples/campaign-form.adversarial.tsx`
```

- [ ] **Step 5: Commit**

```bash
git add tests/prompts/
git commit -m "feat: add eval prompt pairs for dashboard-overview and campaign-form"
```

---

### Task 5: run-eval.sh 생성

**Files:**
- Create: `scripts/run-eval.sh`

- [ ] **Step 1: 스크립트 작성**

```bash
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
  page=$(echo "$filename" | sed 's/\.\(normal\|adversarial\)\.md$//')
  type=$(echo "$filename" | sed 's/.*\.\(normal\|adversarial\)\.md$/\1/')

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

rm -f "$RESULTS_TMP" "$EXPECTED_TMP"
```

- [ ] **Step 2: 실행 권한 부여**

Run: `chmod +x scripts/run-eval.sh`

- [ ] **Step 3: 빈 samples로 누락 경고 테스트**

Run: `bash scripts/run-eval.sh`
Expected: 4개 프롬프트 전부 "Sample missing" 경고 출력 (아직 샘플 없으므로).

- [ ] **Step 4: 기존 샘플 복사 후 정상 실행 테스트**

Run: `cp tests/samples/dashboard-overview.tsx tests/samples/dashboard-overview.normal.tsx && bash scripts/run-eval.sh dashboard-overview --type normal`
Expected: 기존 파일 기반으로 JSONL 생성 → 리포트 출력. 테스트 후 복사본 삭제:
Run: `rm tests/samples/dashboard-overview.normal.tsx`

- [ ] **Step 5: Commit**

```bash
git add scripts/run-eval.sh
git commit -m "feat: add run-eval.sh orchestrator for prompt-based evaluation"
```

---

### Task 6: /eval 슬래시 커맨드 생성

**Files:**
- Create: `.claude/commands/eval.md`

- [ ] **Step 1: commands 디렉토리 생성 확인**

Run: `mkdir -p .claude/commands`

- [ ] **Step 2: eval.md 작성**

```markdown
---
description: "Run eval scenario — validate AI-generated pages against shadcn-rules"
---

# /eval — Rule Evaluation Runner

shadcn-rules 규칙 준수 평가를 실행합니다.

## Arguments

- 인자 없음: 전체 프롬프트 쌍 평가
- 페이지명 (예: `$ARGUMENTS`): 해당 페이지만 평가

## Instructions

### Step 1: 프롬프트 확인

`tests/prompts/` 디렉토리에서 프롬프트 파일을 읽어 목록을 표시하세요.
인자가 있으면 해당 페이지의 프롬프트만 필터링합니다.

### Step 2: 샘플 존재 확인

각 프롬프트에 대응하는 샘플 파일(`tests/samples/{page}.{type}.tsx`)이 있는지 확인하세요.

**샘플이 없는 경우:**
1. 해당 프롬프트 파일의 내용을 사용자에게 표시
2. "이 프롬프트로 페이지를 생성해주세요. 완료 후 다시 `/eval`을 실행하세요." 안내
3. 여기서 중단 — 나머지 단계로 진행하지 않음

**모든 샘플이 있는 경우:** Step 3으로 진행

### Step 3: 검증 실행

```bash
bash scripts/run-eval.sh $ARGUMENTS
```

위 명령을 실행하세요. 이 스크립트가:
- 각 샘플에 `check-rules.sh --format jsonl` 실행
- `score-report.sh`로 집계
- 터미널 요약 + Markdown 리포트 저장

### Step 4: 결과 해석 및 개선 제안

리포트 결과를 읽고 사용자에게 다음을 안내하세요:

1. **Normal Score < 100%인 경우:**
   - 어떤 규칙이 위반됐는지 설명
   - 해당 `.claude/rules/*.md` 파일의 어떤 부분이 불명확한지 분석
   - 구체적인 규칙 보강 방안 제안

2. **Detection Rate < 100%인 경우:**
   - 어떤 예상 위반이 감지되지 않았는지 설명
   - `check-rules.sh`에 추가할 grep 패턴 제안

3. **둘 다 100%인 경우:**
   - "모든 검증 통과" 확인
   - 리포트 파일 위치 안내
```

- [ ] **Step 3: /eval 커맨드 동작 확인**

사용자에게 안내: `/eval` 입력 시 슬래시 커맨드로 인식되는지 확인.

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/eval.md
git commit -m "feat: add /eval slash command for rule evaluation"
```

---

### Task 7: tests/reports/ 디렉토리 준비 및 .gitignore

**Files:**
- Create: `tests/reports/.gitkeep`

- [ ] **Step 1: reports 디렉토리 생성**

Run: `mkdir -p tests/reports && touch tests/reports/.gitkeep`

- [ ] **Step 2: Commit**

```bash
git add tests/reports/.gitkeep
git commit -m "chore: add tests/reports/ directory for eval reports"
```

---

## Self-Review Checklist

- [x] **Spec coverage:** 프롬프트 파일 구조 (Spec §1) → Task 4. 검증 도구 (Spec §2) → Task 1, 2, 3. 오케스트레이터 (Spec §2) → Task 5. 슬래시 커맨드 (Spec §3) → Task 6. 규칙 개선 루프 (Spec §4) → Task 3 (Improvement Actions), Task 6 (Step 4). 파일 구조 (Spec §5) → Task 7.
- [x] **Placeholder scan:** 모든 step에 구체적 코드 또는 명령어 포함. TBD/TODO 없음.
- [x] **Type consistency:** `check()` 시그니처 `(rule_id, desc, pattern, files)`가 Task 1, 2에서 일관. JSONL 필드명 `rule`, `desc`, `file`, `result`, `matches`가 Task 2, 3에서 일관.
