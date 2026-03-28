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

## The Cycle

```
[1] Reset — bash scripts/reset-preview.sh
    │
    ▼
[2] Generate — 서브에이전트가 규칙만 보고 페이지 생성
    │
    ▼
[3] Verify — tsc + check-rules.sh + score-report.sh
    │
    ▼
[4] Snapshot — save-snapshot.sh
    │
    ▼
[5] Diagnose — 위반 원인 분류
    │
    ▼
[6] Fix — 규칙 파일 수정
    │
    ▼
Back to [1]
```

## Step 1: Reset

```bash
bash scripts/reset-preview.sh
```
- AI 생성물 삭제, `npx shadcn init`, 커스텀 토큰 주입, shadcn 컴포넌트 설치
- 매 사이클마다 동일한 baseline에서 시작

## Step 2: Generate

서브에이전트에게 전달:
1. `.claude/rules/` 9개 규칙 파일 경로
2. `tests/prompts/` 의 페이지 프롬프트
3. 작업 디렉토리: `preview/`

**핵심**: 서브에이전트는 fresh context — 규칙 파일만으로 올바르게 생성하는지 검증하는 것이 목적.

## Step 3: Verify

```bash
bash scripts/run-eval.sh --check-only
```
- `tsc -b` 빌드 검증
- `check-rules.sh` grep + ENV 검증
- `score-report.sh` 리포트 생성

## Step 4: Snapshot

```bash
bash scripts/save-snapshot.sh
```
- `tests/snapshots/{date}-run{N}/` 에 생성물 + 리포트 저장

## Step 5: Diagnose

위반을 발견하면 **원인을 먼저 분류**한다:

| 원인 | 증상 | 조치 |
|------|------|------|
| **규칙 간 모순** | 두 파일이 반대로 말함 | 한쪽을 정리, 다른쪽에 cross-reference |
| **예제 코드 오류** | 규칙 텍스트와 예제가 불일치 | 예제를 규칙에 맞춰 수정 |
| **3계층 미분류** | 기본값인데 FORBIDDEN으로 써있음 | DEFAULT로 재분류 |
| **규칙 누락** | AI가 규칙에 없는 패턴을 만듦 | 규칙/예제 추가 |
| **규칙 모호** | AI가 잘못 해석 | 규칙 문구 강화 또는 예제 추가 |
| **컴포넌트 미커버** | 규칙에 없는 컴포넌트 사용 | 사용 빈도에 따라 규칙 추가 결정 |

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

---

## When to Add a New Rule

ALL of these are true:
1. **2회 이상 관찰**: 같은 위반이 2개 이상 샘플에서 발생
2. **기존 규칙 미커버**: 어떤 규칙 ID도 이 패턴을 명시하지 않음
3. **grep 검증 가능**: 코드를 읽어서 판별 가능
4. **계층 결정**: 절대/기본값/커스텀 중 어디에 해당하는지 명확

**추가하지 않는 경우:**
- 1회성 AI 오류 (재현 불가)
- 기존 규칙이 커버하지만 AI가 무시한 경우 (규칙 위치/강조 조정)
- 규칙이 정의되지 않은 컴포넌트의 사용법 (온라인 레퍼런스 참조로 충분)

## When to Add Component Rules

컴포넌트별 규칙 추가 기준:

| 상태 | 조치 |
|------|------|
| shadcn 컴포넌트, 사용 빈도 낮음 | 규칙 불필요 — 온라인 레퍼런스 참조 |
| shadcn 컴포넌트, 사용 빈도 높음 + AI가 잘못 사용 | 조합 패턴 규칙 추가 |
| Composed 컴포넌트 | 사용 예시만 언급, 구체적 props/구현은 규정하지 않음 |

## When to Remove a Rule

ALL of these are true:
1. 3회 이상 평가에서 한 번도 위반 안 됨
2. 다른 규칙과 중복
3. check-rules.sh에서 false positive 발생

---

## Files Quick Reference

| File | Purpose |
|------|---------|
| CLAUDE.md | 규칙 허브 — 프로젝트 정의 + 3계층 + 규칙 import |
| .claude/rules/*.md | 도메인별 규칙 (9개 파일) |
| scripts/reset-preview.sh | preview 초기화 |
| scripts/run-eval.sh | eval 오케스트레이터 |
| scripts/check-rules.sh | grep + ENV 검증 |
| scripts/score-report.sh | 리포트 생성 |
| scripts/save-snapshot.sh | 스냅샷 저장 |
| scripts/open-viewer.sh | 비교 뷰어 전환 |
| tests/prompts/*.md | 페이지 생성 프롬프트 |
| tests/snapshots/{date}-run{N}/ | 스냅샷: 생성물 + 리포트 |
| docs/refinement-loop.md | 이 문서 |
