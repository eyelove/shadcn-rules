# Eval + Preview 통합 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** eval 실행 시 preview 환경을 초기화하고, AI가 shadcn 컴포넌트 설치부터 페이지 생성까지 수행한 결과를 스냅샷으로 보존하며, 브라우저에서 좌/우 비교할 수 있는 preview UI를 구축한다.

**Architecture:** shell 스크립트로 eval 파이프라인을 오케스트레이션 (reset → build check → grep check → snapshot save). preview 앱은 Vite glob import로 스냅샷의 tsx 파일을 동적 로드하여 렌더링. 스냅샷마다 meta.json으로 점수를 관리.

**Tech Stack:** Bash (eval 파이프라인), React + Vite + Tailwind (preview), shadcn/ui (컴포넌트)

---

## File Structure

```
scripts/
  reset-preview.sh              ← [신규] preview 초기화
  save-snapshot.sh              ← [신규] 스냅샷 저장
  templates/
    App.shell.tsx               ← [신규] 초기화용 빈 App 셸
  run-eval.sh                   ← [수정] 전체 흐름 변경
  check-rules.sh                ← [수정] ENV 검증 추가
  score-report.sh               ← [수정] JSON 출력 + 스냅샷 저장

tests/
  prompts/
    setup.md                    ← [신규] 셋업 프롬프트
    dashboard-overview.normal.md    ← [수정] expected_ui/composed/lib 추가
    dashboard-overview.adversarial.md ← [수정] expected_ui/composed/lib 추가
    campaign-form.normal.md         ← [수정] expected_ui/composed/lib 추가
    campaign-form.adversarial.md    ← [수정] expected_ui/composed/lib 추가
  snapshots/                    ← [신규] 스냅샷 보존 디렉토리

preview/
  src/
    App.tsx                     ← [수정] 스냅샷 비교 뷰어
  vite.config.ts                ← [수정] 스냅샷 디렉토리 접근 허용

docs/
  refinement-loop.md            ← [수정] 스냅샷 기반 흐름으로 업데이트
```

---

### Task 1: App.shell.tsx 템플릿 + reset-preview.sh

**Files:**
- Create: `scripts/templates/App.shell.tsx`
- Create: `scripts/reset-preview.sh`

- [ ] **Step 1: App.shell.tsx 작성**

```tsx
// scripts/templates/App.shell.tsx
// Empty shell — replaced by AI during eval page generation step.
// Do not edit manually. This file is copied by reset-preview.sh.

export default function App() {
  return (
    <div className="flex h-screen items-center justify-center text-sm text-muted-foreground">
      No pages generated yet. Run eval to generate pages.
    </div>
  )
}
```

- [ ] **Step 2: reset-preview.sh 작성**

```bash
#!/bin/bash
# Reset preview to clean Vite + Tailwind state.
# Removes AI-generated files, restores App.shell.tsx.
# Usage: bash scripts/reset-preview.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREVIEW_DIR="${SCRIPT_DIR}/../preview"

echo "Resetting preview..."

# Remove AI-generated directories
rm -rf "${PREVIEW_DIR}/src/components"
rm -rf "${PREVIEW_DIR}/src/lib"
rm -rf "${PREVIEW_DIR}/src/hooks"
rm -rf "${PREVIEW_DIR}/src/pages"

# Remove old App.css (Vite default)
rm -f "${PREVIEW_DIR}/src/App.css"

# Restore empty shell App
cp "${SCRIPT_DIR}/templates/App.shell.tsx" "${PREVIEW_DIR}/src/App.tsx"

# Reset index.css to Tailwind-only
cat > "${PREVIEW_DIR}/src/index.css" << 'CSSEOF'
@import "tailwindcss";
CSSEOF

echo "  ✓ preview reset to clean state"
```

- [ ] **Step 3: 실행 권한 부여 + 동작 확인**

Run: `chmod +x scripts/reset-preview.sh && bash scripts/reset-preview.sh`
Expected: "✓ preview reset to clean state", preview/src/components 및 preview/src/lib 삭제됨, App.tsx가 빈 셸로 교체됨.

- [ ] **Step 4: 커밋**

```bash
git add scripts/templates/App.shell.tsx scripts/reset-preview.sh
git commit -m "feat: add reset-preview.sh and App.shell.tsx template"
```

---

### Task 2: save-snapshot.sh

**Files:**
- Create: `scripts/save-snapshot.sh`

- [ ] **Step 1: save-snapshot.sh 작성**

```bash
#!/bin/bash
# Save current preview state as a snapshot.
# Copies AI-generated files (composed, lib, pages, App.tsx) into an existing snapshot dir.
# Usage: bash scripts/save-snapshot.sh <snapshot-dir>
#
# Arguments:
#   $1 — snapshot directory (must already exist, created by run-eval.sh)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREVIEW_DIR="${SCRIPT_DIR}/../preview"
SNAP_DIR="${1:?Usage: save-snapshot.sh <snapshot-dir>}"

echo "Saving snapshot to ${SNAP_DIR}..."

mkdir -p "${SNAP_DIR}/samples/src"

# Copy AI-generated files only (not shadcn ui components)
if [ -d "${PREVIEW_DIR}/src/components/composed" ]; then
  mkdir -p "${SNAP_DIR}/samples/src/components"
  cp -r "${PREVIEW_DIR}/src/components/composed" "${SNAP_DIR}/samples/src/components/"
fi

if [ -d "${PREVIEW_DIR}/src/lib" ]; then
  cp -r "${PREVIEW_DIR}/src/lib" "${SNAP_DIR}/samples/src/"
fi

if [ -d "${PREVIEW_DIR}/src/pages" ]; then
  cp -r "${PREVIEW_DIR}/src/pages" "${SNAP_DIR}/samples/src/"
fi

if [ -f "${PREVIEW_DIR}/src/App.tsx" ]; then
  cp "${PREVIEW_DIR}/src/App.tsx" "${SNAP_DIR}/samples/src/"
fi

echo "  ✓ Snapshot saved"
```

- [ ] **Step 2: 실행 권한 부여**

Run: `chmod +x scripts/save-snapshot.sh`

- [ ] **Step 3: 커밋**

```bash
git add scripts/save-snapshot.sh
git commit -m "feat: add save-snapshot.sh for eval result preservation"
```

---

### Task 3: 프롬프트 프론트매터 확장

**Files:**
- Create: `tests/prompts/setup.md`
- Modify: `tests/prompts/dashboard-overview.normal.md`
- Modify: `tests/prompts/dashboard-overview.adversarial.md`
- Modify: `tests/prompts/campaign-form.normal.md`
- Modify: `tests/prompts/campaign-form.adversarial.md`

- [ ] **Step 1: setup.md 작성**

```markdown
---
type: setup
---

# Preview 환경 셋업

preview/ 디렉토리에 shadcn/ui 프로젝트의 기본 CSS/테마를 설정하세요.
**컴포넌트는 설치하지 마세요.** 컴포넌트는 페이지 생성 시 필요에 따라 설치합니다.

## 작업 항목

### 1. index.css에 Tailwind + 토큰 설정
- `@import "tailwindcss";` 유지
- `tokens/globals.css`의 CSS 커스텀 프로퍼티를 `preview/src/index.css`에 추가
- `:root`와 `.dark` 모두 포함

### 2. shadcn 초기 구성 확인
- `preview/components.json` 이 존재하고 올바른 설정인지 확인
- aliases가 `@/components`, `@/lib` 등으로 설정되어 있는지 확인

### 3. 변경하지 말 것
- `package.json` — 기본 의존성 외 추가 설치 금지
- `vite.config.ts` — 수정 금지
- `tsconfig.app.json` — 수정 금지
- 어떤 shadcn 컴포넌트도 설치 금지 (`npx shadcn add` 실행 금지)
```

- [ ] **Step 2: dashboard-overview.normal.md 프론트매터 확장**

기존 프론트매터 교체:
```yaml
---
type: normal
page: dashboard-overview
template: PAGE-04
expected_violations: 0
expected_ui:
  - card
  - button
  - badge
  - select
  - chart
expected_composed:
  - DataTable
  - KpiCard
expected_lib:
  - formatCurrencyCompact
  - formatCompact
  - formatDelta
---
```

본문의 `## 출력` 섹션 교체:
```markdown
## 출력
- 파일 위치: `preview/src/pages/dashboard-overview.normal.tsx`
- 필요한 shadcn 컴포넌트를 직접 설치하세요 (`npx shadcn add ...`)
- Composed 컴포넌트(DataTable, KpiCard)가 없으면 `preview/src/components/composed/`에 생성하세요
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
```

- [ ] **Step 3: dashboard-overview.adversarial.md 프론트매터 확장**

기존 프론트매터 교체:
```yaml
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
expected_ui:
  - card
  - button
  - badge
  - select
  - chart
expected_composed:
  - DataTable
  - KpiCard
expected_lib:
  - formatCurrencyCompact
  - formatCompact
  - formatDelta
---
```

본문의 `## 출력` 섹션 교체:
```markdown
## 출력
- 파일 위치: `preview/src/pages/dashboard-overview.adversarial.tsx`
```

- [ ] **Step 4: campaign-form.normal.md 프론트매터 확장**

기존 프론트매터 교체:
```yaml
---
type: normal
page: campaign-form
template: PAGE-03
expected_violations: 0
expected_ui:
  - card
  - button
  - input
  - textarea
  - select
  - field
expected_composed: []
expected_lib: []
---
```

본문의 `## 출력` 섹션 교체:
```markdown
## 출력
- 파일 위치: `preview/src/pages/campaign-form.normal.tsx`
- 필요한 shadcn 컴포넌트를 직접 설치하세요 (`npx shadcn add ...`)
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
```

- [ ] **Step 5: campaign-form.adversarial.md 프론트매터 확장**

기존 프론트매터 교체:
```yaml
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
expected_ui:
  - card
  - button
  - input
  - textarea
  - select
  - field
expected_composed: []
expected_lib: []
---
```

본문의 `## 출력` 섹션 교체:
```markdown
## 출력
- 파일 위치: `preview/src/pages/campaign-form.adversarial.tsx`
```

- [ ] **Step 6: 커밋**

```bash
git add tests/prompts/
git commit -m "feat: add setup prompt and extend frontmatter with expected components"
```

---

### Task 4: check-rules.sh에 ENV 검증 추가

**Files:**
- Modify: `scripts/check-rules.sh`

- [ ] **Step 1: ENV 검증용 함수 추가**

`check_absent` 함수 뒤(라인 85 이후)에 새 함수 추가:

```bash
check_file_exists() {
  local rule_id="$1"
  local desc="$2"
  local filepath="$3"
  CHECKS=$((CHECKS + 1))

  if [ -f "$filepath" ]; then
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${filepath}\",\"result\":\"PASS\"}"
    else
      echo -e "${GREEN}PASS${NC} [${rule_id}] $desc"
    fi
    PASSED=$((PASSED + 1))
  else
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${filepath}\",\"result\":\"FAIL\"}"
    else
      echo -e "${RED}FAIL${NC} [${rule_id}] $desc (file not found: ${filepath})"
    fi
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
}

check_export_exists() {
  local rule_id="$1"
  local desc="$2"
  local pattern="$3"
  local filepath="$4"
  CHECKS=$((CHECKS + 1))

  if [ -f "$filepath" ] && grep -q "$pattern" "$filepath" 2>/dev/null; then
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${filepath}\",\"result\":\"PASS\"}"
    else
      echo -e "${GREEN}PASS${NC} [${rule_id}] $desc"
    fi
    PASSED=$((PASSED + 1))
  else
    if [ "$FORMAT" = "jsonl" ]; then
      echo "{\"rule\":\"${rule_id}\",\"desc\":\"${desc}\",\"file\":\"${filepath}\",\"result\":\"FAIL\"}"
    else
      echo -e "${RED}FAIL${NC} [${rule_id}] $desc"
    fi
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
}
```

- [ ] **Step 2: ENV 검증 섹션 추가**

스크립트 끝(PAGE TEMPLATE STRUCTURE 섹션 이후, 최종 결과 출력 전)에 추가:

```bash
# --- ENVIRONMENT CHECKS ---
# These checks require --prompt and --preview-dir arguments.
# When called from run-eval.sh, these are passed automatically.
# When called standalone, ENV checks are skipped.

PROMPT_FILE=""
PREVIEW_DIR=""

# Parse additional args (add to existing arg parsing at top of script)
# --prompt <file> --preview-dir <dir>

if [ -n "$PROMPT_FILE" ] && [ -n "$PREVIEW_DIR" ]; then
  if [ "$FORMAT" != "jsonl" ]; then
    echo ""
    echo "--- ENVIRONMENT CHECKS ---"
  fi

  # ENV-01: expected_ui components are installed
  in_expected_ui=0
  while IFS= read -r line; do
    if echo "$line" | grep -q "^expected_ui:"; then
      in_expected_ui=1
      continue
    fi
    if [ "$in_expected_ui" = "1" ]; then
      if echo "$line" | grep -q "^  - "; then
        comp=$(echo "$line" | sed 's/^  - //')
        check_file_exists "ENV-01" "shadcn component installed: ${comp}" "${PREVIEW_DIR}/src/components/ui/${comp}.tsx"
      else
        in_expected_ui=0
      fi
    fi
  done < "$PROMPT_FILE"

  # ENV-02: expected_composed components exist + barrel export
  in_expected_composed=0
  has_composed=0
  while IFS= read -r line; do
    if echo "$line" | grep -q "^expected_composed:"; then
      in_expected_composed=1
      continue
    fi
    if [ "$in_expected_composed" = "1" ]; then
      if echo "$line" | grep -q "^  - "; then
        comp=$(echo "$line" | sed 's/^  - //')
        has_composed=1
        check_file_exists "ENV-02" "Composed component exists: ${comp}" "${PREVIEW_DIR}/src/components/composed/${comp}.tsx"
        check_export_exists "ENV-02" "Composed barrel exports: ${comp}" "export.*${comp}" "${PREVIEW_DIR}/src/components/composed/index.ts"
      elif echo "$line" | grep -q "^\[\]"; then
        in_expected_composed=0
      else
        in_expected_composed=0
      fi
    fi
  done < "$PROMPT_FILE"

  if [ "$has_composed" = "1" ]; then
    check_file_exists "ENV-02" "Composed barrel index.ts exists" "${PREVIEW_DIR}/src/components/composed/index.ts"
  fi

  # ENV-03: expected_lib functions exist
  in_expected_lib=0
  has_lib=0
  while IFS= read -r line; do
    if echo "$line" | grep -q "^expected_lib:"; then
      in_expected_lib=1
      continue
    fi
    if [ "$in_expected_lib" = "1" ]; then
      if echo "$line" | grep -q "^  - "; then
        func=$(echo "$line" | sed 's/^  - //')
        has_lib=1
        check_export_exists "ENV-03" "Format function exists: ${func}" "function ${func}\|export.*${func}" "${PREVIEW_DIR}/src/lib/format.ts"
      elif echo "$line" | grep -q "^\[\]"; then
        in_expected_lib=0
      else
        in_expected_lib=0
      fi
    fi
  done < "$PROMPT_FILE"

  if [ "$has_lib" = "1" ]; then
    check_file_exists "ENV-03" "@/lib/format.ts exists" "${PREVIEW_DIR}/src/lib/format.ts"
  fi

  # ENV-04: shadcn originals not modified (checksum)
  if [ -f "${PREVIEW_DIR}/.ui-checksums" ]; then
    CURRENT_SUM=$(find "${PREVIEW_DIR}/src/components/ui" -name "*.tsx" -exec shasum {} \; 2>/dev/null | sort | shasum | awk '{print $1}')
    SAVED_SUM=$(cat "${PREVIEW_DIR}/.ui-checksums")
    CHECKS=$((CHECKS + 1))
    if [ "$CURRENT_SUM" = "$SAVED_SUM" ]; then
      if [ "$FORMAT" = "jsonl" ]; then
        echo "{\"rule\":\"ENV-04\",\"desc\":\"shadcn originals not modified\",\"file\":\"${PREVIEW_DIR}/src/components/ui\",\"result\":\"PASS\"}"
      else
        echo -e "${GREEN}PASS${NC} [ENV-04] shadcn originals not modified"
      fi
      PASSED=$((PASSED + 1))
    else
      if [ "$FORMAT" = "jsonl" ]; then
        echo "{\"rule\":\"ENV-04\",\"desc\":\"shadcn originals not modified\",\"file\":\"${PREVIEW_DIR}/src/components/ui\",\"result\":\"FAIL\"}"
      else
        echo -e "${RED}FAIL${NC} [ENV-04] shadcn originals were modified"
      fi
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi

  # ENV-05: no extra Composed components
  if [ -d "${PREVIEW_DIR}/src/components/composed" ]; then
    EXTRA=$(find "${PREVIEW_DIR}/src/components/composed" -name "*.tsx" -o -name "*.ts" | while read -r f; do
      bname=$(basename "$f")
      case "$bname" in
        DataTable.tsx|KpiCard.tsx|SearchBar.tsx|index.ts) ;;
        *) echo "$bname" ;;
      esac
    done)
    CHECKS=$((CHECKS + 1))
    if [ -z "$EXTRA" ]; then
      if [ "$FORMAT" = "jsonl" ]; then
        echo "{\"rule\":\"ENV-05\",\"desc\":\"No extra Composed components\",\"file\":\"${PREVIEW_DIR}/src/components/composed\",\"result\":\"PASS\"}"
      else
        echo -e "${GREEN}PASS${NC} [ENV-05] No extra Composed components"
      fi
      PASSED=$((PASSED + 1))
    else
      if [ "$FORMAT" = "jsonl" ]; then
        echo "{\"rule\":\"ENV-05\",\"desc\":\"No extra Composed components\",\"file\":\"${PREVIEW_DIR}/src/components/composed\",\"result\":\"FAIL\",\"matches\":[\"${EXTRA}\"]}"
      else
        echo -e "${RED}FAIL${NC} [ENV-05] Extra Composed components found: ${EXTRA}"
      fi
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  fi
fi
```

- [ ] **Step 3: 기존 인자 파싱을 확장하여 --prompt, --preview-dir 지원**

스크립트 상단의 인자 파싱 루프를 교체:

```bash
FORMAT="text"
ARGS=()
PROMPT_FILE=""
PREVIEW_DIR=""

for arg in "$@"; do
  case "$arg" in
    --format)
      FORMAT="__next__"
      ;;
    --prompt)
      PROMPT_FILE="__next__"
      ;;
    --preview-dir)
      PREVIEW_DIR="__next__"
      ;;
    *)
      if [ "$FORMAT" = "__next__" ]; then
        FORMAT="$arg"
      elif [ "$PROMPT_FILE" = "__next__" ]; then
        PROMPT_FILE="$arg"
      elif [ "$PREVIEW_DIR" = "__next__" ]; then
        PREVIEW_DIR="$arg"
      else
        ARGS+=("$arg")
      fi
      ;;
  esac
done
TARGET="${ARGS[0]:-tests/samples}"
```

- [ ] **Step 4: 동작 확인**

Run: `bash scripts/check-rules.sh --format jsonl --prompt tests/prompts/dashboard-overview.normal.md --preview-dir preview tests/samples/dashboard-overview.normal.tsx 2>&1 | grep ENV`
Expected: ENV-01~05 관련 JSONL 라인 출력 (현재 preview에 컴포넌트 미설치이므로 FAIL)

- [ ] **Step 5: 커밋**

```bash
git add scripts/check-rules.sh
git commit -m "feat: add ENV-01~05 environment checks to check-rules.sh"
```

---

### Task 5: score-report.sh에 JSON 출력 + meta.json 생성 추가

**Files:**
- Modify: `scripts/score-report.sh`

- [ ] **Step 1: report.json 출력 추가**

score-report.sh의 인자에 `--output-dir` 옵션 추가. 기존 `REPORT_DIR`/`REPORT_FILE` 로직을 교체:

스크립트 상단 인자 파싱 뒤에 추가:
```bash
OUTPUT_DIR="${3:-}"
BUILD_PASS="${4:-true}"

if [ -n "$OUTPUT_DIR" ]; then
  REPORT_DIR="$OUTPUT_DIR"
  REPORT_FILE="${OUTPUT_DIR}/report.md"
else
  REPORT_DIR="tests/reports"
  REPORT_FILE="${REPORT_DIR}/${TODAY}-report.md"
fi
```

- [ ] **Step 2: meta.json 생성 로직 추가**

마크다운 리포트 생성 블록(`> "$REPORT_FILE"`) 뒤에 추가:

```bash
# Generate meta.json
if [ -n "$OUTPUT_DIR" ]; then
  SNAP_ID=$(basename "$OUTPUT_DIR")
  SNAP_DATE=$(echo "$SNAP_ID" | sed 's/-run[0-9]*$//')
  SNAP_RUN=$(echo "$SNAP_ID" | grep -o '[0-9]*$')

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
  "run": ${SNAP_RUN:-1},
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
```

- [ ] **Step 3: 커밋**

```bash
git add scripts/score-report.sh
git commit -m "feat: add JSON output and meta.json generation to score-report.sh"
```

---

### Task 6: run-eval.sh 전체 흐름 변경

**Files:**
- Modify: `scripts/run-eval.sh`

- [ ] **Step 1: run-eval.sh 전체 재작성**

```bash
#!/bin/bash
# Eval orchestrator for shadcn-rules (v2 — snapshot-based)
# Full flow: reset → setup → generate → build → check → report → snapshot
#
# Usage:
#   bash scripts/run-eval.sh                     # all prompts
#   bash scripts/run-eval.sh dashboard-overview  # specific page
#   bash scripts/run-eval.sh --type adversarial  # specific type only
#   bash scripts/run-eval.sh --check-only        # skip reset/generate, run checks on current preview

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
REPORT_MD_TMP=$(mktemp)

trap 'rm -f "$RESULTS_TMP" "$EXPECTED_TMP" "$REPORT_MD_TMP"' EXIT

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

# ── Step 3: Check for page files in preview/src/pages/ ──
echo "── Checking generated pages ──"
MISSING=0
EVALUATED=0

for prompt_file in $PROMPTS; do
  filename=$(basename "$prompt_file")
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

  # Save checksum of shadcn ui components (for ENV-04)
  if [ -d "${PREVIEW_DIR}/src/components/ui" ] && [ ! -f "${PREVIEW_DIR}/.ui-checksums" ]; then
    find "${PREVIEW_DIR}/src/components/ui" -name "*.tsx" -exec shasum {} \; 2>/dev/null | sort | shasum | awk '{print $1}' > "${PREVIEW_DIR}/.ui-checksums"
  fi

  # Run check-rules.sh with ENV checks
  bash "${SCRIPT_DIR}/check-rules.sh" --format jsonl \
    --prompt "$prompt_file" \
    --preview-dir "$PREVIEW_DIR" \
    "$page_file" >> "$RESULTS_TMP"
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
if cd "$PREVIEW_DIR" && npx tsc -b 2>&1; then
  echo "   ✓ Build passed"
else
  echo "   ✗ Build failed"
  BUILD_PASS=false
fi
cd "$ROOT_DIR"
echo ""

# ── Step 5: Generate report + snapshot ──
# Determine snapshot dir
N=1
while [ -d "${ROOT_DIR}/tests/snapshots/${DATE}-run${N}" ]; do
  N=$((N + 1))
done
SNAP_DIR="${ROOT_DIR}/tests/snapshots/${DATE}-run${N}"
mkdir -p "$SNAP_DIR"

echo ""
if [ -s "$EXPECTED_TMP" ]; then
  bash "${SCRIPT_DIR}/score-report.sh" "$RESULTS_TMP" "$EXPECTED_TMP" "$SNAP_DIR" "$BUILD_PASS"
else
  bash "${SCRIPT_DIR}/score-report.sh" "$RESULTS_TMP" "" "$SNAP_DIR" "$BUILD_PASS"
fi

# ── Step 6: Save snapshot ──
echo ""
echo "── Saving snapshot ──"
bash "${SCRIPT_DIR}/save-snapshot.sh" "$SNAP_DIR"

echo ""
echo "══════════════════════════════════════════"
echo " Snapshot saved to: ${SNAP_DIR}"
echo "══════════════════════════════════════════"
```

- [ ] **Step 2: 동작 확인 (--check-only 모드)**

Run: `bash scripts/run-eval.sh --check-only 2>&1 | head -20`
Expected: 기존 preview 상태를 리셋하지 않고 검증만 실행. 페이지 미생성 상태이므로 "Page missing" 메시지.

- [ ] **Step 3: 커밋**

```bash
git add scripts/run-eval.sh
git commit -m "feat: rewrite run-eval.sh with snapshot-based pipeline"
```

---

### Task 7: preview 비교 뷰어 (App.tsx)

**Files:**
- Modify: `preview/vite.config.ts`
- Create: `preview/src/App.tsx` (비교 뷰어 — eval 후 별도 실행)

> Note: 이 App.tsx는 **eval 실행 중에는 사용되지 않음**. eval에서 AI가 생성하는 App.tsx는 페이지 라우팅용. 비교 뷰어는 eval 완료 후 별도로 스냅샷을 확인할 때 사용. 실행 시 `PREVIEW_MODE=viewer pnpm dev`로 구분하거나, 별도 엔트리포인트를 사용.

- [ ] **Step 1: vite.config.ts에 스냅샷 디렉토리 접근 허용**

```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    fs: {
      allow: [path.resolve(__dirname, '..')]
    }
  }
})
```

- [ ] **Step 2: 비교 뷰어 App.tsx 작성**

`preview/src/App.viewer.tsx` 로 작성 (eval용 App.tsx와 분리):

```tsx
import { useState, useEffect, Suspense, lazy } from "react"
import type { ComponentType } from "react"

// Glob import all snapshot page files
const snapshotModules = import.meta.glob(
  "../../tests/snapshots/*/samples/src/pages/*.tsx"
) as Record<string, () => Promise<{ default: ComponentType }>>

// Glob import all meta.json files
const metaModules = import.meta.glob(
  "../../tests/snapshots/*/meta.json"
) as Record<string, () => Promise<Record<string, unknown>>>

interface SnapshotInfo {
  id: string
  meta: Record<string, unknown> | null
  pages: Record<string, () => Promise<{ default: ComponentType }>>
}

function parseSnapshots(): Map<string, SnapshotInfo> {
  const map = new Map<string, SnapshotInfo>()

  // Parse page modules
  for (const [path, loader] of Object.entries(snapshotModules)) {
    // path: ../../tests/snapshots/2026-03-28-run1/samples/src/pages/dashboard-overview.normal.tsx
    const match = path.match(/snapshots\/([^/]+)\/samples\/src\/pages\/(.+)\.tsx$/)
    if (!match) continue
    const [, snapId, pageName] = match

    if (!map.has(snapId)) {
      map.set(snapId, { id: snapId, meta: null, pages: {} })
    }
    map.get(snapId)!.pages[pageName] = loader
  }

  return map
}

function getPageGroups(snap: SnapshotInfo): string[] {
  const pages = Object.keys(snap.pages)
  const groups = new Set<string>()
  for (const p of pages) {
    // "dashboard-overview.normal" → "dashboard-overview"
    const group = p.replace(/\.(normal|adversarial)$/, "")
    groups.add(group)
  }
  return Array.from(groups).sort()
}

type CompareMode = "normal-vs-adversarial" | "run-vs-run"

function App() {
  const [snapshots, setSnapshots] = useState<Map<string, SnapshotInfo>>(new Map())
  const [mode, setMode] = useState<CompareMode>("normal-vs-adversarial")

  // Normal vs Adversarial state
  const [selectedSnap, setSelectedSnap] = useState("")
  const [selectedPage, setSelectedPage] = useState("")

  // Run vs Run state
  const [leftSnap, setLeftSnap] = useState("")
  const [rightSnap, setRightSnap] = useState("")
  const [runPage, setRunPage] = useState("")

  // Loaded components
  const [LeftComp, setLeftComp] = useState<ComponentType | null>(null)
  const [RightComp, setRightComp] = useState<ComponentType | null>(null)

  // Meta data
  const [leftMeta, setLeftMeta] = useState<Record<string, unknown> | null>(null)
  const [rightMeta, setRightMeta] = useState<Record<string, unknown> | null>(null)

  // Initialize snapshots
  useEffect(() => {
    const parsed = parseSnapshots()
    setSnapshots(parsed)
    const ids = Array.from(parsed.keys()).sort()
    if (ids.length > 0) {
      setSelectedSnap(ids[ids.length - 1])
      setLeftSnap(ids[ids.length - 1])
      if (ids.length > 1) setRightSnap(ids[ids.length - 2])
      else setRightSnap(ids[0])
    }

    // Load meta for all snapshots
    for (const [path, loader] of Object.entries(metaModules)) {
      const match = path.match(/snapshots\/([^/]+)\/meta\.json$/)
      if (!match) continue
      const snapId = match[1]
      loader().then((data) => {
        setSnapshots((prev) => {
          const next = new Map(prev)
          const info = next.get(snapId)
          if (info) info.meta = data as Record<string, unknown>
          return next
        })
      })
    }
  }, [])

  // Load components when selection changes
  useEffect(() => {
    if (mode === "normal-vs-adversarial") {
      const snap = snapshots.get(selectedSnap)
      if (!snap || !selectedPage) return

      const normalKey = `${selectedPage}.normal`
      const advKey = `${selectedPage}.adversarial`

      if (snap.pages[normalKey]) {
        const Lazy = lazy(snap.pages[normalKey])
        setLeftComp(() => Lazy)
      } else {
        setLeftComp(null)
      }

      if (snap.pages[advKey]) {
        const Lazy = lazy(snap.pages[advKey])
        setRightComp(() => Lazy)
      } else {
        setRightComp(null)
      }

      setLeftMeta(snap.meta)
      setRightMeta(snap.meta)
    } else {
      const lSnap = snapshots.get(leftSnap)
      const rSnap = snapshots.get(rightSnap)

      if (lSnap?.pages[runPage]) {
        const Lazy = lazy(lSnap.pages[runPage])
        setLeftComp(() => Lazy)
      } else {
        setLeftComp(null)
      }

      if (rSnap?.pages[runPage]) {
        const Lazy = lazy(rSnap.pages[runPage])
        setRightComp(() => Lazy)
      } else {
        setRightComp(null)
      }

      setLeftMeta(lSnap?.meta ?? null)
      setRightMeta(rSnap?.meta ?? null)
    }
  }, [mode, selectedSnap, selectedPage, leftSnap, rightSnap, runPage, snapshots])

  // Auto-select first page group
  useEffect(() => {
    const snap = snapshots.get(selectedSnap)
    if (snap && !selectedPage) {
      const groups = getPageGroups(snap)
      if (groups.length > 0) setSelectedPage(groups[0])
    }
  }, [selectedSnap, snapshots, selectedPage])

  const snapIds = Array.from(snapshots.keys()).sort()
  const currentSnap = snapshots.get(selectedSnap)
  const pageGroups = currentSnap ? getPageGroups(currentSnap) : []

  // All unique full page names across all snapshots (for run-vs-run)
  const allPageNames = Array.from(
    new Set(
      Array.from(snapshots.values()).flatMap((s) => Object.keys(s.pages))
    )
  ).sort()

  function getScore(meta: Record<string, unknown> | null, pageName: string): string {
    if (!meta || !meta.scores) return "—"
    const scores = meta.scores as Record<string, { score: number }>
    return scores[pageName] ? `${scores[pageName].score}%` : "—"
  }

  function getBuild(meta: Record<string, unknown> | null): string {
    if (!meta) return "—"
    return (meta as { buildPass?: boolean }).buildPass ? "PASS" : "FAIL"
  }

  const Loading = (
    <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
      Loading...
    </div>
  )

  return (
    <div className="flex flex-col h-screen bg-background text-foreground">
      {/* Header */}
      <header className="border-b border-border px-4 py-3 flex items-center gap-4 shrink-0">
        <h1 className="text-sm font-semibold">shadcn-rules Preview</h1>

        <select
          value={mode}
          onChange={(e) => setMode(e.target.value as CompareMode)}
          className="text-sm border border-border rounded px-2 py-1 bg-background"
        >
          <option value="normal-vs-adversarial">Normal vs Adversarial</option>
          <option value="run-vs-run">Run vs Run</option>
        </select>

        {mode === "normal-vs-adversarial" ? (
          <>
            <select
              value={selectedSnap}
              onChange={(e) => setSelectedSnap(e.target.value)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              {snapIds.map((id) => (
                <option key={id} value={id}>{id}</option>
              ))}
            </select>
            <select
              value={selectedPage}
              onChange={(e) => setSelectedPage(e.target.value)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              {pageGroups.map((pg) => (
                <option key={pg} value={pg}>{pg}</option>
              ))}
            </select>
          </>
        ) : (
          <>
            <span className="text-xs text-muted-foreground">Left:</span>
            <select
              value={leftSnap}
              onChange={(e) => setLeftSnap(e.target.value)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              {snapIds.map((id) => (
                <option key={id} value={id}>{id}</option>
              ))}
            </select>
            <span className="text-xs text-muted-foreground">Right:</span>
            <select
              value={rightSnap}
              onChange={(e) => setRightSnap(e.target.value)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              {snapIds.map((id) => (
                <option key={id} value={id}>{id}</option>
              ))}
            </select>
            <select
              value={runPage}
              onChange={(e) => setRunPage(e.target.value)}
              className="text-sm border border-border rounded px-2 py-1 bg-background"
            >
              {allPageNames.map((p) => (
                <option key={p} value={p}>{p}</option>
              ))}
            </select>
          </>
        )}
      </header>

      {/* Compare panels */}
      <div className="flex flex-1 overflow-hidden">
        {/* Left panel */}
        <div className="flex-1 flex flex-col border-r border-border overflow-hidden">
          <div className="px-3 py-2 border-b border-border bg-muted/30 text-xs text-muted-foreground">
            {mode === "normal-vs-adversarial"
              ? `${selectedPage}.normal`
              : `${leftSnap} / ${runPage}`}
          </div>
          <div className="flex-1 overflow-y-auto">
            <Suspense fallback={Loading}>
              {LeftComp ? <LeftComp /> : <div className="p-4 text-sm text-muted-foreground">No page found</div>}
            </Suspense>
          </div>
          <div className="px-3 py-2 border-t border-border bg-muted/30 text-xs flex gap-4">
            <span>Score: {getScore(
              leftMeta,
              mode === "normal-vs-adversarial" ? `${selectedPage}.normal` : runPage
            )}</span>
            <span>Build: {getBuild(leftMeta)}</span>
          </div>
        </div>

        {/* Right panel */}
        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="px-3 py-2 border-b border-border bg-muted/30 text-xs text-muted-foreground">
            {mode === "normal-vs-adversarial"
              ? `${selectedPage}.adversarial`
              : `${rightSnap} / ${runPage}`}
          </div>
          <div className="flex-1 overflow-y-auto">
            <Suspense fallback={Loading}>
              {RightComp ? <RightComp /> : <div className="p-4 text-sm text-muted-foreground">No page found</div>}
            </Suspense>
          </div>
          <div className="px-3 py-2 border-t border-border bg-muted/30 text-xs flex gap-4">
            <span>Score: {getScore(
              rightMeta,
              mode === "normal-vs-adversarial" ? `${selectedPage}.adversarial` : runPage
            )}</span>
            <span>Build: {getBuild(rightMeta)}</span>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
```

- [ ] **Step 3: 뷰어 전환 스크립트 작성**

`scripts/open-viewer.sh`:

```bash
#!/bin/bash
# Switch preview App.tsx to the comparison viewer and open browser.
# Usage: bash scripts/open-viewer.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREVIEW_DIR="${SCRIPT_DIR}/../preview"

cp "${PREVIEW_DIR}/src/App.viewer.tsx" "${PREVIEW_DIR}/src/App.tsx"
echo "Switched to viewer mode. Run 'cd preview && pnpm dev' to start."
```

- [ ] **Step 4: 커밋**

```bash
git add preview/vite.config.ts preview/src/App.viewer.tsx scripts/open-viewer.sh
git commit -m "feat: add snapshot comparison viewer for preview"
```

---

### Task 8: 기존 tests/samples + tests/reports 마이그레이션

**Files:**
- Delete: `tests/samples/` (기존 8개 파일)
- Delete: `tests/reports/` (기존 2개 리포트)
- Create: `tests/snapshots/.gitkeep`

- [ ] **Step 1: 기존 샘플을 레거시 스냅샷으로 마이그레이션**

```bash
mkdir -p tests/snapshots/legacy/samples
cp tests/samples/*.tsx tests/snapshots/legacy/samples/ 2>/dev/null || true
cp tests/reports/*.md tests/snapshots/legacy/ 2>/dev/null || true
```

- [ ] **Step 2: 기존 디렉토리 삭제**

```bash
rm -rf tests/samples tests/reports
```

- [ ] **Step 3: snapshots .gitkeep 추가**

```bash
touch tests/snapshots/.gitkeep
```

- [ ] **Step 4: 커밋**

```bash
git add tests/snapshots/ tests/samples tests/reports
git commit -m "refactor: migrate samples/reports to snapshots directory"
```

---

### Task 9: docs/refinement-loop.md 업데이트

**Files:**
- Modify: `docs/refinement-loop.md`

- [ ] **Step 1: refinement-loop.md 업데이트**

`## The Cycle` 섹션의 다이어그램을 교체:

```markdown
## The Cycle

```
Rules (CLAUDE.md + .claude/rules/*.md)
    │
    ▼
[1] Reset — bash scripts/reset-preview.sh (preview 초기화)
    │
    ▼
[2] Setup — AI가 CSS/테마 설정 (셋업 프롬프트)
    │
    ▼
[3] Generate — AI가 shadcn 설치 + Composed 생성 + 페이지 작성 (페이지 프롬프트)
    │
    ▼
[4] Build — tsc -b (빌드 검증)
    │
    ▼
[5] Check — check-rules.sh (grep + ENV 검증)
    │
    ▼
[6] Report — score-report.sh (report.md + meta.json)
    │
    ▼
[7] Snapshot — save-snapshot.sh (tests/snapshots/{날짜}-run{N}/)
    │
    ▼
[8] Review — preview 비교 뷰어에서 시각적 확인
    │
    ▼
[9] Diagnose — 위반 원인 분류 (규칙 모호? 규칙 누락? AI 오류?)
    │
    ▼
[10] Update — 규칙 파일 수정
    │
    ▼
Back to [1]
```
```

`## Files Quick Reference` 테이블 교체:

```markdown
## Files Quick Reference

| File | Purpose |
|------|---------|
| CLAUDE.md | Rule hub — imports all rule files |
| .claude/rules/*.md | Domain-scoped rule content |
| scripts/reset-preview.sh | Reset preview to clean state |
| scripts/run-eval.sh | Eval orchestrator (v2, snapshot-based) |
| scripts/check-rules.sh | Automated grep + ENV violation checker |
| scripts/score-report.sh | Terminal summary + markdown/JSON report |
| scripts/save-snapshot.sh | Save eval results as snapshot |
| scripts/open-viewer.sh | Switch preview to comparison viewer mode |
| tests/prompts/*.md | Prompt files (shared across runs) |
| tests/snapshots/{date}-run{N}/ | Snapshot: samples + report + meta |
| preview/src/App.viewer.tsx | Snapshot comparison viewer |
| docs/refinement-loop.md | This document |
```

- [ ] **Step 2: 커밋**

```bash
git add docs/refinement-loop.md
git commit -m "docs: update refinement-loop.md for snapshot-based eval flow"
```

---

### Task 10: 통합 테스트

- [ ] **Step 1: 전체 파이프라인 dry run**

```bash
# reset만 실행하여 preview가 초기화되는지 확인
bash scripts/reset-preview.sh
```

Expected: "✓ preview reset to clean state"

- [ ] **Step 2: run-eval.sh --check-only 실행**

```bash
bash scripts/run-eval.sh --check-only
```

Expected: 페이지가 없으므로 "Page missing" 메시지. 스냅샷은 생성되지 않음.

- [ ] **Step 3: 뷰어 전환 확인**

```bash
bash scripts/open-viewer.sh
```

Expected: "Switched to viewer mode" 메시지. preview/src/App.tsx가 App.viewer.tsx 내용으로 교체됨.

- [ ] **Step 4: 최종 커밋**

```bash
git add -A
git commit -m "chore: final integration test cleanup"
```
