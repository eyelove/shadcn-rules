# Eval Scenario Design — 페이지 제작 프롬프트 + 검증 리포트

## 목적

1. **규칙 시스템 품질 측정** — shadcn-rules 규칙 파일이 AI에게 얼마나 잘 전달되는지 수치화
2. **규칙 개선 루프** — 위반 발생 시 어떤 규칙이 불명확한지 피드백 → 규칙 파일 개선

## 접근

프롬프트 쌍(정상 + adversarial) → AI 수동 생성 → 자동 검증 → 스코어링 리포트 → 개선 액션

---

## 1. 프롬프트 파일 구조

### 위치 및 네이밍

```
tests/prompts/
  dashboard-overview.normal.md
  dashboard-overview.adversarial.md
  campaign-form.normal.md
  campaign-form.adversarial.md
```

### Normal 프롬프트 (`.normal.md`)

AI에게 규칙을 준수하며 페이지를 생성하라는 지시문.

```markdown
---
type: normal
page: dashboard-overview
template: PAGE-04
expected_violations: 0
---

# Dashboard Overview 페이지 생성

아래 요구사항에 맞는 대시보드 개요 페이지를 작성하세요.

## 요구사항
- KPI 4개: Total Spend, Impressions, Clicks, CTR
- 차트 2개: Daily Spend (LineChart), Channel Split (BarChart)
- 최근 캠페인 테이블: 5컬럼 (ID, Name, Status, Spend, CTR)
- 로케일: en-US, 통화: USD

## 규칙 참조
프로젝트의 .claude/rules/ 디렉토리에 있는 규칙을 모두 준수하세요.
```

### Adversarial 프롬프트 (`.adversarial.md`)

규칙을 모르는 초보자처럼 자연스러운 위반 코드를 유도.

```markdown
---
type: adversarial
page: dashboard-overview
template: PAGE-04
expected_violations:
  - FORB-01
  - FORB-02
  - FORB-03
  - FORB-05
  - FMT-01
  - FMT-02
---

# Dashboard Overview 페이지 생성

대시보드 개요 페이지를 작성하세요.

## 요구사항
- KPI 4개: Total Spend, Impressions, Clicks, CTR
- 차트 2개: Daily Spend (LineChart), Channel Split (BarChart)
- 최근 캠페인 테이블: 5컬럼
- 로케일: en-US

## 스타일 지침
- 차트 색상은 직접 hex로 지정해주세요 (#8884d8, #82ca9d 등)
- KPI 카드는 div로 자유롭게 레이아웃하세요
- 숫자 포매팅은 toLocaleString()으로 처리하세요
- 필요한 곳에 style={{}}로 미세 조정하세요
```

**핵심:** adversarial 프롬프트의 frontmatter에 `expected_violations`를 명시하여, 리포트에서 검증 도구의 감지율(Detection Rate)도 측정.

---

## 2. 검증 도구

### `check-rules.sh` 개선

기존 33개 체크와 터미널 출력은 유지. `--format jsonl` 플래그 추가.

```bash
# 기존 (사람용)
bash scripts/check-rules.sh tests/samples/dashboard-overview.normal.tsx

# NEW: 기계 파싱용
bash scripts/check-rules.sh --format jsonl tests/samples/dashboard-overview.normal.tsx
```

JSONL 출력:
```jsonl
{"rule":"FORB-01","desc":"No inline style={{}}","file":"dashboard-overview.normal.tsx","result":"PASS"}
{"rule":"FORB-02","desc":"No hardcoded hex colors","file":"dashboard-overview.normal.tsx","result":"FAIL","matches":["line 42: stroke=\"#8884d8\""]}
```

**변경 범위:**
- 기존 `check()` / `check_absent()` 함수에 `$FORMAT` 변수 분기 추가. 기존 동작 변경 없음.
- 각 `check()` 호출에 rule ID 파라미터 추가 (예: `check "FORB-01" "No inline style={{}}" 'style={{' "$TARGET"`). 현재 스크립트에는 rule ID가 없으므로 33개 체크 모두에 ID를 부여해야 함.

### `score-report.sh` (NEW)

JSONL 출력을 받아 집계.

**입력:** JSONL 결과 (파이프 또는 파일)
**출력:** 터미널 요약 + `tests/reports/YYYY-MM-DD-report.md`

#### 터미널 출력:
```
══════════════════════════════════════════
 Score Report — 2026-03-27
══════════════════════════════════════════

 Page                          PASS  FAIL  Score
 ─────────────────────────────────────────
 dashboard-overview.normal      30     0   100%
 dashboard-overview.adversarial 24     6    80%
 campaign-form.normal           30     0   100%
 campaign-form.adversarial      22     8    73%

 Rule Violation Heatmap:
 ─────────────────────────────────────────
 FORB-02 (hardcoded colors)     ████████  6
 FORB-01 (inline styles)        ██████    4
 FMT-01  (inline formatting)    ████      3
 FORB-03 (div as card)          ██        1

 Detection Rate (adversarial):
 ─────────────────────────────────────────
 Expected: 10  Detected: 10  Missed: 0
 Rate: 100%
```

#### Markdown 리포트 (`tests/reports/YYYY-MM-DD-report.md`):

터미널과 동일 + 추가:
- 각 FAIL의 파일명:줄번호 상세 목록
- adversarial `expected_violations` 대비 감지 비교표
- Improvement Actions 섹션

### `run-eval.sh` (NEW)

오케스트레이터. 프롬프트 수집 → 샘플 확인 → 검증 → 리포트.

```bash
bash scripts/run-eval.sh                    # 전체
bash scripts/run-eval.sh dashboard-overview # 특정 페이지
bash scripts/run-eval.sh --type adversarial # 특정 타입만
```

플로우:
1. `tests/prompts/*.md`에서 프롬프트 수집
2. `tests/samples/{page}.{type}.tsx` 존재 확인 (없으면 경고 + 스킵)
3. 각 샘플에 `check-rules.sh --format jsonl` 실행
4. 결과를 `score-report.sh`에 전달
5. 개선 포인트 출력

---

## 3. 슬래시 커맨드 (`/eval`)

### 스킬 정의

Claude Code 슬래시 커맨드로 등록. 전체 워크플로우를 하나의 커맨드로 실행.

```
/eval                        — 전체 평가 (모든 프롬프트 쌍)
/eval dashboard-overview     — 특정 페이지만
/eval --type adversarial     — adversarial만
```

### 스킬 동작 플로우

```
/eval 실행
  │
  ├─ 1. 프롬프트 목록 표시
  │     "다음 프롬프트에 대해 평가를 실행합니다:"
  │     - dashboard-overview (normal + adversarial)
  │     - campaign-form (normal + adversarial)
  │
  ├─ 2. 샘플 존재 확인
  │     tests/samples/{page}.{type}.tsx 확인
  │     ├─ 있음 → 3단계로
  │     └─ 없음 → 프롬프트 내용을 표시하고 생성 안내
  │           "아래 프롬프트로 페이지를 생성하세요:"
  │           (프롬프트 내용 출력)
  │           "생성 후 다시 /eval을 실행하세요."
  │
  ├─ 3. check-rules.sh --format jsonl 실행
  │     각 샘플 파일에 대해 자동 실행
  │
  ├─ 4. score-report.sh 실행
  │     터미널 요약 출력 + Markdown 리포트 저장
  │
  └─ 5. 개선 액션 제안
        Normal Score < 100% → "rules/{file}.md 보강 필요"
        Detection Rate < 100% → "check-rules.sh 패턴 추가 필요"
```

### 스킬 파일 위치

```
.claude/commands/eval.md     — 슬래시 커맨드 정의
```

---

## 4. 규칙 개선 루프

### 리포트 Improvement Actions 섹션

```markdown
## Improvement Actions

### 검증 도구 개선 (Detection Rate < 100%)
| 미검출 규칙 | 현재 상태 | 제안 |
|------------|----------|------|
| FORB-03 | grep 패턴 없음 | check-rules.sh에 div+border+bg 패턴 추가 |

### 규칙 문서 개선 (Normal Score < 100%)
| 위반 규칙 | 위반 파일 | 제안 |
|----------|----------|------|
| FORB-01 | dashboard-overview.normal.tsx:42 | forbidden.md FORB-01 예제 보강 |
```

### 개선 사이클

```
프롬프트 작성 → AI 페이지 생성 (수동) → /eval 실행
  ↓
리포트 확인
  ↓
┌─ Normal 위반? → .claude/rules/*.md 보강
└─ 미검출 위반? → check-rules.sh 패턴 추가
  ↓
다음 사이클 (재생성 → /eval)
```

---

## 5. 파일 구조 전체 맵

```
scripts/
  check-rules.sh          ← 기존 + --format jsonl 추가
  score-report.sh         ← NEW: JSONL 집계 → 터미널 + Markdown
  run-eval.sh             ← NEW: 오케스트레이터
  evaluate.md             ← 기존 (수동 체크리스트, 유지)

tests/
  prompts/
    dashboard-overview.normal.md
    dashboard-overview.adversarial.md
    campaign-form.normal.md
    campaign-form.adversarial.md
  samples/
    dashboard-overview.normal.tsx
    dashboard-overview.adversarial.tsx
    campaign-form.normal.tsx
    campaign-form.adversarial.tsx
    campaign-list.tsx               ← 기존 (유지)
    campaign-detail.tsx             ← 기존 (유지)
    campaign-form.tsx               ← 기존 (유지)
    dashboard-overview.tsx          ← 기존 (유지)
  reports/
    YYYY-MM-DD-report.md

.claude/
  commands/
    eval.md                ← /eval 슬래시 커맨드
```

## 6. 범위 밖

- List / Detail 페이지 프롬프트 (추후 확장)
- CI/CD 파이프라인 연동
- API 기반 자동 생성
- 수동 체크리스트(evaluate.md) 자동화
