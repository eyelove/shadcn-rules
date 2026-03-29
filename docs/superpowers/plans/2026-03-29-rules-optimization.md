# Rules Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 규칙 파일(94KB/2,494줄)을 토큰 효율적 구조로 리팩토링하여, 조건부 로딩 + 간결한 작성법 + Hook 강제를 통해 동일한 코드 품질을 ~30KB 이하로 달성한다.

**Architecture:** CLAUDE.md에서 `@` 참조를 제거하고 `paths:` 조건부 로딩에 의존. 규칙 파일은 "규칙 문장 + CORRECT/FORBIDDEN 한 쌍 + // WHY"로 압축. 기계적 검증은 `check-rules.sh`를 Hook으로 연결. 상세 예제는 gold/ 디렉토리에 보존.

**Tech Stack:** Claude Code rules system, bash hooks, check-rules.sh (기존)

---

## 현재 상태 (Before)

| 파일 | 줄 수 | 역할 |
|------|-------|------|
| CLAUDE.md | 107줄 | 9개 `@` 참조로 전체 인라인 |
| cards.md | 441줄 | Card 패턴 5가지 + 코드 예제 |
| fields.md | 488줄 | Field 패턴 9가지 + 코드 예제 |
| data-table.md | 356줄 | DataTable 전략 + 전체 컬럼 예제 |
| components.md | 266줄 | 2-tier 모델 + 선택 가이드 |
| page-templates.md | 259줄 | 4가지 페이지 스켈레톤 |
| formatting.md | 210줄 | 포맷 함수 + 로케일 규칙 |
| forbidden.md | 216줄 | 6가지 금지 패턴 |
| tokens.md | 166줄 | 토큰, 타이포, 스페이싱 |
| naming.md | 92줄 | 네이밍 컨벤션 |
| **합계** | **2,601줄** | **~94KB 매 세션 전체 로딩** |

## 목표 상태 (After)

| 파일 | 목표 줄 수 | 변경 |
|------|-----------|------|
| CLAUDE.md | ~60줄 | `@` 참조 제거, 핵심 원칙만 |
| 각 rules/ 파일 | 50~120줄 | 규칙+한쌍예제+WHY, 상세 제거 |
| gold/*.tsx | 4개 | eval 검증된 참조 파일 (on-demand) |
| Hook (settings.json) | 1개 | PostToolUse에서 check-rules.sh 연결 |
| **합계** | **~700줄** | **paths: 조건부 로딩, ~25KB** |

## 리팩토링 원칙

1. **"이걸 제거하면 Claude가 실수할까?" 테스트** — 아니면 삭제
2. **규칙 문장 + CORRECT/FORBIDDEN 한 쌍 + // WHY** — 이것이 기본 단위
3. **AI가 이미 아는 것은 규칙에 넣지 않는다** — React, Tailwind 기본은 제거
4. **기계적 검증은 Hook으로** — 텍스트 규칙 60~80% vs Hook 100%
5. **상세 예제는 gold/ 참조** — on-demand 읽기, 항상 로딩 X

---

## Task 1: Gold Standard 참조 파일 생성

**Files:**
- Create: `gold/campaign-list.tsx`
- Create: `gold/campaign-detail.tsx`
- Create: `gold/campaign-form.tsx`
- Create: `gold/campaign-dashboard.tsx`

최신 eval snapshot(run9)에서 arm_a(규칙 적용) 결과물 중 가장 높은 점수를 받은 파일을 gold/ 디렉토리에 복사한다. 이 파일들은 규칙 파일에서 "상세 코드는 gold/campaign-list.tsx 참조"로 가리키는 참조 파일이 된다.

- [ ] **Step 1: snapshot에서 arm_a 샘플 파일 확인**

```bash
ls tests/snapshots/2026-03-29-run9/samples/src/
cat tests/snapshots/2026-03-29-run9/report.json | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{k}: {v}') for k,v in d.items() if 'score' in str(v).lower() or 'arm_a' in str(k)]"
```

Expected: 4개 페이지의 arm_a 샘플 파일 목록과 점수

- [ ] **Step 2: gold/ 디렉토리 생성 및 복사**

```bash
mkdir -p gold
# 각 페이지의 arm_a 파일을 gold/로 복사
# 파일명은 정확한 경로를 Step 1에서 확인 후 결정
cp tests/snapshots/2026-03-29-run9/samples/src/campaign-list.with_rules.tsx gold/campaign-list.tsx
cp tests/snapshots/2026-03-29-run9/samples/src/campaign-detail.with_rules.tsx gold/campaign-detail.tsx
cp tests/snapshots/2026-03-29-run9/samples/src/campaign-form.with_rules.tsx gold/campaign-form.tsx
cp tests/snapshots/2026-03-29-run9/samples/src/campaign-dashboard.with_rules.tsx gold/campaign-dashboard.tsx
```

NOTE: 실제 파일명은 Step 1에서 확인한 경로에 따라 조정한다.

- [ ] **Step 3: gold/ 파일 상단에 주석 추가**

각 gold 파일 1줄째에 추가:
```tsx
// GOLD STANDARD — eval run9 arm_a 기준. 규칙 파일에서 참조용. 직접 수정하지 말 것.
```

- [ ] **Step 4: .gitignore에 gold/ 추가 여부 결정**

gold/는 git에 추적한다 (규칙과 함께 다른 프로젝트에 복사될 수 있어야 함).

```bash
# gold/가 .gitignore에 없는지 확인
grep "gold" .gitignore || echo "gold/ is not gitignored — correct"
```

- [ ] **Step 5: Commit**

```bash
git add gold/
git commit -m "chore: add gold standard reference files from eval run9 arm_a"
```

---

## Task 2: CLAUDE.md 리팩토링 — `@` 참조 제거

**Files:**
- Modify: `CLAUDE.md` (전체 재작성)

현재 107줄에서 `@` 참조 9개를 제거하고, 핵심 원칙만 ~60줄로 압축한다. 규칙 파일은 `paths:` frontmatter로 자동 로딩된다.

- [ ] **Step 1: 현재 CLAUDE.md 백업**

```bash
cp CLAUDE.md CLAUDE.md.bak
```

- [ ] **Step 2: CLAUDE.md 재작성**

```markdown
# shadcn-rules

AI가 shadcn/ui 기반 대시보드를 생성할 때 일관된 코드를 보장하는 규칙 시스템.

## 규칙의 3계층

| 계층 | 설명 |
|------|------|
| **절대 규칙** | 위반 불가 — inline style 금지, 하드코딩 색상 금지, Card 구조 |
| **기본값** | 특별한 지시 없으면 이대로 생성 — gap-4, chart-1~5, KPI→Chart→Table |
| **커스텀 허용** | 사용자 지시 시 토큰 시스템 안에서 변경 가능 |

## 컴포넌트 모델

2-tier:
- **shadcn tier**: `@/components/ui/*` 직접 사용
- **Composed tier**: `@/components/composed/*` — DataTable, SearchBar, KpiCard만

## 핵심 원칙 (Always Apply)

- shadcn 컴포넌트 원본(`@/components/ui/*`) 수정 금지
- 모든 대시보드 섹션은 Card로 감싼다. Card 중첩 금지
- 폼 Input은 반드시 Field > FieldLabel 안에 배치
- style={{}} 절대 금지 (Recharts contentStyle 포함)
- 색상/radius는 CSS token만 사용 — hex, rgb, Tailwind 프리미티브 금지
- 숫자/통화/퍼센트는 `@/lib/format` 유틸리티만 사용
- Composed 컴포넌트는 barrel import: `@/components/composed`

## 규칙 파일

`.claude/rules/` 디렉토리의 규칙이 paths 패턴에 따라 자동 로딩된다.
의심스러우면 규칙 파일을 읽어라 — 추론하지 말 것.

## Gold Standard

`gold/` 디렉토리에 eval 검증된 참조 파일이 있다.
상세 코드 패턴이 필요하면 해당 파일을 읽어라.

## Eval

`/eval`로 A/B 테스트. Arm A(규칙 적용) vs Arm B(규칙 없음).
`check-rules.sh`로 자동 검증, `preview/`에서 시각적 확인.
```

- [ ] **Step 3: 줄 수 확인**

```bash
wc -l CLAUDE.md
```

Expected: ~50줄 (60줄 미만)

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "refactor: CLAUDE.md에서 @참조 제거, paths: 조건부 로딩으로 전환"
```

---

## Task 3: forbidden.md 간결화

**Files:**
- Modify: `.claude/rules/forbidden.md`

현재 216줄 → 목표 ~70줄. 각 FORB 항목을 "규칙 문장 + CORRECT/FORBIDDEN 한 쌍 + // WHY"로 압축.

- [ ] **Step 1: forbidden.md 재작성**

```markdown
---
paths:
  - "src/**/*.tsx"
  - "src/**/*.css"
  - "app/**/*.tsx"
  - "app/**/*.css"
  - "components/**/*.tsx"
  - "components/**/*.css"
  - "resources/js/**/*.tsx"
  - "resources/css/**/*.css"
---

# Forbidden Patterns

6가지 절대 금지 패턴. 위반 시 Hook(check-rules.sh)이 자동 감지한다.

## FORB-01 — No Inline Styles

`style={{}}` 절대 금지. Recharts `contentStyle`, axis `stroke` 포함.

```tsx
// FORBIDDEN
<div style={{ marginTop: "24px" }}>
// CORRECT
<div className="mt-6">
```

// WHY: inline style은 토큰 시스템을 우회한다. chart 관련: cards.md CARD-02.

## FORB-02 — No Hardcoded Colors

hex, rgb(), oklch(), Tailwind 프리미티브(zinc-*, gray-*) 금지.

```tsx
// FORBIDDEN
<div className="bg-zinc-900 text-gray-100">
// CORRECT
<div className="bg-background text-foreground">
```

// WHY: 하드코딩 색상은 테마/다크모드를 깨뜨린다.

## FORB-03 — No div as Card Substitute

대시보드 섹션에 border+bg div 금지. Card 사용 필수.
레이아웃 div(flex, grid)는 허용.

```tsx
// FORBIDDEN
<div className="rounded-lg border bg-card p-4"><h3>Revenue</h3></div>
// CORRECT
<Card><CardHeader><CardTitle>Revenue</CardTitle></CardHeader><CardContent>...</CardContent></Card>
```

// WHY: Card만이 token 기반 surface(bg-card, border-border, rounded-[--radius])를 보장.

## FORB-04 — No Unnecessary Composed Wrappers

shadcn 컴포넌트를 단순 passthrough하는 wrapper 금지.

```tsx
// FORBIDDEN — 로직 없는 wrapper
export function ActionButton(props) { return <Button {...props} /> }
// CORRECT — shadcn 직접 사용
<Button onClick={handleCreate}>New Campaign</Button>
```

// WHY: thin wrapper는 indirection만 추가하고 shadcn 업데이트를 어렵게 만든다.

## FORB-05 — No Bare Input Outside Field

폼 컨텍스트에서 Input/Select/Textarea를 Field 없이 사용 금지.
예외: DataTable 위 검색/필터 toolbar의 Input.

```tsx
// FORBIDDEN
<Input placeholder="Campaign name" />
// CORRECT
<Field><FieldLabel>Campaign Name</FieldLabel><Input placeholder="Campaign name" /></Field>
```

// WHY: Field가 accessible label, validation state, error display를 제공.

## FORB-06 — No Card Double Wrapping

Card 안에 Card 중첩 금지. 서브그룹은 Separator 사용.

```tsx
// FORBIDDEN
<Card><CardContent><Card>...</Card></CardContent></Card>
// CORRECT
<Card><CardContent className="space-y-4"><div>A</div><Separator /><div>B</div></CardContent></Card>
```

// WHY: 이중 래핑은 padding/border가 중복되어 시각적 계층을 깨뜨린다.

## Escape Hatch

금지 패턴이 정말 필요하면: 1) 멈추고 2) 이유 설명 3) 승인 대기 4) `// EXCEPTION:` 주석.
```

- [ ] **Step 2: 줄 수 확인**

```bash
wc -l .claude/rules/forbidden.md
```

Expected: ~75줄 (현재 216줄에서 ~65% 감소)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/forbidden.md
git commit -m "refactor: forbidden.md 간결화 (216→~75줄, 규칙+한쌍예제+WHY)"
```

---

## Task 4: tokens.md 간결화

**Files:**
- Modify: `.claude/rules/tokens.md`

현재 166줄 → 목표 ~80줄. 스페이싱 역할별 고정값 테이블은 유지 (AI가 추론 불가). Tailwind 기본 지식은 제거.

- [ ] **Step 1: tokens.md 재작성**

```markdown
---
paths:
  - "src/**/*.tsx"
  - "src/**/*.css"
  - "app/**/*.tsx"
  - "app/**/*.css"
  - "components/**/*.tsx"
  - "components/**/*.css"
  - "resources/js/**/*.tsx"
  - "resources/css/**/*.css"
---

# Token Rules

모든 color, spacing, radius, shadow는 CSS custom property token 사용 필수.
hex, rgb, oklch, Tailwind 프리미티브(gray-100, zinc-800) 직접 사용 금지.

## Color Tokens

**Surfaces:** `bg-background` · `bg-card` · `bg-popover` · `bg-muted` · `bg-accent`
**Text:** `text-foreground` · `text-card-foreground` · `text-muted-foreground`
**Actions:** `bg-primary` · `bg-secondary` · `bg-destructive` · `border-border` · `ring-ring`
**Chart:** `var(--chart-1)` ~ `var(--chart-5)` — chartConfig에서 정의, `var(--color-KEY)`로 참조
**Dashboard 확장:** `var(--kpi-positive)` · `var(--kpi-negative)` · `var(--table-row-hover)`

## Radius

`rounded-[--radius]` · `rounded-[--radius-sm]` · `rounded-[--radius-lg]` 사용.
`rounded-md`, `rounded-lg` (Tailwind 고정값) 금지.

## Typography

본문 기본 `text-sm`(14px). 한국어 글리프 기준.

| 역할 | 클래스 |
|------|--------|
| 본문 | `text-sm font-normal` |
| 보조/캡션 | `text-xs font-normal` |
| CardTitle | `text-base font-semibold` |
| 페이지 제목 h1 | `text-xl font-semibold` |
| KPI 값 | `text-2xl font-semibold` |
| FieldLabel | `text-sm font-medium` |

## Spacing 고정값

대부분 수직 `gap-4`(16px), 인라인 `gap-2`(8px). 사용자 지시 없이 변경 금지.

| 역할 | 클래스 |
|------|--------|
| 페이지 루트 | `flex flex-col gap-4 p-4` |
| Card/섹션 grid | `gap-4` |
| CardContent 수직 | `space-y-4` |
| 필터↔DataTable | `pb-4` |
| 인라인 요소 | `gap-2` |
| 버튼 그룹 | `gap-2` |

## Chart Config

```tsx
const chartConfig = {
  desktop: { label: "Desktop", color: "var(--chart-1)" },
} satisfies ChartConfig
```

chart 요소에서 `stroke="var(--color-desktop)"`. 상세: cards.md CARD-02.

## Escape Hatch

token이 없으면: `scripts/templates/custom-tokens.css`에 먼저 추가 → `var(--token)`으로 참조.
인라인 리터럴 후 "나중에 추가" 금지.
```

- [ ] **Step 2: 줄 수 확인**

```bash
wc -l .claude/rules/tokens.md
```

Expected: ~75줄 (현재 166줄에서 ~55% 감소)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/tokens.md
git commit -m "refactor: tokens.md 간결화 (166→~75줄)"
```

---

## Task 5: cards.md 간결화

**Files:**
- Modify: `.claude/rules/cards.md`

현재 441줄 → 목표 ~120줄. 5가지 카드 패턴을 규칙+최소 예제로 압축. 전체 코드는 gold/ 참조.

- [ ] **Step 1: cards.md 재작성**

핵심 구조:
1. Principles (3줄)
2. CARD-01~05 각각: 구조 설명 1~3줄 + 핵심 코드 스니펫(5~10줄) + Rules 불릿
3. Forbidden 패턴은 forbidden.md 참조
4. 전체 코드 예제는 gold/ 참조

각 CARD 패턴의 압축 전략:

**CARD-01 KPI:** grid 클래스 + Card > CardHeader(CardDescription+CardTitle+CardAction) 구조만. 전체 예제 → gold/campaign-dashboard.tsx 참조.

**CARD-02 Chart:** ChartContainer + ChartTooltip + ChartLegend 조합 규칙만. 전체 예제 → gold/ 참조. Date Range Picker 상세 코드 삭제 (fields.md로 이관되어 있음).

**CARD-03 Table:** 4가지 서브패턴(a~d)을 테이블로 요약. 전체 예제 → gold/ 참조.

**CARD-04 Form:** form id linking + CardFooter 규칙만. 전체 예제 → gold/campaign-form.tsx 참조.

**CARD-05 Mixed:** space-y-4 + Separator 규칙만. 전체 예제 → gold/campaign-detail.tsx 참조.

작성 시 지켜야 할 것:
- 각 패턴의 **구조 규칙**(Card > CardHeader > CardContent 같은)은 반드시 유지
- **chartConfig 정의 방법**은 유지 (AI가 추론 불가)
- **CardAction에 Select/DateRange 배치** 규칙은 유지
- **ChartContainer에 min-h 필수** 규칙은 유지
- **axis/grid에 stroke 금지** 규칙은 유지

삭제해도 되는 것:
- Date Range Picker 전체 코드 블록 (~25줄)
- CARD-03a~d 전체 코드 블록 (테이블 요약으로 대체)
- Column Layout Reference 테이블 (page-templates.md에 있음)
- Forbidden Patterns 섹션 (forbidden.md에 있음)

- [ ] **Step 2: 줄 수 확인**

```bash
wc -l .claude/rules/cards.md
```

Expected: ~120줄 (현재 441줄에서 ~73% 감소)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/cards.md
git commit -m "refactor: cards.md 간결화 (441→~120줄, gold/ 참조)"
```

---

## Task 6: fields.md 간결화

**Files:**
- Modify: `.claude/rules/fields.md`

현재 488줄 → 목표 ~100줄. 9가지 FIELD 패턴을 규칙 요약으로 압축.

- [ ] **Step 1: fields.md 재작성**

압축 전략:
- **FIELD-01~03**: 구조 계층도(form > FieldGroup > FieldSet > Field) + 핵심 규칙만 유지. 코드 삭제.
- **FIELD-04 (react-hook-form)**: Controller + data-invalid + aria-invalid 패턴은 AI가 추론 불가 → 최소 코드 스니펫 유지 (10줄).
- **FIELD-05 (Checkbox/Switch)**: `orientation="horizontal"` + FieldContent 규칙 1줄.
- **FIELD-06 (Date Picker)**: Popover + Calendar + formatDate 조합 규칙 2줄. 전체 코드 → gold/.
- **FIELD-07 (Combobox)**: 언제 Select vs Combobox 선택 기준 + items/onValueChange 규칙 2줄.
- **FIELD-08 (RadioGroup)**: 2~5개 옵션, 상호 배타적 선택 → RadioGroup. 코드 삭제.
- **FIELD-09 (Choice Card)**: FieldLabel > Field(horizontal) > FieldContent + RadioGroupItem 구조 규칙 2줄. 코드 삭제.

유지해야 할 것:
- Field 컴포넌트 계층도 (form > FieldGroup > FieldSet > Field > FieldLabel)
- Common Imports 목록
- react-hook-form Controller 최소 예제
- CardFooter 버튼 규칙 (gap-2, variant 구분, form id linking)

삭제해도 되는 것:
- FIELD-01~03 전체 코드 블록 (계층도로 충분)
- FIELD-05~09 전체 코드 블록 (규칙 문장으로 충분)
- Forbidden Patterns 섹션 (forbidden.md에 있음)
- Exception 섹션 (cards.md CARD-03b에서 이미 명시)

- [ ] **Step 2: 줄 수 확인**

```bash
wc -l .claude/rules/fields.md
```

Expected: ~100줄 (현재 488줄에서 ~80% 감소)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/fields.md
git commit -m "refactor: fields.md 간결화 (488→~100줄, gold/ 참조)"
```

---

## Task 7: data-table.md 간결화

**Files:**
- Modify: `.claude/rules/data-table.md`

현재 356줄 → 목표 ~80줄. TABLE-05 전체 컬럼 예제(~100줄)를 gold/ 참조로 대체.

- [ ] **Step 1: data-table.md 재작성**

유지:
- TABLE-00 선택 플로우차트 (Data > 20 rows? → DataTable, 아니면 Table)
- TABLE-01 Props Interface (AI가 추론 불가)
- TABLE-02 컬럼 순서 테이블 (Checkbox→ID→Name→Attribute→Metric→Actions)
- TABLE-03 기능 테이블 (sorting, pagination, selection, header styling)

삭제:
- TABLE-05 전체 컬럼 예제 (~100줄) → `gold/campaign-list.tsx의 columns 정의 참조`
- TABLE-04 Card 조합 (cards.md CARD-03 참조로 충분)
- TABLE-06 Forbidden (forbidden.md에 있음)

- [ ] **Step 2: 줄 수 확인**

```bash
wc -l .claude/rules/data-table.md
```

Expected: ~80줄 (현재 356줄에서 ~78% 감소)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/data-table.md
git commit -m "refactor: data-table.md 간결화 (356→~80줄, gold/ 참조)"
```

---

## Task 8: components.md 간결화

**Files:**
- Modify: `.claude/rules/components.md`

현재 266줄 → 목표 ~80줄.

- [ ] **Step 1: components.md 재작성**

유지:
- 2-tier 모델 테이블 (shadcn vs Composed)
- Import Convention (shadcn 직접 import 목록 — AI가 정확한 import path 필요)
- Composed Qualification 기준 3가지 (내부 상태, 도메인 조합, 3회+ 반복)
- Composed Component List 테이블
- SELECT-01, DATE-01, RADIO-01 선택 기준 (AI가 추론 불가한 의사결정 트리)

삭제:
- Composed Qualification의 코드 예제 (IS/IS NOT — 규칙 문장으로 충분)
- Chart Library Usage 섹션 (cards.md CARD-02에 있음)
- Cell Functions in DataTable 섹션 (data-table.md에 있음)
- SearchBar Props Interface (별도로 존재하므로 중복)

- [ ] **Step 2: 줄 수 확인**

```bash
wc -l .claude/rules/components.md
```

Expected: ~80줄 (현재 266줄에서 ~70% 감소)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/components.md
git commit -m "refactor: components.md 간결화 (266→~80줄)"
```

---

## Task 9: page-templates.md 간결화

**Files:**
- Modify: `.claude/rules/page-templates.md`

현재 259줄 → 목표 ~70줄.

- [ ] **Step 1: page-templates.md 재작성**

유지:
- Page Structure Rules 테이블 (절대 규칙 + 기본값)
- 4가지 페이지 타입의 구조 규칙 (루트 래퍼, 헤더, 섹션 순서)
- Column Layout Reference 테이블
- FORBIDDEN/DEFAULT 주석 (각 페이지 타입별)

삭제:
- PAGE-01~04 전체 코드 블록 → `gold/ 참조`
- Cross-References 섹션 (각 규칙 파일 내에서 참조)

각 PAGE 패턴은 다음 형태로 압축:

```
## PAGE-01 — List Page
구조: 루트(flex col gap-4 p-4) > 헤더(div) > Table Card(CARD-03b)
KPI/Chart 없음. 전체 예제: gold/campaign-list.tsx
```

- [ ] **Step 2: 줄 수 확인**

```bash
wc -l .claude/rules/page-templates.md
```

Expected: ~70줄 (현재 259줄에서 ~73% 감소)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/page-templates.md
git commit -m "refactor: page-templates.md 간결화 (259→~70줄, gold/ 참조)"
```

---

## Task 10: formatting.md 간결화

**Files:**
- Modify: `.claude/rules/formatting.md`

현재 210줄 → 목표 ~80줄.

- [ ] **Step 1: formatting.md 재작성**

유지:
- ko-KR Rules 테이블 (AI가 추론 불가한 만/억 스케일, "원" 접미사 규칙)
- en-US Rules 테이블
- Function Signatures (formatCurrency, formatCompact 등 — AI가 함수명+시그니처 필요)
- Context Application 테이블 (KPI→formatCompact, Table→formatNumber 매핑)

삭제:
- 각 함수의 상세 예시 출력값 (시그니처 + Context 테이블로 충분)
- Forbidden Patterns (FMT-01~04) → 규칙 문장 1줄씩으로 압축
- ko-KR abbreviation scale 상세 변환표 (규칙 테이블로 충분)

- [ ] **Step 2: 줄 수 확인**

```bash
wc -l .claude/rules/formatting.md
```

Expected: ~80줄 (현재 210줄에서 ~62% 감소)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/formatting.md
git commit -m "refactor: formatting.md 간결화 (210→~80줄)"
```

---

## Task 11: naming.md 간결화

**Files:**
- Modify: `.claude/rules/naming.md`

현재 92줄 → 목표 ~50줄. 이미 가장 짧은 파일이므로 경미한 압축.

- [ ] **Step 1: naming.md 재작성**

유지:
- NAME-01 파일 네이밍 테이블
- NAME-02 컴포넌트 네이밍 + barrel export 규칙
- Directory Structure

삭제:
- NAME-03 CSS Variable 섹션 (tokens.md에 있음)
- Escape Hatch (2줄이면 충분)

- [ ] **Step 2: 줄 수 확인**

```bash
wc -l .claude/rules/naming.md
```

Expected: ~50줄 (현재 92줄에서 ~46% 감소)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/naming.md
git commit -m "refactor: naming.md 간결화 (92→~50줄)"
```

---

## Task 12: Hook 설정 — check-rules.sh 연결

**Files:**
- Create: `.claude/settings.json`

기존 `check-rules.sh`를 PostToolUse Hook으로 연결하여 Write/Edit 후 자동 검증.

- [ ] **Step 1: check-rules.sh가 단일 파일 검사를 지원하는지 확인**

```bash
# 단일 파일로 테스트
bash scripts/check-rules.sh gold/campaign-list.tsx
echo "Exit code: $?"
```

Expected: 파일에 대한 검사 결과 출력

- [ ] **Step 2: settings.json 생성**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "if [[ \"$CLAUDE_FILE_PATH\" == *.tsx ]]; then bash scripts/check-rules.sh \"$CLAUDE_FILE_PATH\" --format text 2>&1 | tail -5; fi",
        "description": "TSX 파일 수정 후 규칙 위반 자동 검사"
      }
    ]
  }
}
```

NOTE: `$CLAUDE_FILE_PATH` 환경변수가 PostToolUse에서 사용 가능한지 확인 필요. 사용 불가능하면 Hook 내부에서 최근 수정 파일을 감지하는 방식으로 변경한다.

- [ ] **Step 3: Hook 동작 테스트**

gold/ 파일을 대상으로 Write 도구를 사용해 테스트. check-rules.sh가 자동 실행되는지 확인.

- [ ] **Step 4: Commit**

```bash
git add .claude/settings.json
git commit -m "feat: PostToolUse Hook으로 check-rules.sh 자동 검증 연결"
```

---

## Task 13: Eval 검증 — 리팩토링 전후 비교

**Files:**
- 변경 없음 (검증만)

리팩토링된 규칙으로 eval을 돌려 기존과 동일한 코드 품질이 나오는지 확인.

- [ ] **Step 1: 리팩토링 완료 상태에서 eval 실행**

```bash
bash scripts/run-eval.sh
```

Expected: 4개 페이지(campaign-list, campaign-detail, campaign-form, campaign-dashboard) 생성

- [ ] **Step 2: check-rules.sh로 점수 비교**

```bash
# 새 결과 점수
bash scripts/score-report.sh

# 이전 결과와 비교 (run9가 리팩토링 전 마지막)
cat tests/snapshots/2026-03-29-run9/report.md
```

Expected: arm_a 점수가 이전 run9과 동등하거나 개선

- [ ] **Step 3: 퇴보(regression) 확인**

점수가 하락한 항목이 있으면:
1. 해당 규칙 파일에서 삭제된 내용 중 필수 규칙이 있었는지 확인
2. 필수 규칙이었다면 규칙 파일에 복원 (규칙 문장 형태로)
3. 불필요한 내용이었다면 무시

- [ ] **Step 4: 최종 줄 수 집계**

```bash
wc -l CLAUDE.md .claude/rules/*.md
```

Expected:
```
   ~50 CLAUDE.md
  ~120 cards.md
   ~80 components.md
   ~80 data-table.md
  ~100 fields.md
   ~75 forbidden.md
   ~80 formatting.md
   ~50 naming.md
   ~70 page-templates.md
   ~75 tokens.md
  ~780 total  (현재 2,601줄에서 ~70% 감소)
```

- [ ] **Step 5: Commit (결과 snapshot)**

```bash
git add tests/snapshots/
git commit -m "test: eval 검증 — 규칙 리팩토링 후 점수 비교"
```

---

## 리스크 및 주의사항

### 리팩토링 시 반드시 유지해야 할 내용

이 항목들은 삭제하면 AI가 올바른 코드를 생성할 수 없다:

1. **shadcn import path 목록** (components.md) — AI가 정확한 경로를 알아야 함
2. **DataTable Props Interface** (data-table.md) — Composed 컴포넌트의 계약
3. **SearchBar Props Interface** (components.md) — Composed 컴포넌트의 계약
4. **formatCurrency/formatCompact 함수 시그니처** (formatting.md) — 유틸리티 API
5. **ko-KR 만/억 스케일 규칙** (formatting.md) — AI가 추론 불가
6. **react-hook-form Controller 패턴** (fields.md) — data-invalid, aria-invalid 연결
7. **chartConfig 정의 방법** (tokens.md 또는 cards.md) — var(--color-KEY) 참조 패턴
8. **페이지 루트 래퍼 클래스** (tokens.md) — `flex flex-col gap-4 p-4`
9. **Card 내부 구조 규칙** (cards.md) — CardHeader 필수, form id linking

### 삭제해도 안전한 내용

1. AI가 이미 아는 React/Tailwind 기본 패턴
2. 동일 규칙의 중복 예제 (한 쌍이면 충분)
3. 다른 규칙 파일에 이미 있는 내용 (크로스 레퍼런스로 대체)
4. Forbidden Patterns의 반복 (forbidden.md에 통합)
5. Column Layout Reference (page-templates.md에만 유지)

### `@` 참조 제거의 리스크

- **규칙이 로딩되지 않을 수 있다**: `paths:` 매칭 파일을 읽지 않으면 규칙이 컨텍스트에 없음
- **완화책**: CLAUDE.md에 "의심스러우면 규칙 파일을 읽어라" 명시 + gold/ 파일 읽기 시 관련 규칙 자동 로딩
- **추가 완화책**: eval에서 퇴보 여부 확인 (Task 13)

### gold/ 파일 관리

- eval을 다시 돌릴 때마다 gold/ 파일을 갱신할지 판단 필요
- 규칙 변경 → eval → 점수 향상 → gold/ 갱신의 사이클
- gold/ 파일은 "현재 최선"을 나타내야 함
