# Eval Consolidation & Component Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eval 프롬프트를 5개→4개로 병합하고, 규칙 파일과 템플릿을 강화하여 SearchBar/RadioGroup/Choice Card/DataTable 개선을 검증할 수 있도록 한다.

**Architecture:** 규칙 파일을 먼저 업데이트(fields.md, components.md, data-table.md)하고, 템플릿(DataTable.tsx, SearchBar.tsx)을 강화한 뒤, 프롬프트 4개를 실무 요청 스타일로 재작성한다. 마지막으로 reset-preview.sh와 check-rules.sh를 동기화한다.

**Tech Stack:** shadcn/ui, TanStack Table, react-hook-form, Recharts, Tailwind CSS

---

## File Map

### 수정할 파일

| 파일 | 변경 내용 |
|------|----------|
| `.claude/rules/fields.md` | FIELD-08 (RadioGroup), FIELD-09 (Choice Card) 추가, Common Imports에 RadioGroup/FieldTitle |
| `.claude/rules/components.md` | RadioGroup import 추가, SearchBar Composed 설명 강화 (Config-driven props) |
| `.claude/rules/data-table.md` | TABLE-03에 헤더 배경색/정렬 아이콘 기본 표시 추가, TABLE-05에 Switch 셀 예제 |
| `scripts/templates/composed/DataTable.tsx` | TableHeader bg-muted, 정렬 아이콘 항상 표시 (ArrowUpDown → ArrowUp/ArrowDown) |
| `scripts/templates/composed/index.ts` | SearchBar export 추가 |
| `scripts/reset-preview.sh` | shadcn 설치 목록에 `radio-group` 추가 |
| `scripts/check-rules.sh` | SearchBar ENV-02 검증 추가 |
| `tests/prompts/campaign-list.md` | 재작성 (SearchBar + DataTable 강화, ko-KR) |
| `tests/prompts/campaign-form.md` | 재작성 (모든 폼 컴포넌트 통합, ko-KR) |
| `tests/prompts/campaign-detail.md` | 재작성 (Tabs 차별화, ko-KR) |

### 생성할 파일

| 파일 | 내용 |
|------|------|
| `scripts/templates/composed/SearchBar.tsx` | Config-driven 필터 바 (text, select, combobox, dateRange) |
| `tests/prompts/campaign-dashboard.md` | dashboard-overview 대체 (ko-KR) |

### 삭제할 파일

| 파일 | 이유 |
|------|------|
| `tests/prompts/dashboard-overview.md` | campaign-dashboard.md로 대체 |
| `tests/prompts/ad-group-form.md` | campaign-form.md에 병합 |

---

### Task 1: fields.md — FIELD-08, FIELD-09 추가

**Files:**
- Modify: `.claude/rules/fields.md`

- [ ] **Step 1: Common Imports에 RadioGroup, FieldTitle 추가**

`.claude/rules/fields.md`의 Common Imports 섹션 끝에 추가:

```tsx
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
```

그리고 기존 Field import에 `FieldTitle` 추가:

```tsx
import { Field, FieldLabel, FieldGroup, FieldSet, FieldLegend, FieldSeparator, FieldDescription, FieldError, FieldContent, FieldTitle } from "@/components/ui/field"
```

- [ ] **Step 2: FIELD-08 — RadioGroup 추가**

`FIELD-07` 섹션과 `CardFooter Button Rules` 섹션 사이에 추가:

```markdown
## FIELD-08 — RadioGroup

수직 라디오 버튼. 옵션이 2~5개이고 상호 배타적 선택일 때 사용한다.
옵션이 1개면 Checkbox, 6개 이상이면 Select 또는 Combobox를 사용한다.

고유 import: `RadioGroup, RadioGroupItem` from `@/components/ui/radio-group`

\```tsx
<Field>
  <FieldLabel>캠페인 목표</FieldLabel>
  <RadioGroup defaultValue="awareness" onValueChange={setGoal}>
    <div className="flex items-center gap-2">
      <RadioGroupItem value="awareness" id="goal-awareness" />
      <FieldLabel htmlFor="goal-awareness" className="font-normal">브랜드 인지도</FieldLabel>
    </div>
    <div className="flex items-center gap-2">
      <RadioGroupItem value="conversion" id="goal-conversion" />
      <FieldLabel htmlFor="goal-conversion" className="font-normal">전환</FieldLabel>
    </div>
    <div className="flex items-center gap-2">
      <RadioGroupItem value="traffic" id="goal-traffic" />
      <FieldLabel htmlFor="goal-traffic" className="font-normal">트래픽</FieldLabel>
    </div>
  </RadioGroup>
  <FieldDescription>캠페인의 주요 목표를 선택하세요.</FieldDescription>
</Field>
\```

// WHY: RadioGroup은 시각적으로 모든 옵션을 한눈에 보여준다. Select는 드롭다운을 열어야 하므로
// 옵션이 적을 때는 RadioGroup이 더 빠른 인터랙션을 제공한다.
```

- [ ] **Step 3: FIELD-09 — Choice Card (RadioGroup + Field) 추가**

FIELD-08 바로 아래에 추가:

```markdown
## FIELD-09 — Choice Card (RadioGroup + Field)

RadioGroup 아이템을 카드 형태로 표시. 각 옵션에 제목과 설명이 필요할 때 사용한다.
shadcn 공식 패턴: `FieldLabel > Field orientation="horizontal" > FieldContent(FieldTitle + FieldDescription) + RadioGroupItem`.

고유 import: `RadioGroup, RadioGroupItem` from `@/components/ui/radio-group`

\```tsx
<Field>
  <FieldLabel>요금제</FieldLabel>
  <RadioGroup defaultValue="standard" onValueChange={setPlan}>
    <FieldLabel htmlFor="plan-standard">
      <Field orientation="horizontal">
        <FieldContent>
          <FieldTitle>스탠다드</FieldTitle>
          <FieldDescription>소규모 팀에 적합합니다.</FieldDescription>
        </FieldContent>
        <RadioGroupItem value="standard" id="plan-standard" />
      </Field>
    </FieldLabel>
    <FieldLabel htmlFor="plan-professional">
      <Field orientation="horizontal">
        <FieldContent>
          <FieldTitle>프로페셔널</FieldTitle>
          <FieldDescription>성장하는 비즈니스를 위한 플랜입니다.</FieldDescription>
        </FieldContent>
        <RadioGroupItem value="professional" id="plan-professional" />
      </Field>
    </FieldLabel>
    <FieldLabel htmlFor="plan-enterprise">
      <Field orientation="horizontal">
        <FieldContent>
          <FieldTitle>엔터프라이즈</FieldTitle>
          <FieldDescription>대규모 팀과 기업을 위한 플랜입니다.</FieldDescription>
        </FieldContent>
        <RadioGroupItem value="enterprise" id="plan-enterprise" />
      </Field>
    </FieldLabel>
  </RadioGroup>
</Field>
\```

**Rules:**
- 외부 `Field > FieldLabel`로 전체 그룹의 레이블 제공
- 각 아이템은 `FieldLabel(htmlFor) > Field(orientation="horizontal") > FieldContent + RadioGroupItem`
- FieldContent 안에 `FieldTitle`과 `FieldDescription`으로 카드 내용 구성
- RadioGroupItem이 FieldContent 뒤에 위치 (우측 정렬)

// WHY: Choice Card는 각 옵션의 의미를 설명해야 할 때 사용한다. 단순 라벨만으로 충분하면 FIELD-08을 쓴다.
// shadcn 공식 패턴을 그대로 따르므로 접근성과 키보드 네비게이션이 보장된다.
```

- [ ] **Step 4: 변경 확인**

Run: `grep -n "FIELD-08\|FIELD-09\|FieldTitle\|RadioGroup" .claude/rules/fields.md`
Expected: FIELD-08, FIELD-09 섹션과 RadioGroup/FieldTitle import이 모두 존재

- [ ] **Step 5: Commit**

```bash
git add .claude/rules/fields.md
git commit -m "docs: fields.md에 FIELD-08(RadioGroup), FIELD-09(Choice Card) 추가"
```

---

### Task 2: components.md — RadioGroup import, SearchBar 강화

**Files:**
- Modify: `.claude/rules/components.md`

- [ ] **Step 1: shadcn import 목록에 RadioGroup 추가**

`Import Convention > shadcn — direct imports` 섹션의 마지막 import 뒤에 추가:

```tsx
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
```

- [ ] **Step 2: Composed Component List 테이블에 SearchBar 설명 강화**

현재 SearchBar 행:

```markdown
| **SearchBar** | Configurable filter bar with multiple input types | Filter state management, debounced search, config-driven field rendering |
```

이 행은 이미 존재하므로 유지. Composed Qualification 아래에 SearchBar의 Props 스펙 참조를 추가:

`Composed Component List` 테이블 아래의 참조 목록에 추가:

```markdown
- @.claude/rules/cards.md — SearchBar usage in CARD-03b filter toolbar
```

- [ ] **Step 3: Input Component Selection에 RadioGroup 선택 기준 추가**

`DATE-01` 섹션 뒤에 새 섹션 추가:

```markdown
### RADIO-01 — RadioGroup vs Select vs Choice Card

\```
옵션이 2~5개이고 상호 배타적?
  ├─ 라벨만으로 충분? → RadioGroup (FIELD-08)
  └─ 각 옵션에 제목+설명 필요? → Choice Card (FIELD-09)

옵션이 ~10개 이하, 고정? → Select
옵션이 10개 이상? → Combobox
\```

| 기준 | RadioGroup | Choice Card | Select |
|------|-----------|-------------|--------|
| 옵션 수 | 2~5개 | 2~5개 | ~10개 이하 |
| 옵션 설명 | 불필요 | 제목+설명 필요 | 불필요 |
| 시각적 크기 | 컴팩트 | 카드 크기 | 드롭다운 |
| 대시보드 사용처 | 캠페인 목표, 입찰 전략 | 요금제, 캠페인 유형 | 상태, 지역, 기간 |

// WHY: 옵션이 적고 한눈에 보여야 하면 RadioGroup. 설명이 필요하면 Choice Card.
// 옵션이 많아지면 화면을 차지하므로 Select/Combobox로 전환한다.
```

- [ ] **Step 4: 변경 확인**

Run: `grep -n "RadioGroup\|RADIO-01\|SearchBar" .claude/rules/components.md`
Expected: RadioGroup import, RADIO-01 섹션, SearchBar 참조가 모두 존재

- [ ] **Step 5: Commit**

```bash
git add .claude/rules/components.md
git commit -m "docs: components.md에 RadioGroup import, RADIO-01 선택 기준, SearchBar 참조 추가"
```

---

### Task 3: data-table.md — 헤더 배경색, 정렬 아이콘, Switch 셀

**Files:**
- Modify: `.claude/rules/data-table.md`

- [ ] **Step 1: TABLE-03 Built-in Features 테이블 업데이트**

현재 TABLE-03 테이블:

```markdown
| Feature | Location | Description |
|---------|----------|-------------|
| Sorting | Header click | `sortable: true` columns; sort icon in header; asc -> desc -> none cycle |
| Column pinning | `pinned: "left"` | Checkbox + ID + Title pinned, sticky on horizontal scroll |
| Pagination | DataTable bottom | `pageSize`-based; prev/next + page numbers |
| Row selection | Checkbox column | Select all / individual; `onSelectionChange` callback |
```

다음으로 교체:

```markdown
| Feature | Location | Description |
|---------|----------|-------------|
| Sorting | Header click | `sortable: true` columns; sort icon always visible (`ArrowUpDown`); active sort shows `ArrowUp`/`ArrowDown`; asc -> desc -> none cycle |
| Column pinning | `pinned: "left"` | Checkbox + ID + Title pinned, sticky on horizontal scroll |
| Pagination | DataTable bottom | `pageSize`-based; prev/next + page info ("Page 1 of 8") |
| Row selection | Checkbox column | Select all / individual; `onSelectionChange` callback |
| Header styling | `TableHeader` | `bg-muted` background on header row for visual emphasis |
| Cell Switch | cell function | Toggle switch in table cell for on/off state (e.g., campaign active/pause) |
```

- [ ] **Step 2: TABLE-05 컬럼 예제에 Switch 셀 추가**

TABLE-05의 Actions 컬럼(12번) 바로 앞에 Switch 컬럼 추가:

```tsx
  // 11.5 Active toggle — Switch in cell
  {
    accessorKey: "isActive",
    header: "Active",
    align: "center",
    enableSorting: false,
    cell: (row) => (
      <Switch
        checked={row.isActive}
        onCheckedChange={(checked) => handleToggleActive(row.id, checked)}
        aria-label={`Toggle ${row.name}`}
      />
    ),
  },
```

그리고 import 목록에 `Switch` 추가:

```tsx
import { Switch } from "@/components/ui/switch"
```

- [ ] **Step 3: TABLE-03 아래에 헤더 스타일링 규칙 추가**

TABLE-03 테이블 뒤에 추가:

```markdown
**Header styling rules:**
- `TableHeader` 내부 `TableRow`에 `bg-muted` 적용 — 헤더와 본문의 시각적 구분
- 정렬 가능 컬럼(`sortable: true`)에는 `ArrowUpDown` 아이콘이 항상 표시됨
- 활성 정렬 시 `ArrowUp`(asc) 또는 `ArrowDown`(desc)으로 전환
- 아이콘은 `lucide-react`에서 import: `ArrowUpDown`, `ArrowUp`, `ArrowDown`

// WHY: 헤더 배경색이 없으면 데이터 행과 구분이 약하다. 정렬 아이콘이 hover에서만 보이면
// 사용자가 정렬 가능 여부를 알 수 없다. 항상 표시하여 어포던스를 제공한다.
```

- [ ] **Step 4: 변경 확인**

Run: `grep -n "bg-muted\|ArrowUpDown\|Switch\|Cell Switch" .claude/rules/data-table.md`
Expected: bg-muted, ArrowUpDown, Switch 관련 내용이 모두 존재

- [ ] **Step 5: Commit**

```bash
git add .claude/rules/data-table.md
git commit -m "docs: data-table.md에 헤더 배경색, 정렬 아이콘 상시 표시, Switch 셀 패턴 추가"
```

---

### Task 4: DataTable.tsx 템플릿 강화

**Files:**
- Modify: `scripts/templates/composed/DataTable.tsx`

- [ ] **Step 1: import에 lucide-react 아이콘 추가**

파일 상단 import 영역에 추가:

```tsx
import { ArrowUpDown, ArrowUp, ArrowDown } from "lucide-react"
```

- [ ] **Step 2: TableHeader에 bg-muted 적용**

현재 (line 82-83):
```tsx
<TableHeader>
  {table.getHeaderGroups().map((headerGroup) => (
    <TableRow key={headerGroup.id}>
```

다음으로 교체:
```tsx
<TableHeader>
  {table.getHeaderGroups().map((headerGroup) => (
    <TableRow key={headerGroup.id} className="bg-muted">
```

- [ ] **Step 3: 정렬 아이콘을 항상 표시하도록 변경**

현재 (line 94-98):
```tsx
                  {header.isPlaceholder
                    ? null
                    : flexRender(header.column.columnDef.header, header.getContext())}
                  {header.column.getIsSorted() === "asc" && " ↑"}
                  {header.column.getIsSorted() === "desc" && " ↓"}
```

다음으로 교체:
```tsx
                  {header.isPlaceholder
                    ? null
                    : (
                      <div
                        className={
                          header.column.getCanSort()
                            ? "flex items-center gap-1 cursor-pointer select-none"
                            : undefined
                        }
                        onClick={header.column.getToggleSortingHandler()}
                      >
                        {flexRender(header.column.columnDef.header, header.getContext())}
                        {header.column.getCanSort() && (
                          header.column.getIsSorted() === "asc"
                            ? <ArrowUp className="size-4" />
                            : header.column.getIsSorted() === "desc"
                              ? <ArrowDown className="size-4" />
                              : <ArrowUpDown className="size-4 text-muted-foreground" />
                        )}
                      </div>
                    )}
```

그리고 `TableHead`에서 기존 onClick 제거 (line 92):
```tsx
                  onClick={header.column.getCanSort() ? header.column.getToggleSortingHandler() : undefined}
```
→ 삭제 (onClick이 내부 div로 이동했으므로)

- [ ] **Step 4: 변경 확인**

Run: `grep -n "ArrowUpDown\|bg-muted\|ArrowUp\|ArrowDown" scripts/templates/composed/DataTable.tsx`
Expected: ArrowUpDown import, bg-muted 클래스, ArrowUp/ArrowDown 조건부 렌더링이 모두 존재

- [ ] **Step 5: Commit**

```bash
git add scripts/templates/composed/DataTable.tsx
git commit -m "feat: DataTable 템플릿에 헤더 배경색, 정렬 아이콘 상시 표시 추가"
```

---

### Task 5: SearchBar.tsx 템플릿 생성

**Files:**
- Create: `scripts/templates/composed/SearchBar.tsx`
- Modify: `scripts/templates/composed/index.ts`

- [ ] **Step 1: SearchBar.tsx 생성**

`scripts/templates/composed/SearchBar.tsx` 생성:

```tsx
import * as React from "react"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select"
import {
  Combobox,
  ComboboxInput,
  ComboboxContent,
  ComboboxList,
  ComboboxItem,
  ComboboxEmpty,
} from "@/components/ui/combobox"
import {
  Popover,
  PopoverTrigger,
  PopoverContent,
} from "@/components/ui/popover"
import { Calendar } from "@/components/ui/calendar"
import { Button } from "@/components/ui/button"
import { CalendarIcon, SearchIcon } from "lucide-react"
import { formatDate } from "@/lib/format"
import type { DateRange } from "react-day-picker"

interface SearchBarFilterBase {
  name: string
  placeholder?: string
}

interface TextFilter extends SearchBarFilterBase {
  type: "text"
}

interface SelectFilter extends SearchBarFilterBase {
  type: "select"
  options: { value: string; label: string }[]
}

interface ComboboxFilter extends SearchBarFilterBase {
  type: "combobox"
  items: { value: string; label: string }[]
}

interface DateRangeFilter extends SearchBarFilterBase {
  type: "dateRange"
}

type SearchBarFilter = TextFilter | SelectFilter | ComboboxFilter | DateRangeFilter

interface SearchBarProps {
  filters: SearchBarFilter[]
  onSearch: (values: Record<string, unknown>) => void
}

export function SearchBar({ filters, onSearch }: SearchBarProps) {
  const [values, setValues] = React.useState<Record<string, unknown>>({})

  const updateValue = (name: string, value: unknown) => {
    const next = { ...values, [name]: value }
    setValues(next)
    onSearch(next)
  }

  return (
    <div className="flex items-center gap-2 pb-4">
      {filters.map((filter) => {
        switch (filter.type) {
          case "text":
            return (
              <div key={filter.name} className="relative">
                <SearchIcon className="absolute left-2.5 top-2.5 size-4 text-muted-foreground" />
                <Input
                  placeholder={filter.placeholder}
                  value={(values[filter.name] as string) ?? ""}
                  onChange={(e) => updateValue(filter.name, e.target.value)}
                  className="pl-8"
                />
              </div>
            )

          case "select":
            return (
              <Select
                key={filter.name}
                value={(values[filter.name] as string) ?? ""}
                onValueChange={(v) => updateValue(filter.name, v)}
              >
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder={filter.placeholder} />
                </SelectTrigger>
                <SelectContent>
                  {filter.options.map((opt) => (
                    <SelectItem key={opt.value} value={opt.value}>
                      {opt.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            )

          case "combobox":
            return (
              <Combobox
                key={filter.name}
                items={filter.items}
                value={values[filter.name] as string | undefined}
                onValueChange={(v) => updateValue(filter.name, v)}
                itemToStringValue={(item) => item.label}
              >
                <ComboboxInput placeholder={filter.placeholder} />
                <ComboboxContent>
                  <ComboboxList>
                    {(item) => <ComboboxItem>{item.label}</ComboboxItem>}
                  </ComboboxList>
                  <ComboboxEmpty>No results found.</ComboboxEmpty>
                </ComboboxContent>
              </Combobox>
            )

          case "dateRange": {
            const dateRange = values[filter.name] as DateRange | undefined
            return (
              <Popover key={filter.name}>
                <PopoverTrigger asChild>
                  <Button
                    variant="outline"
                    className="w-[260px] justify-start text-left font-normal"
                    data-empty={!dateRange?.from || undefined}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {dateRange?.from ? (
                      dateRange.to ? (
                        <>
                          {formatDate(dateRange.from, { locale: "ko-KR" })} -{" "}
                          {formatDate(dateRange.to, { locale: "ko-KR" })}
                        </>
                      ) : (
                        formatDate(dateRange.from, { locale: "ko-KR" })
                      )
                    ) : (
                      <span className="text-muted-foreground">
                        {filter.placeholder ?? "기간 선택"}
                      </span>
                    )}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="range"
                    selected={dateRange}
                    onSelect={(range) => updateValue(filter.name, range)}
                    numberOfMonths={2}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
            )
          }

          default:
            return null
        }
      })}
    </div>
  )
}
```

- [ ] **Step 2: barrel export에 SearchBar 추가**

`scripts/templates/composed/index.ts`를 수정:

```ts
export { DataTable } from "./DataTable"
export { KpiCard } from "./KpiCard"
export { SearchBar } from "./SearchBar"
```

- [ ] **Step 3: 변경 확인**

Run: `ls scripts/templates/composed/`
Expected: DataTable.tsx, KpiCard.tsx, SearchBar.tsx, index.ts

- [ ] **Step 4: Commit**

```bash
git add scripts/templates/composed/SearchBar.tsx scripts/templates/composed/index.ts
git commit -m "feat: SearchBar Composed 컴포넌트 템플릿 생성 (Config-driven filter bar)"
```

---

### Task 6: reset-preview.sh — radio-group, combobox 설치 추가

**Files:**
- Modify: `scripts/reset-preview.sh`

- [ ] **Step 1: shadcn 설치 목록에 radio-group, combobox 추가**

현재 (line 51):
```bash
npx shadcn@latest add card badge input textarea select field chart separator popover calendar switch --yes 2>&1
```

다음으로 교체:
```bash
npx shadcn@latest add card badge input textarea select field chart separator popover calendar switch radio-group combobox --yes 2>&1
```

- [ ] **Step 2: 런타임 의존성에 react-day-picker 확인**

`react-day-picker`는 shadcn의 calendar 컴포넌트 설치 시 자동으로 포함되므로 추가 설치 불필요. 확인만 한다.

Run: `grep "react-day-picker" scripts/reset-preview.sh`
Expected: 없음 (calendar 설치 시 자동 포함)

- [ ] **Step 3: Commit**

```bash
git add scripts/reset-preview.sh
git commit -m "chore: reset-preview.sh에 radio-group, combobox shadcn 컴포넌트 설치 추가"
```

---

### Task 7: check-rules.sh — SearchBar 환경 검증 추가

**Files:**
- Modify: `scripts/check-rules.sh`

- [ ] **Step 1: ENV-05에 SearchBar.tsx 허용 확인**

현재 ENV-05 (line 406):
```bash
if [ "$bname" != "DataTable.tsx" ] && [ "$bname" != "KpiCard.tsx" ] && [ "$bname" != "SearchBar.tsx" ] && [ "$bname" != "index.ts" ]; then
```

SearchBar.tsx는 이미 허용 목록에 있으므로 변경 불필요.

- [ ] **Step 2: Commit (변경 없으면 스킵)**

check-rules.sh에 변경이 필요 없다면 이 커밋은 스킵한다.

---

### Task 8: 프롬프트 — campaign-dashboard.md 생성

**Files:**
- Create: `tests/prompts/campaign-dashboard.md`
- Delete: `tests/prompts/dashboard-overview.md`

- [ ] **Step 1: campaign-dashboard.md 생성**

```markdown
---
page: campaign-dashboard
template: PAGE-04
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
  - formatCurrency
  - formatNumber
  - formatPercent
---

# 캠페인 대시보드 페이지 생성

광고 운영팀이 매일 아침 전체 캠페인 성과를 한눈에 확인하는 대시보드가 필요합니다.
팀장이 주간 회의에서 이 화면을 프로젝터로 띄워 현황을 공유하므로, KPI 수치가 크고 명확하게 보여야 합니다.

## 요구사항

### 페이지 헤더
- 제목: "캠페인 대시보드"
- 설명: "전체 캠페인 성과 현황"
- 우측에 "캠페인 생성" 버튼

### KPI 카드 (4개, 4-column grid)
아래 지표를 KpiCard 컴포넌트로 표시합니다. 값은 compact 포맷(만/억 단위)으로 표시하세요.

| 지표 | 값 (원본) | delta |
|------|----------|-------|
| 총 지출 | 245,800,000원 | +12.5% |
| 노출수 | 18,420,000 | +8.3% |
| 클릭수 | 892,000 | -2.1% |
| 평균 CTR | 4.84% | +0.5% |

- 총 지출과 클릭수는 통화/수량 compact(formatCurrencyCompact, formatCompact)
- CTR은 formatPercent
- delta는 formatDelta

### 차트 (2개, 2-column grid)

#### 일일 지출 추이 (LineChart)
- 최근 30일 데이터 (목 데이터 30건)
- X축: 날짜, Y축: 지출(원)
- CardAction에 기간 Select: "최근 7일", "최근 30일", "최근 90일"
- chartConfig에서 색상 정의, `var(--color-KEY)` 참조
- ChartTooltip + ChartTooltipContent 사용

#### 채널별 지출 비율 (BarChart)
- 채널: Google Ads, Meta Ads, Naver SA, Kakao Moment, X Ads
- 각 채널별 지출 금액
- chartConfig에서 chart-1~5 토큰 색상 사용

### 최근 캠페인 테이블
- CardHeader: "최근 캠페인" + CardDescription "최근 활동이 있는 캠페인"
- DataTable 컬럼:
  - ID (pinned left, sortable)
  - 캠페인명 (pinned left, sortable)
  - 상태 (Badge variant="outline")
  - 채널
  - 노출수 (right-aligned, formatNumber)
  - 클릭수 (right-aligned, formatNumber)
  - CTR (right-aligned, formatPercent)
  - 지출 (right-aligned, formatCurrency)
- 10행 목 데이터
- onRowClick으로 `/campaigns/${row.id}` 이동

### 기타
- 로케일: ko-KR, 통화: KRW
- 모든 숫자는 format 유틸리티 사용 (inline 포맷팅 금지)

## 출력
- Composed 컴포넌트(DataTable, KpiCard)가 없으면 `preview/src/components/composed/`에 생성하세요
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
```

- [ ] **Step 2: dashboard-overview.md 삭제**

```bash
rm tests/prompts/dashboard-overview.md
```

- [ ] **Step 3: 변경 확인**

Run: `ls tests/prompts/`
Expected: campaign-dashboard.md, campaign-detail.md, campaign-form.md, campaign-list.md (4개)

- [ ] **Step 4: Commit**

```bash
git add tests/prompts/campaign-dashboard.md
git rm tests/prompts/dashboard-overview.md
git commit -m "feat: dashboard-overview → campaign-dashboard 프롬프트 재작성 (ko-KR, 실무 스타일)"
```

---

### Task 9: 프롬프트 — campaign-list.md 재작성

**Files:**
- Modify: `tests/prompts/campaign-list.md`

- [ ] **Step 1: campaign-list.md 전체 교체**

```markdown
---
page: campaign-list
template: PAGE-01
expected_ui:
  - card
  - button
  - badge
  - input
  - select
  - dropdown-menu
  - checkbox
  - switch
  - combobox
  - popover
  - calendar
expected_composed:
  - DataTable
  - SearchBar
expected_lib:
  - formatNumber
  - formatCurrency
  - formatPercent
  - formatDate
---

# 캠페인 관리 페이지 생성

캠페인 운영팀에서 전체 캠페인을 관리하는 페이지가 필요합니다.
운영팀은 하루에 수십 번 이 페이지를 방문하여 캠페인 상태를 확인하고, 성과가 낮은 캠페인을 일시정지하거나 예산을 조정합니다.
필터링과 정렬이 빠르게 되어야 하고, 목록에서 바로 캠페인 활성/비활성 토글이 가능해야 합니다.

## 요구사항

### 페이지 헤더
- 제목: "캠페인 관리"
- 설명: "전체 캠페인 목록을 관리합니다"
- 우측에 "캠페인 생성" 버튼

### 검색/필터 바 (SearchBar)
Card 안, DataTable 위에 SearchBar 컴포넌트를 배치합니다.
다음 필터를 config로 구성하세요:

| 필터 | 타입 | 설명 |
|------|------|------|
| 검색 | text | 캠페인명으로 검색 (placeholder: "캠페인 검색...") |
| 채널 | combobox | Google Ads, Meta Ads, Naver SA, Kakao Moment, X Ads (placeholder: "채널 선택") |
| 기간 | dateRange | 캠페인 운영 기간 필터 (placeholder: "기간 선택") |
| 상태 | select | 전체, 활성, 일시정지, 종료 (placeholder: "상태") |

### DataTable
- CardHeader: "전체 캠페인" + CardDescription "총 142개 캠페인" + Export 버튼 (CardAction, variant="outline", size="sm")

#### 컬럼 구성
| 순서 | 컬럼 | 설정 |
|------|------|------|
| 1 | 선택 (Checkbox) | pinned left, 전체선택/해제 |
| 2 | ID | pinned left, sortable |
| 3 | 캠페인명 | pinned left, sortable |
| 4 | 상태 | sortable, Badge variant="outline" |
| 5 | 채널 | sortable |
| 6 | 활성 | Switch 토글 (on/off로 캠페인 활성화/비활성화) |
| 7 | 시작일 | sortable, formatDate |
| 8 | 종료일 | sortable, formatDate |
| 9 | 노출수 | sortable, right-aligned, tabular-nums, formatNumber |
| 10 | 클릭수 | sortable, right-aligned, tabular-nums, formatNumber |
| 11 | CTR | sortable, right-aligned, tabular-nums, formatPercent |
| 12 | 지출 | sortable, right-aligned, tabular-nums, font-medium, formatCurrency |
| 13 | 액션 | DropdownMenu: 수정, 복제, 삭제(text-destructive) |

- pageSize: 20
- 20행 목 데이터 (다양한 상태와 채널 혼합)
- onRowClick으로 `/campaigns/${row.id}` 이동
- onSelectionChange로 선택된 캠페인 추적

### 기타
- 로케일: ko-KR, 통화: KRW
- 날짜 포맷: formatDate 사용 (date-fns 직접 사용 금지)
- 모든 숫자는 format 유틸리티 사용

## 출력
- Composed 컴포넌트(DataTable, SearchBar)가 없으면 `preview/src/components/composed/`에 생성하세요
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
```

- [ ] **Step 2: 변경 확인**

Run: `grep -c "SearchBar\|Switch\|combobox\|dateRange" tests/prompts/campaign-list.md`
Expected: 8 이상 (SearchBar, Switch, combobox, dateRange 관련 언급)

- [ ] **Step 3: Commit**

```bash
git add tests/prompts/campaign-list.md
git commit -m "feat: campaign-list 프롬프트 재작성 (SearchBar, Switch 토글, ko-KR, 실무 스타일)"
```

---

### Task 10: 프롬프트 — campaign-form.md 재작성 (폼 통합)

**Files:**
- Modify: `tests/prompts/campaign-form.md`
- Delete: `tests/prompts/ad-group-form.md`

- [ ] **Step 1: campaign-form.md 전체 교체**

```markdown
---
page: campaign-form
template: PAGE-03
expected_ui:
  - card
  - button
  - input
  - textarea
  - select
  - field
  - popover
  - calendar
  - switch
  - radio-group
  - combobox
expected_composed: []
expected_lib:
  - formatDate
---

# 캠페인 생성 폼 페이지

마케팅팀에서 새 캠페인을 등록할 때 사용하는 폼 페이지입니다.
캠페인 기본 정보부터 예산, 타겟팅, 일정까지 한 화면에서 입력해야 합니다.
입력 필드가 많으므로 FieldSet으로 섹션을 나누어 구조화하세요.

## 요구사항

### 페이지 헤더
- Back 버튼 (캠페인 목록 `/campaigns`으로 이동)
- 제목: "캠페인 생성"

### 폼 구조 (단일 Card, react-hook-form + Controller)

#### Section 1 — 기본 정보 (FieldSet, FieldLegend: "기본 정보")
| 필드 | 타입 | 설명 |
|------|------|------|
| 캠페인명 | Input (required) | placeholder: "캠페인명을 입력하세요" |
| 광고주 | Combobox | 광고주 목록에서 검색 선택 (30개 이상 목 데이터, 타이핑 즉시 필터링) |
| 설명 | Textarea (optional) | placeholder: "캠페인 설명 (선택사항)" |

#### Section 2 — 캠페인 설정 (FieldSet, FieldLegend: "캠페인 설정")
| 필드 | 타입 | 설명 |
|------|------|------|
| 캠페인 목표 | RadioGroup | 브랜드 인지도, 전환, 트래픽 (3개 옵션) |
| 캠페인 유형 | Choice Card (RadioGroup + Field) | 검색 광고 / 디스플레이 광고 / 동영상 광고 (각각 제목+설명 포함) |
| 채널 | Select | Google Ads, Meta Ads, Naver SA, Kakao Moment |
| 자동 최적화 | Switch | "성과에 따라 입찰가를 자동으로 조정합니다" |

#### Section 3 — 예산 & 일정 (FieldSet, FieldLegend: "예산 & 일정")
| 필드 | 타입 | 설명 |
|------|------|------|
| 일일 예산 | Input (number, required) | FieldDescription: "일일 최대 지출 금액 (원)" |
| 시작일 | DatePicker (Popover + Calendar) | 2-column grid의 왼쪽 |
| 종료일 | DatePicker (Popover + Calendar) | 2-column grid의 오른쪽 |

- 시작일/종료일은 `grid grid-cols-1 gap-4 sm:grid-cols-2`로 배치
- 날짜 표시는 formatDate 사용 (date-fns 직접 사용 금지)

### CardFooter
- 취소 (variant="outline", type="button") + 저장 (type="submit")
- form id 연결 (`form="campaign-form"`)
- CardFooter에 `className="gap-2"`

### Validation (react-hook-form)
- 캠페인명: required ("캠페인명은 필수입니다")
- 일일 예산: required ("예산은 필수입니다"), min 1000 ("최소 1,000원 이상")
- Controller로 각 필드 연결, FieldError로 에러 표시
- data-invalid on Field, aria-invalid on Input

### 기타
- 로케일: ko-KR
- 날짜 포맷: YYYY-MM-DD (기본값)

## 출력
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
```

- [ ] **Step 2: ad-group-form.md 삭제**

```bash
rm tests/prompts/ad-group-form.md
```

- [ ] **Step 3: 변경 확인**

Run: `ls tests/prompts/`
Expected: campaign-dashboard.md, campaign-detail.md, campaign-form.md, campaign-list.md (4개)

Run: `grep -c "RadioGroup\|Choice Card\|Combobox\|Switch\|DatePicker" tests/prompts/campaign-form.md`
Expected: 8 이상

- [ ] **Step 4: Commit**

```bash
git add tests/prompts/campaign-form.md
git rm tests/prompts/ad-group-form.md
git commit -m "feat: campaign-form 프롬프트 재작성 + ad-group-form 병합 (RadioGroup, Choice Card, Combobox, ko-KR)"
```

---

### Task 11: 프롬프트 — campaign-detail.md 재작성

**Files:**
- Modify: `tests/prompts/campaign-detail.md`

- [ ] **Step 1: campaign-detail.md 전체 교체**

```markdown
---
page: campaign-detail
template: PAGE-02
expected_ui:
  - card
  - button
  - badge
  - chart
  - select
  - separator
  - tabs
expected_composed:
  - DataTable
  - KpiCard
expected_lib:
  - formatCurrencyCompact
  - formatCompact
  - formatDelta
  - formatCurrency
  - formatNumber
  - formatPercent
  - formatDate
---

# 캠페인 상세 페이지 생성

캠페인 운영자가 개별 캠페인의 성과를 분석하는 상세 페이지입니다.
상단에서 핵심 KPI를 빠르게 확인하고, 차트로 추이를 분석한 뒤, 하단에서 소속 광고그룹의 세부 성과를 Tabs로 전환하며 볼 수 있어야 합니다.

## 요구사항

### 페이지 헤더
- Back 버튼 (캠페인 목록 `/campaigns`으로 이동)
- 제목: "2026 봄 프로모션" (캠페인명, 목 데이터)
- 설명: "캠페인 상세 성과 분석"
- 우측에 상태 Badge (variant="outline", "활성")

### KPI 카드 (4개, 4-column grid)
아래 지표를 KpiCard로 표시합니다.

| 지표 | 값 (원본) | delta | footerText |
|------|----------|-------|------------|
| 총 지출 | 42,500,000원 | +15.2% | 전월 대비 |
| 노출수 | 3,280,000 | +22.1% | 전월 대비 |
| 클릭수 | 156,000 | -3.4% | 전월 대비 |
| 전환율 | 3.82% | +0.8% | 전월 대비 |

- 통화는 formatCurrencyCompact (만/억원)
- 수량은 formatCompact (만/억)
- delta는 formatDelta

### 캠페인 요약 (Mixed Card — CARD-05)
Card 하나에 캠페인 메타 정보를 요약합니다.

- CardHeader: "캠페인 정보"
- CardContent (space-y-4):
  - 상단 grid (grid-cols-2 gap-4): 상태(Badge), 채널(text), 시작일(formatDate), 종료일(formatDate)
  - Separator
  - 하단: 일일 예산(formatCurrency), 총 예산(formatCurrency), 광고주명(text)

### 차트 (2개, 2-column grid)

#### 일일 성과 추이 (LineChart)
- 최근 30일 데이터 (목 데이터 30건)
- 2개 시리즈: 지출, 전환수
- CardAction에 기간 Select: "최근 7일", "최근 30일", "최근 90일"
- chartConfig에서 색상 정의
- ChartTooltip + ChartTooltipContent, ChartLegend + ChartLegendContent 사용

#### 매체별 성과 비교 (BarChart)
- 채널별 지출/클릭/전환을 Grouped Bar로 표시
- 채널: Google Ads, Meta Ads, Naver SA
- chartConfig에서 chart-1~3 토큰 색상 사용

### 광고그룹 테이블 (Tabs로 상태별 전환)
Card 안에 Tabs를 배치하여 상태별 광고그룹을 전환합니다.

- CardHeader: "광고그룹" + CardDescription "이 캠페인에 속한 광고그룹"
- Tabs: "활성" (기본), "일시정지", "종료"
- 각 Tab의 DataTable 컬럼:
  - ID (pinned left, sortable)
  - 광고그룹명 (pinned left, sortable)
  - 상태 (Badge)
  - 노출수 (right-aligned, formatNumber)
  - 클릭수 (right-aligned, formatNumber)
  - CTR (right-aligned, formatPercent)
  - 지출 (right-aligned, formatCurrency)
  - CPA (right-aligned, formatCurrency)
- 각 탭에 5~8행 목 데이터
- onRowClick으로 `/ad-groups/${row.id}` 이동

### 기타
- 로케일: ko-KR, 통화: KRW
- KPI에는 compact 포맷, 테이블에는 exact 포맷
- 날짜는 formatDate (기본 형식)

## 출력
- Composed 컴포넌트(DataTable, KpiCard)가 없으면 `preview/src/components/composed/`에 생성하세요
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
```

- [ ] **Step 2: 변경 확인**

Run: `grep -c "Tabs\|Mixed Card\|Separator\|ChartLegend\|formatDate" tests/prompts/campaign-detail.md`
Expected: 8 이상

- [ ] **Step 3: Commit**

```bash
git add tests/prompts/campaign-detail.md
git commit -m "feat: campaign-detail 프롬프트 재작성 (Tabs, Mixed Card, ChartLegend, ko-KR, 실무 스타일)"
```

---

### Task 12: 최종 검증

**Files:**
- 모든 변경된 파일

- [ ] **Step 1: 프롬프트 파일 목록 확인**

Run: `ls -la tests/prompts/`
Expected: 정확히 4개 파일:
- campaign-dashboard.md
- campaign-detail.md
- campaign-form.md
- campaign-list.md

- [ ] **Step 2: 규칙 파일 정합성 확인**

Run: `grep -rn "FIELD-08\|FIELD-09\|RADIO-01" .claude/rules/`
Expected:
- fields.md에 FIELD-08, FIELD-09
- components.md에 RADIO-01

- [ ] **Step 3: 템플릿 파일 확인**

Run: `ls scripts/templates/composed/`
Expected: DataTable.tsx, KpiCard.tsx, SearchBar.tsx, index.ts

Run: `grep "SearchBar" scripts/templates/composed/index.ts`
Expected: `export { SearchBar } from "./SearchBar"`

- [ ] **Step 4: DataTable 변경 확인**

Run: `grep -n "bg-muted\|ArrowUpDown" scripts/templates/composed/DataTable.tsx`
Expected: bg-muted와 ArrowUpDown 모두 존재

- [ ] **Step 5: reset-preview.sh 확인**

Run: `grep "radio-group\|combobox" scripts/reset-preview.sh`
Expected: radio-group과 combobox이 shadcn 설치 목록에 포함

- [ ] **Step 6: 프롬프트 frontmatter 유효성**

각 프롬프트의 `expected_composed`가 사용하는 컴포넌트와 일치하는지 확인:

Run: `grep -A5 "expected_composed" tests/prompts/*.md`
Expected:
- campaign-dashboard: DataTable, KpiCard
- campaign-list: DataTable, SearchBar
- campaign-form: [] (빈 배열)
- campaign-detail: DataTable, KpiCard

- [ ] **Step 7: 교차 참조 확인**

fields.md의 FIELD-08/09가 components.md의 RADIO-01과 일관적인지 확인:

Run: `grep "FIELD-08\|FIELD-09" .claude/rules/components.md`
Expected: RADIO-01 섹션에서 FIELD-08, FIELD-09 참조

- [ ] **Step 8: Commit (필요시)**

모든 검증 통과 후 누락된 변경사항이 있으면 커밋.
