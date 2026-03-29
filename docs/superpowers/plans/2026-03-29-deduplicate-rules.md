# Rule Files Deduplication Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 규칙 파일 간 중복 콘텐츠를 제거하여 "정의는 한 곳, 나머지는 참조" 원칙을 적용한다.

**Architecture:** 각 규칙/패턴의 정의(definition + 예제 코드)는 한 파일에만 존재하고, 다른 파일에서는 `@참조`로 대체한다. 파일 구조 자체는 유지하되, 중복 예제 코드를 제거한다.

**현재 상태:** 9개 규칙 파일, 총 2,540줄. 차트 패턴이 5곳, Card+DataTable이 4곳, Card+Form이 3곳에 중복.

**목표:** ~300줄 이상 감소, 각 패턴의 정의 파일(source of truth)을 명확히 한다.

---

## Source of Truth 매핑

리팩토링 후 각 패턴의 정의 파일:

| 패턴 | 정의 파일 | 참조하는 파일 |
|------|----------|-------------|
| Chart 전체 패턴 (ChartContainer, ChartTooltip, axis 규칙) | `cards.md` CARD-02 | components.md, tokens.md, forbidden.md, page-templates.md |
| Card + DataTable 조합 | `cards.md` CARD-03 | data-table.md, page-templates.md |
| Card + Form 조합 | `fields.md` FIELD-01~04 | cards.md, page-templates.md |
| Card Double Wrapping 금지 | `forbidden.md` FORB-06 | cards.md (제거) |
| Card Without CardHeader 금지 | `cards.md` Forbidden | forbidden.md (참조) |
| Bare Input 금지 | `fields.md` Forbidden | forbidden.md (참조) |
| Inline style 금지 (일반) | `forbidden.md` FORB-01 | tokens.md, components.md (제거) |
| Hardcoded color 금지 | `forbidden.md` FORB-02 | tokens.md, components.md (제거) |

---

## File Structure

변경 대상 파일과 예상 줄 수 변화:

| 파일 | 현재 | 예상 | 변경 내용 |
|------|------|------|----------|
| `forbidden.md` | 249줄 | ~120줄 | FORB-01 chart 예제 제거, FORB-03/05/06 예제 축소 → 참조로 대체 |
| `page-templates.md` | 424줄 | ~200줄 | PAGE-01~04 내부의 Card/Chart/Form 코드를 골격+참조로 축소 |
| `components.md` | 176줄 | ~130줄 | Chart Library Usage 섹션의 중복 예제/금지 패턴 제거 → 참조 |
| `tokens.md` | 199줄 | ~155줄 | Chart & Library Props 섹션의 중복 예제 제거 → 참조 |
| `cards.md` | 412줄 | ~350줄 | CARD-04 Form Card 제거 (fields.md가 정의 파일), Forbidden 섹션 축소 |
| `fields.md` | 459줄 | ~430줄 | Card-less Form/Bare Input 금지 예제 약간 축소 (정의 파일이므로 유지) |
| `data-table.md` | 351줄 | ~310줄 | TABLE-06 Card 래핑 금지 예제 축소 → 참조 |
| `formatting.md` | 178줄 | 178줄 | 변경 없음 (중복 없음) |
| `naming.md` | 92줄 | 92줄 | 변경 없음 (중복 없음) |

**예상 총 감소: 2,540줄 → ~1,965줄 (~575줄 감소, 23%)**

---

## Task 1: `forbidden.md` — 예제 축소, 참조로 대체

forbidden.md는 "금지 목록의 인덱스" 역할로 전환한다. 각 FORB 항목은 규칙 설명 + 최소 예제(일반 케이스 1개) + 정의 파일 참조로 구성.

**Files:**
- Modify: `.claude/rules/forbidden.md`

**변경 원칙:**
- 각 FORB 항목: 규칙 1줄 + WHY 1줄 + FORBIDDEN/CORRECT 예제 1쌍(가장 일반적인 것) + 정의 파일 참조
- chart 전용 예제(contentStyle, stroke) → FORB-01에서 제거, "Chart 관련은 @cards.md CARD-02 참조" 추가
- FORB-03의 긴 "ALLOWED uses of div" 예제 → 유지 (이것은 forbidden.md 고유 콘텐츠)
- FORB-05의 exception(search toolbar) → 유지 (forbidden.md 고유)
- FORB-06의 예제 → 축소 (1쌍만 유지)

- [ ] **Step 1: FORB-01 수정 — chart 예제 제거**

현재 FORB-01에 일반 inline style 예제(6줄) + chart contentStyle/stroke 예제(18줄) = 24줄 예제.
chart 예제를 제거하고 참조로 대체:

```markdown
## FORB-01 — No Inline Styles

NEVER use `style={{}}` on any HTML element or component.
// WHY: Inline styles bypass the token system entirely and cannot be audited by grep or linting.

\```tsx
// FORBIDDEN
<div style={{ marginTop: "24px", padding: "16px" }}>

// CORRECT
<div className="mt-6 p-4">
\```

**No exceptions.** This includes Recharts `contentStyle` and manual `stroke` props on axis/grid components.
Chart 관련 inline style 금지의 전체 규칙과 예제: @cards.md CARD-02
```

- [ ] **Step 2: FORB-03 수정 — 예제 1쌍으로 축소**

FORBIDDEN div 예제 2개 → 1개로 축소. "ALLOWED uses of div" 섹션은 유지.

- [ ] **Step 3: FORB-05 수정 — 예제 축소**

FORBIDDEN/CORRECT 예제를 1쌍으로 축소, "전체 Field 계층 규칙: @fields.md" 참조 추가.
Exception(search toolbar) 유지.

- [ ] **Step 4: FORB-06 수정 — 예제 축소**

FORBIDDEN/CORRECT 예제 1쌍만 유지. "Card 구조 규칙 전체: @cards.md" 참조 추가.

- [ ] **Step 5: 검증**

Run: `wc -l .claude/rules/forbidden.md`
Expected: ~120줄 이하 (현재 249줄)

- [ ] **Step 6: Commit**

```bash
git add .claude/rules/forbidden.md
git commit -m "refactor: forbidden.md 중복 예제 제거, 정의 파일 참조로 대체"
```

---

## Task 2: `components.md` — Chart Library Usage 섹션 축소

components.md의 Chart Library Usage 섹션(125~161줄, ~37줄)은 cards.md CARD-02와 거의 동일한 내용. 역할 설명 + 참조로 대체.

**Files:**
- Modify: `.claude/rules/components.md`

**변경 원칙:**
- Chart Library Usage 섹션: 어떤 컴포넌트를 쓰는지 목록(ChartContainer, ChartTooltip 등)만 유지
- 전체 코드 예제 + FORBIDDEN 예제 제거 → "@cards.md CARD-02 참조"
- Cell Functions in DataTable 섹션: 유지 (components.md 고유)

- [ ] **Step 1: Chart Library Usage 섹션 축소**

현재 37줄 → ~12줄로 축소:

```markdown
## Chart Library Usage

Charts use shadcn's chart components from `@/components/ui/chart`:
- `ChartContainer` — responsive wrapper (MUST have `min-h-[VALUE]` or `aspect-*`)
- `ChartTooltip` + `ChartTooltipContent` — themed tooltip
- `ChartLegend` + `ChartLegendContent` — themed legend

Recharts primitives (`BarChart`, `LineChart`, `CartesianGrid`, `XAxis`, `YAxis`, etc.) are imported directly from `recharts`.

Full chart pattern with code examples, chartConfig usage, and forbidden patterns: @cards.md CARD-02
```

- [ ] **Step 2: 검증**

Run: `wc -l .claude/rules/components.md`
Expected: ~145줄 이하 (현재 176줄)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/components.md
git commit -m "refactor: components.md Chart 섹션 축소, cards.md CARD-02 참조"
```

---

## Task 3: `tokens.md` — Chart & Library Props 섹션 축소

tokens.md의 Chart & Library Props 섹션(146~193줄, ~48줄)은 cards.md CARD-02 + forbidden.md FORB-01과 동일. chartConfig 정의 방법만 남기고 나머지 제거.

**Files:**
- Modify: `.claude/rules/tokens.md`

**변경 원칙:**
- "Forbidden Patterns" 헤더 + 내용 제거 → forbidden.md 참조
- Chart & Library Props: chartConfig 토큰 정의 방법(var(--chart-1) 등)만 유지, 전체 코드 예제 + FORBIDDEN 예제 제거

- [ ] **Step 1: Forbidden Patterns 섹션 제거**

현재:
```markdown
## Forbidden Patterns

For all forbidden color patterns with FORBIDDEN/CORRECT examples, see: @.claude/rules/forbidden.md (FORB-02)
```
이 섹션은 이미 참조만 하고 있으므로, Chart & Library Props로 병합하거나 유지. (현재 4줄이므로 유지해도 무방)

- [ ] **Step 2: Chart & Library Props 섹션 축소**

현재 48줄 → ~15줄로 축소:

```markdown
## Chart & Library Props

Chart colors are defined in `chartConfig` using CSS custom property tokens:
\```tsx
const chartConfig = {
  desktop: { label: "Desktop", color: "var(--chart-1)" },
  mobile: { label: "Mobile", color: "var(--chart-2)" },
} satisfies ChartConfig
\```

Chart elements reference colors as `var(--color-KEY)` (e.g., `stroke="var(--color-desktop)"`).
Charts live inside `Card > CardContent > ChartContainer`.

Full chart pattern, axis/grid rules, and forbidden patterns: @cards.md CARD-02
```

- [ ] **Step 3: 검증**

Run: `wc -l .claude/rules/tokens.md`
Expected: ~165줄 이하 (현재 199줄)

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/tokens.md
git commit -m "refactor: tokens.md Chart 섹션 축소, cards.md CARD-02 참조"
```

---

## Task 4: `cards.md` — CARD-04 제거, Forbidden 섹션 축소

cards.md의 CARD-04(Form Card)는 fields.md FIELD-01~04와 중복. cards.md에서 제거하고 fields.md를 정의 파일로 지정.
Forbidden 섹션의 Card Double Wrapping은 forbidden.md FORB-06과 동일하므로 축소.

**Files:**
- Modify: `.claude/rules/cards.md`

**변경 원칙:**
- CARD-04 Form Card: 전체 코드 예제 제거, 참조로 대체 (~50줄 → ~5줄)
- Forbidden > Card Double Wrapping: 예제 제거, forbidden.md FORB-06 참조 (~25줄 → ~3줄)
- Forbidden > Card Without CardHeader: 유지 (cards.md 고유, forbidden.md에 없음)
- Forbidden > Dashboard Section Without Card: 유지 (cards.md 고유)

- [ ] **Step 1: CARD-04 축소**

현재 CARD-04(225~276줄, ~52줄) → 참조로 대체:

```markdown
### CARD-04 — Form Card

Form cards embed a form inside a Card, typically on settings or edit pages.
`<form>` gets an `id` attribute; submit button uses `form="form-id"` to link from CardFooter.

Full form hierarchy, Field patterns, and code examples: @fields.md
```

- [ ] **Step 2: Forbidden > Card Double Wrapping 축소**

현재(334~357줄, ~24줄) → 참조로 대체:

```markdown
### Card Double Wrapping

NEVER nest Card inside Card. One Card per section, one level deep.
Full rule with examples: @forbidden.md FORB-06
```

- [ ] **Step 3: 검증**

Run: `wc -l .claude/rules/cards.md`
Expected: ~350줄 이하 (현재 412줄)

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/cards.md
git commit -m "refactor: cards.md CARD-04/Double Wrapping 중복 제거, 정의 파일 참조"
```

---

## Task 5: `data-table.md` — TABLE-06 Card 래핑 예제 축소

data-table.md TABLE-06의 Card 래핑 금지 예제는 cards.md + forbidden.md와 중복.

**Files:**
- Modify: `.claude/rules/data-table.md`

**변경 원칙:**
- TABLE-06: DataTable 고유 금지 패턴만 유지 (hardcoded colors in cell, large dataset with Table)
- Card 래핑 관련 금지 예제 2개 → 참조로 대체
- TABLE-04 Card Combination: 이미 3줄이므로 유지

- [ ] **Step 1: TABLE-06 Card 래핑 예제 축소**

첫 번째 금지 패턴("DataTable without Card wrapper")과 두 번째("DataTable with internal Card") 제거, 참조로 대체:

```markdown
## TABLE-06 — Forbidden Patterns

DataTable and Table MUST always be inside `Card > CardContent`. Card wrapping rules: @cards.md CARD-03

\```tsx
// FORBIDDEN — Large dataset (100+ rows) with shadcn Table directly
<Table>
  {largeDataset.map((row) => <TableRow key={row.id}>...</TableRow>)}
</Table>

// CORRECT — Use DataTable for large or interactive data
<DataTable columns={columns} data={largeDataset} pageSize={25} />
\```
// WHY: shadcn Table renders all rows at once with no pagination. 100+ rows degrades scroll performance.

\```tsx
// FORBIDDEN — Hardcoded colors in cell rendering
cell: (row) => <span className="text-red-500">{row.status}</span>
cell: (row) => <span style={{ color: "#ef4444" }}>{row.status}</span>

// CORRECT — Token-based classes
cell: (row) => <span className="text-destructive">{row.status}</span>
cell: (row) => <Badge variant="outline">{row.status}</Badge>
\```
// WHY: Hardcoded colors break theming and dark mode. Token classes adapt automatically.
```

- [ ] **Step 2: 검증**

Run: `wc -l .claude/rules/data-table.md`
Expected: ~315줄 이하 (현재 351줄)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/data-table.md
git commit -m "refactor: data-table.md TABLE-06 Card 래핑 중복 제거"
```

---

## Task 6: `page-templates.md` — 페이지 골격만 유지, 내부 코드 참조로 대체

page-templates.md는 가장 많은 중복을 가진 파일. 각 PAGE 템플릿에서 Card/Chart/Form 내부 코드를 제거하고 골격(섹션 순서, grid 클래스, 구조 주석)만 유지.

**Files:**
- Modify: `.claude/rules/page-templates.md`

**변경 원칙:**
- 각 PAGE: 전체 import + JSX를 "골격 코드"로 축소
- 골격 코드 = root wrapper + page header + 섹션별 1~2줄 주석 + grid 클래스
- Chart/Form/DataTable 내부 코드 → `{/* @cards.md CARD-02 */}` 스타일 참조
- FORBIDDEN 코멘트 목록은 유지 (페이지 레벨 규칙)
- Page Structure Rules 테이블은 유지

- [ ] **Step 1: PAGE-01 (List Page) 축소**

현재 ~58줄 → ~35줄. DataTable columns, filter 내부 코드를 참조로 대체:

```tsx
<div className="flex flex-col gap-4 p-4">
  {/* Page Header -- div, not Card */}
  <div className="flex items-center justify-between">
    <div>
      <h1 className="text-xl font-semibold">Campaigns</h1>
      <p className="text-sm text-muted-foreground">Manage your campaigns</p>
    </div>
    <Button onClick={handleCreate}>New Campaign</Button>
  </div>

  {/* Table Card -- @cards.md CARD-03b (DataTable + Inline Filter) */}
  <Card>
    <CardHeader>
      <CardTitle>All Campaigns</CardTitle>
      <CardDescription>142 campaigns</CardDescription>
      <CardAction>
        <Button variant="outline" size="sm" onClick={handleExport}>Export</Button>
      </CardAction>
    </CardHeader>
    <CardContent>
      {/* Filter toolbar + DataTable -- see @cards.md CARD-03b for full pattern */}
      <DataTable columns={columns} data={rows} />
    </CardContent>
  </Card>
</div>
```

- [ ] **Step 2: PAGE-02 (Detail Page) 축소**

현재 ~98줄 → ~45줄. Chart 내부 코드(ChartContainer, Line, Pie 등) 전부 참조로 대체:

```tsx
<div className="flex flex-col gap-4 p-4">
  {/* Page Header -- div, not Card. Back button + status badge. */}
  <div className="flex items-center justify-between">
    {/* Back button + title + badge */}
  </div>

  {/* KPI Cards -- @cards.md CARD-01 */}
  <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
    {kpiItems.map((item) => (
      <KpiCard key={item.label} {...item} />
    ))}
  </div>

  {/* Chart Cards -- @cards.md CARD-02 */}
  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
    <Card>{/* Line chart -- see @cards.md CARD-02 for full pattern */}</Card>
    <Card>{/* Pie chart -- see @cards.md CARD-02 for full pattern */}</Card>
  </div>

  {/* Related Table Card -- @cards.md CARD-03 */}
  <Card>
    <CardHeader>
      <CardTitle>Ad Groups</CardTitle>
    </CardHeader>
    <CardContent>
      <DataTable columns={adGroupColumns} data={adGroups} />
    </CardContent>
  </Card>
</div>
```

- [ ] **Step 3: PAGE-03 (Form Page) 축소**

현재 ~105줄 → ~35줄. Form 내부의 FieldGroup/FieldSet 코드 전부 참조로 대체:

```tsx
<div className="flex flex-col gap-4 p-4">
  {/* Page Header -- div, not Card. Back button required. */}
  <div className="flex items-center gap-4">
    <Button variant="ghost" size="icon" onClick={() => navigate("/campaigns")}>
      <ArrowLeftIcon className="h-4 w-4" />
    </Button>
    <h1 className="text-xl font-semibold">Create Campaign</h1>
  </div>

  {/* Form Card -- @fields.md FIELD-02 (Multi-Section Form) */}
  <Card>
    <CardHeader>
      <CardTitle>Campaign Details</CardTitle>
      <CardDescription>Fill in the details for your new campaign.</CardDescription>
    </CardHeader>
    <CardContent>
      {/* form + FieldGroup + FieldSet -- see @fields.md FIELD-02 for full pattern */}
    </CardContent>
    <CardFooter>
      <Button variant="outline" type="button" onClick={handleCancel}>Cancel</Button>
      <Button type="submit" form="campaign-form">Save</Button>
    </CardFooter>
  </Card>
</div>
```

- [ ] **Step 4: PAGE-04 (Dashboard Page) 축소**

현재 ~98줄 → ~45줄. PAGE-02와 동일 접근 — Chart/DataTable 내부 제거:

```tsx
<div className="flex flex-col gap-4 p-4">
  {/* Page Header -- div, not Card */}
  <div className="flex items-center justify-between">
    <div>
      <h1 className="text-xl font-semibold">Dashboard</h1>
      <p className="text-sm text-muted-foreground">Overview of campaign performance</p>
    </div>
    <Button onClick={handleCreate}>New Campaign</Button>
  </div>

  {/* KPI Cards -- @cards.md CARD-01 */}
  <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
    {kpiItems.map((item) => (
      <KpiCard key={item.label} {...item} />
    ))}
  </div>

  {/* Chart Cards -- @cards.md CARD-02 */}
  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
    <Card>{/* Line chart -- see @cards.md CARD-02 */}</Card>
    <Card>{/* Bar chart -- see @cards.md CARD-02 */}</Card>
  </div>

  {/* Recent Table Card -- @cards.md CARD-03 */}
  <Card>
    <CardHeader>
      <CardTitle>Recent Campaigns</CardTitle>
    </CardHeader>
    <CardContent>
      <DataTable columns={columns} data={recentRows} />
    </CardContent>
  </Card>
</div>
```

- [ ] **Step 5: 검증**

Run: `wc -l .claude/rules/page-templates.md`
Expected: ~200줄 이하 (현재 424줄)

- [ ] **Step 6: Commit**

```bash
git add .claude/rules/page-templates.md
git commit -m "refactor: page-templates.md 골격만 유지, Card/Chart/Form 내부 참조로 대체"
```

---

## Task 7: CLAUDE.md 참조 정합성 확인

CLAUDE.md의 `@.claude/rules/*` 참조와 각 규칙 파일 간 cross-reference가 정확한지 확인.

**Files:**
- Verify: `CLAUDE.md`
- Verify: `.claude/rules/*.md` (모든 파일의 cross-reference)

- [ ] **Step 1: 모든 @참조 수집 및 검증**

각 규칙 파일의 `@.claude/rules/` 또는 `@cards.md` 등의 참조가 실제 존재하는 섹션을 가리키는지 확인.

```bash
grep -rn '@.*\.md' .claude/rules/ | sort
```

- [ ] **Step 2: 깨진 참조 수정**

삭제/이동된 섹션을 가리키는 참조가 있으면 수정.

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/ CLAUDE.md
git commit -m "refactor: cross-reference 정합성 확인 및 수정"
```

---

## Task 8: Eval 검증

리팩토링된 규칙이 기존과 동일한 코드를 생성하는지 eval로 확인.

- [ ] **Step 1: eval 실행**

```bash
./scripts/run-eval.sh
```

- [ ] **Step 2: check-rules 통과 확인**

```bash
./scripts/check-rules.sh tests/snapshots/latest/*.with_rules.tsx
```

- [ ] **Step 3: 결과 비교**

이전 snapshot과 점수 비교. 규칙 준수율이 동일하거나 개선되어야 함.
점수가 하락한 항목이 있으면 해당 규칙 파일의 참조가 AI에게 충분한 컨텍스트를 제공하는지 점검.

- [ ] **Step 4: 필요시 참조 보강**

참조만으로 부족한 경우, 핵심 규칙 1줄 요약을 참조 옆에 추가:
```markdown
Chart 전체 패턴: @cards.md CARD-02 (axis에 stroke 금지, ChartTooltipContent 사용 필수)
```

---

## 실행 순서 및 의존성

```
Task 1 (forbidden.md)     ─┐
Task 2 (components.md)     ├─ 독립 실행 가능 (병렬)
Task 3 (tokens.md)         ├─
Task 4 (cards.md)          ├─
Task 5 (data-table.md)     ─┘
                            │
Task 6 (page-templates.md) ─── Task 1~5 완료 후 (참조 대상이 확정되어야 함)
                            │
Task 7 (cross-reference)   ─── Task 6 완료 후
                            │
Task 8 (eval 검증)         ─── Task 7 완료 후
```

Task 1~5는 서로 독립적이므로 병렬 실행 가능.
Task 6은 참조 대상 파일이 확정된 후 실행.
Task 7~8은 순차 실행.
