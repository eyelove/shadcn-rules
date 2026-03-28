# Rule Refinement Loop

규칙 시스템을 반복적으로 개선하는 프로세스.

## 핵심 원칙

이 프로젝트의 규칙은 3계층으로 나뉜다:

| 계층 | 설명 | 수정 방향 |
|------|------|-----------|
| **절대 규칙** | 위반 불가 (inline style 금지, 하드코딩 색상 금지, Card 구조) | FORBIDDEN으로 유지, 예외 없음 |
| **기본값** | 특별한 지시 없으면 이대로 생성 (spacing, 섹션 순서, 버튼 배치) | DEFAULT로 표기, 사용자 지시 시 변경 가능 |
| **커스텀 허용** | 사용자 지시 시 토큰 시스템 안에서 변경 (색상 팔레트, locale) | 가이드라인만 제공 |

규칙을 추가/수정할 때 반드시 **어느 계층인지** 명시한다. "FORBIDDEN"이면 절대 규칙, "DEFAULT"이면 기본값.

## 평가 방식: A/B 테스트

동일 프롬프트로 **규칙 적용(A)**과 **규칙 미적용(B)**을 비교하여 규칙의 효과를 측정한다.

```
[1] Reset — bash scripts/reset-preview.sh
    │
    ▼
[2] Generate (A/B) — 동일 프롬프트, 두 서브에이전트
    │  ├─ Arm A: 규칙 9개 파일 + 프롬프트 → {page}.with_rules.tsx
    │  └─ Arm B: 프롬프트만 (규칙 없음) → {page}.without_rules.tsx
    │
    ▼
[3] Verify — tsc + check-rules.sh (양쪽 모두) + score-report.sh
    │
    ▼
[4] Snapshot — save-snapshot.sh
    │
    ▼
[5] Diagnose — A/B 비교 분석
    │
    ▼
[6] Fix — 규칙 파일 수정
    │
    ▼
Back to [1]
```

### A/B 결과 해석

| Verdict | Condition | 의미 |
|---------|-----------|------|
| **EFFECTIVE** | delta ≥ 20% | 규칙이 명확히 효과적 |
| **MARGINAL** | delta 5-19% | 규칙 효과 있으나 미미 — 규칙 보강 검토 |
| **NO DIFF** | delta < 5% | 규칙 효과 없음 — 프롬프트가 단순하거나 규칙 불명확 |
| **NEGATIVE** | delta < 0 | 규칙이 오히려 해침 — 규칙 재검토 |

## Step 1: Reset

```bash
bash scripts/reset-preview.sh
```
- AI 생성물 삭제, `npx shadcn init`, 커스텀 토큰 주입, shadcn 컴포넌트 설치
- 매 사이클마다 동일한 baseline에서 시작

## Step 2: Generate (A/B)

`/eval` 커맨드가 각 프롬프트에 대해 두 서브에이전트를 디스패치:
1. **Arm A (with_rules)**: `.claude/rules/` 9개 규칙 + 프롬프트
2. **Arm B (without_rules)**: 프롬프트만 (규칙 파일 없음)

**핵심**: 두 서브에이전트 모두 fresh context — 유일한 차이는 규칙 파일 제공 여부.

## Step 3: Verify

```bash
bash scripts/run-eval.sh --check-only
```
- 양쪽 모두 `check-rules.sh` grep + ENV 검증
- `tsc -b` 빌드 검증
- `score-report.sh` A/B 비교 리포트 생성

## Step 4: Snapshot

`run-eval.sh`가 자동으로 `tests/snapshots/{date}-run{N}/`에 저장:
- `meta.json` — A/B 점수, delta, 빌드 결과
- `report.json` — raw JSONL
- `report.md` — 마크다운 리포트

## Step 5: Diagnose

### A/B 비교 기반 진단

| 상황 | 원인 | 조치 |
|------|------|------|
| A 100%, B 낮음 (EFFECTIVE) | 규칙이 잘 동작 | 유지 |
| A에 failure 있음 | 규칙이 불명확하거나 모순 | 규칙 보강 |
| A, B 점수 비슷 (NO DIFF) | 프롬프트가 단순하거나, AI가 규칙 없이도 올바르게 생성 | 더 복잡한 프롬프트 추가 또는 규칙 차별화 강화 |
| A가 B보다 낮음 (NEGATIVE) | 규칙이 AI를 혼란시킴 | 규칙 단순화 또는 재작성 |

### 진단 체크리스트

규칙을 수정하기 전에 아래를 순서대로 확인:

1. **Cross-file 모순 검사**: 같은 패턴이 다른 파일에서 다르게 설명되어 있나?
2. **예제 코드 검증**: 예제가 실제 shadcn API와 맞나? (Select, FieldLabel 등)
3. **3계층 정합성**: CLAUDE.md의 계층 정의와 각 규칙 파일의 표현이 일치하나?
4. **format 함수 locale**: 모든 format 호출에 locale이 명시되어 있나? (FMT-03)
5. **Card 구조**: 모든 Card 예제에 CardHeader가 있나?
6. **DataTable 컬럼**: `cell:` 키를 사용하나? (`render:` 아님)

## Step 6: Fix

### 수정 원칙

1. **한 번에 하나의 원인**만 수정. 여러 원인을 섞지 않는다.
2. **수정 후 cross-file 검증**: 같은 패턴이 등장하는 모든 파일에서 일관성 확인.
3. **계층 표기**: 규칙 추가/수정 시 절대/기본값/커스텀 중 하나를 명시.

### 기본값 규칙 작성법

```
// 규칙 텍스트에:
**기본값** (특별한 지시 없으면):
- 설명

// 코드 예제에:
// DEFAULT — 이 패턴 설명

// FORBIDDEN 주석 블록에:
// DEFAULT (기본값 -- 사용자 지시 시 변경 가능):
// - 설명
```

### 절대 규칙 작성법

```
NEVER / MUST 사용
// FORBIDDEN — 설명
// CORRECT — 설명
// WHY: 이유
```

### 새 규칙에 check-rules.sh 검사 추가하기

규칙 ID 체계: rules/*.md의 ID를 check-rules.sh에서 그대로 사용한다.

```bash
# 예시: FORB-07을 추가하는 경우
# 1. forbidden.md에 FORB-07 정의
# 2. check-rules.sh에 추가:
check "FORB-07" "설명" 'grep패턴' "$TARGET"
```

의미 기반 ID 예시:
- `FORB-01` ~ `FORB-06`: forbidden.md의 절대 금지 패턴
- `FMT-01` ~ `FMT-03`: formatting.md의 포맷 규칙
- `TOKEN-01`: tokens.md의 토큰 규칙
- `FIELD-BTN-ORDER`, `FIELD-BARE-LABEL`, `FIELD-SUBMIT-LOC`: fields.md의 폼 구조 규칙
- `NAME-02`, `NAME-03`: naming.md의 명명 규칙
- `ENV-02` ~ `ENV-05`: 환경 검증 (Composed/lib 파일 존재 여부)

---

## When to Add a New Rule

ALL of these are true:
1. **2회 이상 관찰**: 같은 위반이 2개 이상 A/B 테스트의 B arm에서 발생
2. **기존 규칙 미커버**: 어떤 규칙 ID도 이 패턴을 명시하지 않음
3. **grep 검증 가능**: 코드를 읽어서 판별 가능
4. **계층 결정**: 절대/기본값/커스텀 중 어디에 해당하는지 명확

**추가하지 않는 경우:**
- 1회성 AI 오류 (재현 불가)
- 기존 규칙이 커버하지만 AI가 무시한 경우 (규칙 위치/강조 조정)
- 규칙이 정의되지 않은 컴포넌트의 사용법 (온라인 레퍼런스 참조로 충분)

## When to Add a New Prompt

| 상황 | 조치 |
|------|------|
| 새 페이지 템플릿 추가 (PAGE-05 등) | 해당 템플릿의 프롬프트 추가 |
| 기존 프롬프트가 NO DIFF | 더 복잡한 요구사항으로 프롬프트 보강 |
| 특정 규칙의 효과를 검증하고 싶음 | 해당 규칙이 활성화되는 시나리오의 프롬프트 추가 |

## When to Remove a Rule

ALL of these are true:
1. 3회 이상 A/B 테스트에서 A/B 차이에 기여하지 않음
2. 다른 규칙과 중복
3. check-rules.sh에서 false positive 발생

---

## Files Quick Reference

| File | Purpose |
|------|---------|
| CLAUDE.md | 규칙 허브 — 프로젝트 정의 + 3계층 + 규칙 import |
| .claude/rules/*.md | 도메인별 규칙 (9개 파일) |
| .claude/commands/eval.md | /eval 커맨드 — A/B 테스트 오케스트레이션 |
| scripts/reset-preview.sh | preview 초기화 |
| scripts/run-eval.sh | eval 오케스트레이터 (A/B) |
| scripts/check-rules.sh | grep + ENV 검증 |
| scripts/score-report.sh | A/B 비교 리포트 생성 |
| scripts/save-snapshot.sh | 스냅샷 저장 |
| scripts/evaluate.md | 수동 체크리스트 (grep이 못 잡는 구조적 검증) |
| scripts/open-viewer.sh | 비교 뷰어 전환 |
| tests/prompts/*.md | 페이지 생성 프롬프트 (A/B 공용) |
| tests/snapshots/{date}-run{N}/ | 스냅샷: 생성물 + A/B 리포트 |
