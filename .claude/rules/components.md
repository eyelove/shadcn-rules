---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
  - "resources/js/**/*.tsx"
---

# Component Rules

## Tier Model

Two tiers. Use shadcn directly for standard UI. Use Composed only when a component meets qualification criteria.

| Tier | Import Path | What Lives Here | Examples |
|------|------------|-----------------|----------|
| **shadcn** | `@/components/ui/*` | Official shadcn/ui primitives. Import and use directly. | Card, Button, Badge, Input, Select, Dialog, Tabs |
| **Composed** | `@/components/composed/` | Project-specific wrappers that encode internal state, domain logic, or repeated multi-component patterns. | DataTable, SearchBar, KpiCard |

// WHY: The old 3-tier model banned all shadcn imports, forcing every UI element through a wrapper.
// Most wrappers added no logic — just forwarded props. Direct shadcn use eliminates that overhead.
// Composed exists only when a component genuinely earns its abstraction.

## Import Convention

### shadcn — direct imports

```tsx
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Checkbox } from "@/components/ui/checkbox"
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from "@/components/ui/table"
import { Dialog, DialogTrigger, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { AlertDialog, AlertDialogTrigger, AlertDialogContent, AlertDialogHeader, AlertDialogTitle, AlertDialogDescription, AlertDialogFooter, AlertDialogAction, AlertDialogCancel } from "@/components/ui/alert-dialog"
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs"
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from "@/components/ui/dropdown-menu"
import { Separator } from "@/components/ui/separator"
import { Label } from "@/components/ui/label"
import { Popover, PopoverTrigger, PopoverContent } from "@/components/ui/popover"
import { Calendar } from "@/components/ui/calendar"
import { Combobox, ComboboxInput, ComboboxContent, ComboboxList, ComboboxItem, ComboboxEmpty } from "@/components/ui/combobox"
import { Switch } from "@/components/ui/switch"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
```

// WHY: shadcn components are well-documented, tree-shakeable, and accessible by default.
// Wrapping them without adding logic creates indirection with no benefit.

### Composed — barrel import

```tsx
import { DataTable, SearchBar, KpiCard } from "@/components/composed"
```

// WHY: Barrel import keeps Composed components discoverable. All Composed components MUST be
// exported from `@/components/composed/index.ts`.

## Composed Qualification

A component belongs in Composed ONLY if it meets at least one of these criteria:

### 1. Internal state logic
The component manages its own state (sorting, filtering, pagination) that callers should not handle.

```tsx
// IS Composed — DataTable manages sort state, pagination, and column visibility internally
<DataTable columns={columns} data={rows} onRowClick={handleClick} />

// IS NOT Composed — a Card with static content has no internal state
<Card><CardHeader><CardTitle>Revenue</CardTitle></CardHeader>
  <CardContent>$42,000</CardContent></Card>
```

### 2. Domain-specific combination
The component combines multiple primitives into a pattern that encodes domain rules.

```tsx
// IS Composed — KpiCard combines Card + delta formatting + positive/negative color logic
<KpiCard label="Total Spend" value="$12,400" delta="+8%" deltaPositive />

// IS NOT Composed — a Button with an icon is just standard shadcn usage
<Button variant="outline"><PlusIcon className="mr-2 h-4 w-4" />New Campaign</Button>
```

### 3. Repeated pattern abstraction
The same multi-component arrangement appears 3+ times across pages with identical structure.

```tsx
// IS Composed — SearchBar encodes filter config -> form fields -> submit pattern
<SearchBar filters={filterConfig} onSearch={handleSearch} />

// IS NOT Composed — a one-off form section used on a single page
<div className="flex gap-4"><Input placeholder="Search..." /><Button>Go</Button></div>
```

// WHY: These criteria prevent premature abstraction. If a pattern does not manage state,
// encode domain rules, or repeat across pages, it should stay as direct shadcn usage.

## Composed Component List

| Component | Role | Internal Logic |
|-----------|------|---------------|
| **DataTable** | Sortable, paginated, clickable data table | Sort state, pagination, column visibility, empty state, loading state |
| **SearchBar** | Configurable filter bar with multiple input types | Filter state management, debounced search, config-driven field rendering |
| **KpiCard** | Metric card with label, value, and delta | Delta formatting, positive/negative color selection via tokens |

For detailed Props contracts and usage examples, see:
- @.claude/rules/data-table.md — DataTable columns, actions, render functions
- @.claude/rules/cards.md — KpiCard props, delta formatting, grid layout
- @.claude/rules/cards.md — SearchBar usage in CARD-03b filter toolbar
- @.claude/rules/fields.md — form field patterns with shadcn primitives

## Input Component Selection

대시보드에서 사용하는 입력 컴포넌트 선택 기준. 맥락에 따라 하나만 선택한다.

### SELECT-01 — Select vs Combobox

```
옵션이 고정이고 ~10개 이하?
  ├─ Yes → Select (Radix)
  └─ No
      └─ 옵션이 많거나 서버에서 로드?
          └─ Yes → Combobox (검색 가능)
```

| 기준 | Select | Combobox |
|------|--------|----------|
| 옵션 수 | ~10개 이하, 고정 목록 | 10개 이상 또는 동적/Ajax |
| 검색 | 없음 | 타이핑 즉시 필터링 |
| 다중 선택 | 미지원 | `multiple` prop 지원 |
| 대시보드 사용처 | 상태 필터, 차트 기간(7d/30d), 카테고리 | 캠페인 선택, 광고주 검색, 매체 선택 |
| 배치 위치 | CardAction, 필터 바, 폼 Field | 필터 바, 폼 Field |

// WHY: 옵션이 적으면 Select가 간결하고 빠르다. 옵션이 많으면 검색 없이는 사용 불가능하므로 Combobox.
// Native `<select>`는 대시보드에서 사용하지 않는다 — 토큰 시스템 적용 불가, 테마 불일치.

### DATE-01 — Date Picker 선택

대시보드에서 Calendar 인라인은 사용하지 않는다. 항상 Popover 안에 넣어 공간을 절약한다.

```
단일 날짜 선택? (폼 필드)
  └─ Popover + Calendar mode="single"

날짜 범위 + 프리셋? (차트/리포트 필터)
  └─ Popover + Select(프리셋) + Calendar mode="range" numberOfMonths={2}
```

| 시나리오 | 구성 | 배치 위치 |
|---------|------|---------|
| 폼 날짜 입력 | `Popover` + `Calendar mode="single"` | `Field` in PAGE-03 |
| 차트/리포트 기간 필터 | `Popover` + `Select`(프리셋) + `Calendar mode="range"` | `CardAction` in CARD-02, 페이지 헤더 |

// WHY: Calendar 인라인은 예약 시스템처럼 달력이 항상 보여야 하는 경우에만 적합하다.
// 대시보드에서는 공간 효율을 위해 Popover 트리거로 숨긴다.

폼 필드에서의 Date Picker, Combobox 코드 패턴: @.claude/rules/fields.md FIELD-06, FIELD-07
차트 필터에서의 Date Range Picker 패턴: @.claude/rules/cards.md CARD-02

### RADIO-01 — RadioGroup vs Select vs Choice Card

```
옵션이 2~5개이고 상호 배타적?
  ├─ 라벨만으로 충분? → RadioGroup (FIELD-08)
  └─ 각 옵션에 제목+설명 필요? → Choice Card (FIELD-09)

옵션이 ~10개 이하, 고정? → Select
옵션이 10개 이상? → Combobox
```

| 기준 | RadioGroup | Choice Card | Select |
|------|-----------|-------------|--------|
| 옵션 수 | 2~5개 | 2~5개 | ~10개 이하 |
| 옵션 설명 | 불필요 | 제목+설명 필요 | 불필요 |
| 시각적 크기 | 컴팩트 | 카드 크기 | 드롭다운 |
| 대시보드 사용처 | 캠페인 목표, 입찰 전략 | 요금제, 캠페인 유형 | 상태, 지역, 기간 |

// WHY: 옵션이 적고 한눈에 보여야 하면 RadioGroup. 설명이 필요하면 Choice Card.
// 옵션이 많아지면 화면을 차지하므로 Select/Combobox로 전환한다.

## Cell Functions in DataTable

When using `cell` in DataTable columns, you MAY use `<span>` with token-based Tailwind classes:
```tsx
// ALLOWED — token-based text styling in cell functions
cell: (row) => <span className="font-medium text-foreground">{row.name}</span>
cell: (row) => <Badge variant="outline">{row.status}</Badge>

// FORBIDDEN — hardcoded colors or inline styles in cell functions
cell: (row) => <span style={{ color: "red" }}>{row.status}</span>
cell: (row) => <span className="text-red-500">{row.status}</span>
```
// WHY: DataTable cell functions need lightweight formatting. Token classes keep consistency.

## Chart Library Usage

Charts use shadcn's chart components from `@/components/ui/chart`:
- `ChartContainer` — responsive wrapper (MUST have `min-h-[VALUE]` or `aspect-*`)
- `ChartTooltip` + `ChartTooltipContent` — themed tooltip
- `ChartLegend` + `ChartLegendContent` — themed legend

Recharts primitives (`BarChart`, `LineChart`, `CartesianGrid`, `XAxis`, `YAxis`, etc.) are imported directly from `recharts`.

Full chart pattern with code examples, chartConfig usage, and forbidden patterns: @.claude/rules/cards.md CARD-02

## Escape Hatch

Need a new Composed component?
1. Verify it meets at least one Composed Qualification criterion above
2. Describe the component, its internal logic, and why direct shadcn usage is insufficient
3. Wait for approval before creating
4. After approval, create it in `@/components/composed/` with a typed props interface
5. Export it from `@/components/composed/index.ts`
6. NEVER add `className` to a Composed component's public props

// WHY: Composed components are high-trust abstractions. Each one adds API surface that every
// consumer must learn. The approval gate prevents premature or redundant abstractions.

For token rules, see: @.claude/rules/tokens.md
For forbidden patterns, see: @.claude/rules/forbidden.md
