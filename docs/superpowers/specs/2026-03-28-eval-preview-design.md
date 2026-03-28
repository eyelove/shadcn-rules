# Eval + Preview 통합 설계

## 목적

shadcn-rules eval 시스템을 확장하여:
1. AI가 **preview 앱 환경 셋업(shadcn 컴포넌트 설치, Composed 생성, lib 유틸리티 작성)까지 규칙대로 수행하는지** 검증
2. 생성된 페이지를 **브라우저에서 실제 shadcn CSS로 렌더링**하여 시각적 완성도 확인
3. **스냅샷 기반 이력 관리**로 반복 생성 결과를 보존하고 비교

---

## eval 실행 흐름

```
[1] reset-preview.sh          ← preview 초기화 (컴포넌트/lib 삭제, 빈 셸)
[2] 셋업 프롬프트 실행          ← CSS/테마 설정만 (컴포넌트 설치 안함)
[3] 페이지 프롬프트 실행         ← AI가 컴포넌트 설치 + Composed 생성 + 페이지 작성
[4] tsc -b                    ← 빌드 검증
[5] check-rules.sh            ← 기존 grep + ENV 검증 (프롬프트별 기대 컴포넌트 점검)
[6] score-report.sh           ← report.md + report.json + meta.json 생성
[7] save-snapshot.sh          ← tests/snapshots/{날짜}-run{N}/에 저장
```

### Step 1: preview 초기화 (`scripts/reset-preview.sh`)

preview를 **기본 Vite + Tailwind 상태**로 리셋.

삭제 대상:
- `preview/src/components/`
- `preview/src/lib/`
- `preview/src/hooks/`
- `preview/src/pages/`
- `preview/src/App.css`

유지 대상:
- `preview/components.json` (shadcn 설정)
- `preview/package.json` (기본 의존성: react, tailwindcss, vite)
- `preview/vite.config.ts`
- `preview/tsconfig.app.json`
- `preview/node_modules/` (pnpm install 시간 절약)

App.tsx를 빈 셸로 복원:
```bash
cp scripts/templates/App.shell.tsx preview/src/App.tsx
```

### Step 2: 셋업 프롬프트 (`tests/prompts/setup.md`)

CSS/테마 설정만 수행. **컴포넌트 설치 없음.**
- Tailwind CSS 설정 확인
- shadcn 초기 구성 (`npx shadcn init` 수준)
- CSS 토큰/테마 변수 설정 (`tokens/globals.css` 참조)

### Step 3: 페이지 프롬프트 실행

기존 `tests/prompts/{page}.{type}.md` 프롬프트를 실행.
AI가 스스로 판단하여:
- 필요한 shadcn 컴포넌트 설치 (`npx shadcn add card button ...`)
- Composed 컴포넌트 생성 (DataTable, KpiCard + barrel export)
- `@/lib/format` 유틸리티 생성
- 페이지 작성 + App.tsx 라우팅 연결

### Step 4: 빌드 검증

```bash
cd preview && pnpm tsc -b
```

빌드 결과를 `meta.json`에 `buildPass: true/false`로 기록.
빌드 실패 시에도 grep 검증은 계속 진행 (독립적 검증 축).

### Step 5-6: 검증 + 리포트

기존 check-rules.sh + score-report.sh 실행. ENV 검증 추가 (아래 참조).
출력을 스냅샷 디렉토리에 직접 생성.

### Step 7: 스냅샷 저장 (`scripts/save-snapshot.sh`)

아래 스냅샷 구조 섹션 참조.

---

## 스냅샷 구조

`tests/reports/`와 `tests/samples/`를 **`tests/snapshots/`로 통합**.

```
tests/
  snapshots/
    2026-03-28-run1/
      samples/
        src/components/composed/   ← AI가 생성한 Composed 컴포넌트만
        src/lib/                   ← AI가 생성한 유틸리티
        src/pages/                 ← AI가 생성한 페이지 파일들
        src/App.tsx                ← AI가 수정한 라우팅
      report.md                    ← 마크다운 리포트
      report.json                  ← 구조화된 검증 결과 (JSONL)
      meta.json                    ← 실행 메타데이터
    2026-03-28-run2/
      ...
  prompts/                         ← 기존 유지 (프롬프트는 공유 자산)
```

### 저장 대상

AI가 직접 작성한 코드만:
- `src/components/composed/` (DataTable, KpiCard, barrel export)
- `src/lib/` (format.ts 등)
- `src/pages/` (생성된 페이지)
- `src/App.tsx` (라우팅)

### 제외 대상

- `src/components/ui/` (shadcn 원본 — 수정 불가 규칙이므로 매번 동일)
- `node_modules/`
- 설정 파일 (`vite.config.ts`, `tsconfig.app.json`, `components.json`)

### Run 번호 결정

`save-snapshot.sh`는 같은 날짜에 기존 run이 있으면 N을 증가:
```bash
DATE=$(date +%Y-%m-%d)
N=1
while [ -d "tests/snapshots/${DATE}-run${N}" ]; do
  N=$((N + 1))
done
SNAP_DIR="tests/snapshots/${DATE}-run${N}"
```

### meta.json 형식

```json
{
  "id": "2026-03-28-run1",
  "date": "2026-03-28",
  "run": 1,
  "prompts": ["dashboard-overview.normal", "dashboard-overview.adversarial", "campaign-form.normal"],
  "scores": {
    "dashboard-overview.normal": { "pass": 32, "fail": 0, "score": 100 },
    "dashboard-overview.adversarial": { "pass": 22, "fail": 10, "score": 68 },
    "campaign-form.normal": { "pass": 32, "fail": 0, "score": 100 }
  },
  "detectionRate": 100,
  "buildPass": true
}
```

---

## check-rules.sh 확장: ENV 검증

기존 32개 grep 검증에 환경 셋업 검증 5개 추가.

### ENV-01: 사용된 shadcn 컴포넌트 설치 확인

페이지 코드의 `import { Card } from "@/components/ui/card"` → `preview/src/components/ui/card.tsx` 파일 존재 확인.
프롬프트 프론트매터의 `expected_ui` 목록과 대조.

### ENV-02: Composed barrel export 구조

- `preview/src/components/composed/index.ts` 존재
- `expected_composed`에 선언된 컴포넌트가 export되는지 확인
- composed/ 안에 DataTable, KpiCard, SearchBar 외 파일이 없는지 (불필요한 Composed 생성 금지)

### ENV-03: @/lib/format 유틸리티 존재

- `preview/src/lib/format.ts` 존재
- `expected_lib`에 선언된 함수가 export되는지 확인

### ENV-04: shadcn 원본 미수정 확인

셋업 프롬프트 실행 직후 `src/components/ui/*.tsx`의 체크섬 저장.
페이지 생성 완료 후 체크섬 재비교. 변경 시 FAIL.

### ENV-05: 불필요한 Composed 컴포넌트 생성 금지

`composed/` 안에 DataTable, KpiCard, SearchBar, index.ts 외 파일 존재 시 FAIL.

---

## 프롬프트 프론트매터 확장

### 페이지별 기대 컴포넌트 매핑

| 페이지 | 템플릿 | expected_ui | expected_composed | expected_lib |
|--------|--------|-------------|-------------------|--------------|
| dashboard-overview | PAGE-04 | card, button, badge, select, chart | DataTable, KpiCard | formatCurrencyCompact, formatCompact, formatDelta |
| campaign-list | PAGE-01 | card, button, badge, input, select, dropdown-menu, checkbox | DataTable | formatNumber, formatCurrency, formatPercent |
| campaign-detail | PAGE-02 | card, button, badge, chart, select | DataTable, KpiCard | formatCurrencyCompact, formatCompact, formatDelta, formatCurrency |
| campaign-form | PAGE-03 | card, button, input, textarea, select, field | (없음) | (없음) |

### 프론트매터 형식

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

adversarial 프롬프트도 동일한 `expected_ui/composed/lib`를 갖되, `expected_violations`에 의도적 위반 규칙을 나열.

---

## preview 비교 UI

### 두 가지 비교 모드

**Normal vs Adversarial:**
- 스냅샷 1개 선택 + 페이지 선택 (예: `dashboard-overview`)
- 좌: `.normal.tsx` 렌더링 / 우: `.adversarial.tsx` 렌더링
- 같은 프롬프트의 "규칙 준수 vs 위반"을 시각적으로 비교

**Run vs Run:**
- 스냅샷 2개 선택 + 페이지 선택 (예: `dashboard-overview.normal`)
- 좌: run1의 결과 / 우: run2의 결과
- 규칙 개선 후 재생성 결과를 비교하여 개선 이력 확인

### UI 레이아웃

```
┌─────────────────────────────────────────────────────┐
│  shadcn-rules Preview                               │
│  ┌─────────────────────────────────────────────────┐│
│  │ Mode: [Normal vs Adversarial ▼]                 ││
│  │ Snapshot: [2026-03-28-run1 ▼]                   ││
│  │ Page: [dashboard-overview ▼]                    ││
│  ├────────────────────┬────────────────────────────┤│
│  │                    │                            ││
│  │  normal.tsx        │  adversarial.tsx           ││
│  │  렌더링 결과        │  렌더링 결과               ││
│  │                    │                            ││
│  ├────────────────────┼────────────────────────────┤│
│  │ Score: 100%        │ Score: 68%                 ││
│  │ Build: PASS        │ Build: PASS                ││
│  └────────────────────┴────────────────────────────┘│
└─────────────────────────────────────────────────────┘
```

Run vs Run 모드에서는 드롭다운이 Left/Right 스냅샷 2개 선택으로 변경.

### 스냅샷 로드 방식

- preview 앱이 `tests/snapshots/` 디렉토리를 Vite glob import로 스캔
- 선택된 스냅샷의 `meta.json`에서 점수 읽기 (JSON fetch)
- 선택된 스냅샷의 `samples/src/pages/*.tsx`를 동적 import로 렌더링
- shadcn 컴포넌트(`src/components/ui/`)는 preview에 현재 설치된 것을 공유
- Composed 컴포넌트, lib 유틸리티는 **스냅샷 내부의 것을 사용** — Vite alias를 스냅샷 선택 시 동적으로 해석하거나, 스냅샷 로드 스크립트가 preview의 `src/components/composed/`, `src/lib/`에 심볼릭 링크를 걸어 전환. 구현 시 가장 단순한 방식을 선택.

---

## 변경 파일 목록

### 신규 생성

| 파일 | 역할 |
|------|------|
| `scripts/reset-preview.sh` | preview 초기화 |
| `scripts/save-snapshot.sh` | 스냅샷 저장 |
| `scripts/templates/App.shell.tsx` | 초기화용 빈 App 셸 |
| `tests/prompts/setup.md` | 셋업 프롬프트 (CSS/테마만) |
| `preview/src/App.tsx` | 스냅샷 비교 뷰어 (새로 작성) |

### 수정

| 파일 | 변경 내용 |
|------|----------|
| `scripts/run-eval.sh` | 전체 흐름 변경 (초기화→셋업→생성→빌드→검증→스냅샷) |
| `scripts/check-rules.sh` | ENV-01~05 검증 추가, 프롬프트 프론트매터 파싱 |
| `scripts/score-report.sh` | report.json 출력 추가, 스냅샷 디렉토리에 저장 |
| `tests/prompts/dashboard-overview.normal.md` | expected_ui, expected_composed, expected_lib 추가 |
| `tests/prompts/dashboard-overview.adversarial.md` | expected_ui, expected_composed, expected_lib 추가 |
| `tests/prompts/campaign-form.normal.md` | expected_ui, expected_composed, expected_lib 추가 |
| `tests/prompts/campaign-form.adversarial.md` | expected_ui, expected_composed, expected_lib 추가 |
| `preview/vite.config.ts` | 스냅샷 디렉토리 접근 허용 |
| `docs/refinement-loop.md` | 스냅샷 기반 흐름으로 업데이트 |

### 삭제

| 파일 | 이유 |
|------|------|
| `tests/reports/` | 스냅샷으로 통합 |
| `tests/samples/` | 스냅샷으로 통합 (기존 8개 파일) |

### 변경 없음

| 파일 | 이유 |
|------|------|
| `.claude/rules/*.md` | eval 대상이지 변경 대상이 아님 |
| `CLAUDE.md` | 규칙 허브 — 변경 불필요 |

---

## 설계 원칙

1. **공식 스킬/플러그인 미사용** — eval은 `.claude/rules/*.md` 규칙 파일만으로 AI가 올바르게 코드를 생성하는지 검증. 외부 스킬이 개입하면 측정 대상이 오염됨.
2. **매 실행 자동 스냅샷** — eval 실행마다 결과를 자동 보존하여 개선 이력 추적.
3. **shadcn 원본 불변** — `src/components/ui/`는 설치 후 수정 금지. 체크섬으로 검증.
4. **프롬프트가 검증 기준을 선언** — `expected_ui/composed/lib` 프론트매터로 페이지별 기대 컴포넌트를 명시. 프롬프트 추가 시 검증 기준도 함께 정의.
