# Card Strategy & Rule System Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 3-tier Composed 전용 규칙 체계를 shadcn 직접 사용 + 최소 Composed 2-tier 모델로 재설계하고, Card/Field/DataTable 전략과 로케일 포맷 규칙을 반영한 규칙 문서와 샘플 코드를 갱신한다.

**Architecture:** 규칙 문서(.claude/rules/*.md)를 새 2-tier 모델에 맞게 재작성하고, CLAUDE.md 진입점을 갱신한 뒤, 4개 테스트 샘플(tests/samples/*.tsx)을 새 규칙에 맞게 재생성한다. 검증 스크립트로 샘플이 규칙을 위반하지 않는지 확인한다.

**Tech Stack:** Markdown (규칙 문서), TypeScript/TSX (샘플 코드), Bash (검증 스크립트)

---

## File Map

| Action | Path | Responsibility |
|--------|------|---------------|
| Rewrite | `.claude/rules/components.md` | 2-tier 모델, import 규칙, Composed 자격 기준 |
| Rewrite | `.claude/rules/cards.md` | Card 전략 (CARD-01~05), 컬럼 레이아웃, 금지 패턴 (신규 파일) |
| Rewrite | `.claude/rules/fields.md` | Field 전략 (FIELD-01~05), CardFooter 버튼 규칙 (신규 파일) |
| Rewrite | `.claude/rules/data-table.md` | DataTable 전략, 컬럼 규칙, Table vs DataTable 선택 기준 (신규 파일) |
| Rewrite | `.claude/rules/formatting.md` | 로케일별 숫자/통화 포맷 규칙 (신규 파일) |
| Rewrite | `.claude/rules/forbidden.md` | 금지 패턴을 새 체계에 맞게 갱신 |
| Rewrite | `.claude/rules/tokens.md` | 토큰 규칙 유지, Card 관련 예시 갱신 |
| Rewrite | `.claude/rules/page-templates.md` | 4개 페이지 템플릿을 새 체계로 재작성 |
| Rewrite | `.claude/rules/naming.md` | 2-tier에 맞게 네이밍 규칙 갱신 |
| Delete | `.claude/rules/component-interfaces.md` | Composed Props 정의 → DataTable/SearchBar/KpiCard만 남기고 data-table.md 등으로 분산 |
| Delete | `.claude/rules/forms.md` | fields.md로 대체 |
| Rewrite | `CLAUDE.md` | 진입점 — 새 규칙 파일 참조, Always Apply 갱신 |
| Rewrite | `tests/samples/campaign-list.tsx` | PAGE-01 샘플을 새 규칙으로 재생성 |
| Rewrite | `tests/samples/campaign-detail.tsx` | PAGE-02 샘플을 새 규칙으로 재생성 |
| Rewrite | `tests/samples/campaign-form.tsx` | PAGE-03 샘플을 새 규칙으로 재생성 |
| Rewrite | `tests/samples/dashboard-overview.tsx` | PAGE-04 샘플을 새 규칙으로 재생성 |
| Update | `scripts/check-rules.sh` | 검증 스크립트를 새 규칙에 맞게 갱신 |

---

## Task 1: Core Rule — components.md (2-Tier Model)

**Files:**
- Rewrite: `.claude/rules/components.md`

- [ ] **Step 1: Read current components.md**

Read `.claude/rules/components.md` to understand current structure.

- [ ] **Step 2: Rewrite components.md with 2-tier model**

Replace entire file with:

```markdown
# Component Rules

## 2-Tier Model

| Tier | Description | Import Path | Examples |
|------|-------------|-------------|---------|
| **shadcn** | shadcn/ui components used directly | `@/components/ui/*` | Card, Field, Button, Badge, Table, Dialog, Tabs, Select, Input, Textarea, Checkbox... |
| **Composed** | Domain logic encapsulated in composite components | `@/components/composed/*` | DataTable, SearchBar, KpiCard |

// WHY: shadcn components are well-documented, widely known, and directly usable.
// Composed components exist only when there is internal state logic or domain-specific combination.

## Import Convention

shadcn components — import from `@/components/ui/*`:
```tsx
import { Card, CardHeader, CardTitle, CardContent, CardFooter, CardAction, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Field, FieldLabel, FieldSet, FieldLegend, FieldGroup, FieldDescription, FieldError, FieldSeparator, FieldContent } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { Checkbox } from "@/components/ui/checkbox"
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table"
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs"
import { Dialog, DialogTrigger, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { AlertDialog, AlertDialogTrigger, AlertDialogContent, AlertDialogHeader, AlertDialogTitle, AlertDialogDescription, AlertDialogFooter, AlertDialogAction, AlertDialogCancel } from "@/components/ui/alert-dialog"
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from "@/components/ui/dropdown-menu"
import { Separator } from "@/components/ui/separator"
```

Composed components — barrel import from `@/components/composed`:
```tsx
import { DataTable, SearchBar, KpiCard } from "@/components/composed"
```

## Composed Qualification

A component qualifies as Composed if it meets ONE OR MORE of:

| Criterion | Description | Example |
|-----------|-------------|---------|
| Internal state logic | Sorting, pagination, filtering state management | DataTable (TanStack Table) |
| Domain-specific combination | Multiple shadcn components combined with domain rules | KpiCard (CardHeader + Badge + delta calculation) |
| Repeated pattern abstraction | Same structure repeated 3+ times | SearchBar (Input + Select + DatePicker filter assembly) |

Simple wrappers are NOT Composed:
```tsx
// NOT Composed — just wrapping
function FormCard({ title, children }) {
  return <Card><CardHeader><CardTitle>{title}</CardTitle></CardHeader>{children}</Card>
}

// Composed — has internal logic
function DataTable({ columns, data, pageSize, onSelectionChange }) {
  // TanStack Table instance, sorting state, pagination logic...
}
```
// WHY: Unnecessary wrappers add indirection without value. Use shadcn directly.

## Composed Component List

| Component | Role | Internal Logic |
|-----------|------|---------------|
| **DataTable** | Sortable/paginated/selectable/pinnable table | TanStack Table, state management |
| **SearchBar** | Composite filter assembly | Filter config → Input/Select/DatePicker dynamic rendering |
| **KpiCard** | KPI metric card | Delta sign detection, Badge variant auto-selection |

For DataTable interface: @.claude/rules/data-table.md
For Card usage rules: @.claude/rules/cards.md
For Field usage rules: @.claude/rules/fields.md

## Escape Hatch

Need a new Composed component?
1. STOP — check if shadcn components can do it directly
2. Verify it meets the Composed qualification criteria above
3. Describe the component and ask for approval
4. After approval, create in `@/components/composed/` with typed props
5. Export from `@/components/composed/index.ts`
```

- [ ] **Step 3: Verify file is well-formed**

Read the file back and check for markdown syntax issues.

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/components.md
git commit -m "refactor(rules): rewrite components.md for 2-tier model (shadcn direct + minimal Composed)"
```

---

## Task 2: Card Strategy Rule — cards.md (New File)

**Files:**
- Create: `.claude/rules/cards.md`

- [ ] **Step 1: Create cards.md**

Write `.claude/rules/cards.md` with the full Card strategy from the design spec (Section 2). Include:
- 3 principles (Card = section container, no double wrapping, unified internal structure)
- CARD-01 through CARD-05 patterns with code examples
- Column layout rules table (KPI 4-col, Chart 2-col, Chart asymmetric, Form 1-col, Form 2-col)
- Forbidden patterns (double wrapping, no CardHeader, no Card for dashboard sections)
- Escape hatch

Content source: `docs/superpowers/specs/2026-03-27-card-strategy-design.md` Section 2.

- [ ] **Step 2: Verify file**

Read the file back. Check all code examples have correct JSX syntax and use token-based classes.

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/cards.md
git commit -m "feat(rules): add cards.md — Card strategy with CARD-01~05 patterns"
```

---

## Task 3: Field Strategy Rule — fields.md (New File)

**Files:**
- Create: `.claude/rules/fields.md`

- [ ] **Step 1: Create fields.md**

Write `.claude/rules/fields.md` with the full Field strategy from the design spec (Section 3). Include:
- 3 principles (shadcn Field system, Card + Field combination, Controller integration)
- Field component hierarchy diagram
- FIELD-01 through FIELD-05 patterns with code examples
- CardFooter button rules (Cancel outline before Submit, form id linking)
- Forbidden patterns (no Card-less form, no label-less Input, no bare Input, no Card-per-section splitting)
- Exception for search/filter Input

Content source: `docs/superpowers/specs/2026-03-27-card-strategy-design.md` Section 3.

- [ ] **Step 2: Verify file**

Read the file back. Check all code examples have correct JSX syntax.

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/fields.md
git commit -m "feat(rules): add fields.md — Field strategy with FIELD-01~05 patterns"
```

---

## Task 4: DataTable Strategy Rule — data-table.md (New File)

**Files:**
- Create: `.claude/rules/data-table.md`

- [ ] **Step 1: Create data-table.md**

Write `.claude/rules/data-table.md` with the full DataTable strategy from the design spec (Section 4). Include:
- 3 principles (DataTable = Composed, Table = shadcn direct, always in Card)
- Table vs DataTable selection flowchart
- DataTableColumn and DataTableProps interfaces
- Standard column order rules table (checkbox → ID → title → attributes → metrics → actions)
- Column pinning rules (1~3 sticky)
- Built-in features table (sorting, pinning, pagination, row selection)
- TABLE-05 full column example with all column types
- TABLE-01 through TABLE-04 Card combination patterns (reference cards.md CARD-03a~d)
- Forbidden patterns
- Cell rendering rules (token-based classes only)

Content source: `docs/superpowers/specs/2026-03-27-card-strategy-design.md` Section 4.

- [ ] **Step 2: Verify file**

Read the file back. Check DataTableColumn interface matches TABLE-05 example usage.

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/data-table.md
git commit -m "feat(rules): add data-table.md — DataTable strategy with column rules and TABLE patterns"
```

---

## Task 5: Formatting Rule — formatting.md (New File)

**Files:**
- Create: `.claude/rules/formatting.md`

- [ ] **Step 1: Create formatting.md**

Write `.claude/rules/formatting.md` with locale-based format rules from the design spec (Section 0). Include:
- Principles (locale-based formatting, KPI compact vs table exact, utility functions)
- ko-KR rules table (원 suffix, 만/억 abbreviation, no decimals)
- ko-KR abbreviation scale (10,000 → 1만, 120,000,000 → 1.2억)
- en-US rules table ($ prefix, K/M/B abbreviation, decimals allowed)
- Format utility function interface (formatCompact, formatCurrencyCompact, formatNumber, formatCurrency, formatPercent, formatDelta)
- Context-by-context application table (KPI Card, KPI delta, table cell money, table cell quantity, table cell ratio)

Content source: `docs/superpowers/specs/2026-03-27-card-strategy-design.md` Section 0.

- [ ] **Step 2: Verify file**

Read the file back. Verify ko-KR and en-US examples are consistent with the utility function signatures.

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/formatting.md
git commit -m "feat(rules): add formatting.md — locale-based number/currency format rules (ko-KR, en-US)"
```

---

## Task 6: Update forbidden.md

**Files:**
- Rewrite: `.claude/rules/forbidden.md`

- [ ] **Step 1: Read current forbidden.md**

Read `.claude/rules/forbidden.md` to understand current 5 patterns.

- [ ] **Step 2: Rewrite forbidden.md for new system**

Update the 5 forbidden patterns to align with the new 2-tier model:

| Pattern | Change |
|---------|--------|
| FORB-01 (No inline styles) | Keep as-is. Exception for library props with tokens stays. |
| FORB-02 (No hardcoded colors) | Keep as-is. |
| FORB-03 (No raw div/span layout) | **Relax** — `div` with grid/flex classes is now allowed for page layout (page header, grid wrappers). Raw `div` is only forbidden as a **substitute for Card** in dashboard sections. Update examples. |
| FORB-04 (No direct shadcn imports) | **Remove entirely** — shadcn direct import is now the default. Replace with: "No unnecessary Composed wrappers — don't create wrappers that just pass through to shadcn components." |
| FORB-05 (No bare Input outside FormField) | **Update** — Change from "FormField" to "Field". Bare Input outside `<Field>` is forbidden. Keep exception for search/filter toolbar inputs. |

Add new forbidden pattern:
| FORB-06 (No Card double wrapping) | Card 안에 Card를 넣지 않는다. |

- [ ] **Step 3: Verify file**

Read the file back. Ensure all FORBIDDEN/CORRECT examples use the new import style and component names.

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/forbidden.md
git commit -m "refactor(rules): update forbidden.md for 2-tier model — relax div/import rules, add Card double-wrap ban"
```

---

## Task 7: Update tokens.md

**Files:**
- Rewrite: `.claude/rules/tokens.md`

- [ ] **Step 1: Read current tokens.md**

Read `.claude/rules/tokens.md`.

- [ ] **Step 2: Update tokens.md**

Changes needed:
- Replace all `@/components/composed` references with shadcn direct imports in examples
- Update Chart & Library Props section to reference `CardContent` instead of `ChartSection`
- Keep all token rules unchanged (they are system-agnostic)
- Update cross-references: `forbidden.md (FORB-02)` stays, add references to `cards.md` for Card styling

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/tokens.md
git commit -m "refactor(rules): update tokens.md examples for 2-tier model"
```

---

## Task 8: Rewrite page-templates.md

**Files:**
- Rewrite: `.claude/rules/page-templates.md`

- [ ] **Step 1: Read current page-templates.md**

Read `.claude/rules/page-templates.md`.

- [ ] **Step 2: Rewrite all 4 page templates**

Replace PAGE-01 through PAGE-04 with the new templates from design spec Section 5:
- PAGE-01 (List): Page header (div) + Card > DataTable with inline filter
- PAGE-02 (Detail): Page header with back + KpiCard grid + Chart Cards grid + Table Card
- PAGE-03 (Form): Page header with back + Card > form with FieldGroup/FieldSet + CardFooter buttons
- PAGE-04 (Dashboard): Page header + KpiCard 4-col grid + Chart 2-col grid + Table Card

Add page structure rules table at top.

Cross-references: `cards.md`, `fields.md`, `data-table.md`, `formatting.md`

- [ ] **Step 3: Verify file**

Read the file back. Ensure every template uses only shadcn imports + DataTable/SearchBar/KpiCard from Composed.

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/page-templates.md
git commit -m "refactor(rules): rewrite page-templates.md with Card/Field/DataTable patterns"
```

---

## Task 9: Update naming.md

**Files:**
- Rewrite: `.claude/rules/naming.md`

- [ ] **Step 1: Read current naming.md**

Read `.claude/rules/naming.md`.

- [ ] **Step 2: Update for 2-tier model**

Changes:
- NAME-02: Remove references to 12 Composed components. Update to list only DataTable, SearchBar, KpiCard.
- NAME-02: Remove "FormNoun" and "ActionNoun" naming patterns (those are now shadcn components)
- Directory structure: Remove `ui/` "DO NOT edit or import" note. Update `composed/` to list only 3 components.
- Keep file naming conventions (kebab-case pages, PascalCase components, etc.)
- Add `lib/` directory for utility functions (formatters)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/naming.md
git commit -m "refactor(rules): update naming.md for 2-tier model with minimal Composed list"
```

---

## Task 10: Delete obsolete rule files

**Files:**
- Delete: `.claude/rules/component-interfaces.md`
- Delete: `.claude/rules/forms.md`

- [ ] **Step 1: Delete component-interfaces.md**

This file defined Props for 12 Composed components. With the 2-tier model, only DataTable/SearchBar/KpiCard remain as Composed, and their interfaces are defined in `data-table.md`.

```bash
git rm .claude/rules/component-interfaces.md
```

- [ ] **Step 2: Delete forms.md**

Replaced by `fields.md` which uses shadcn Field system.

```bash
git rm .claude/rules/forms.md
```

- [ ] **Step 3: Commit**

```bash
git commit -m "refactor(rules): remove component-interfaces.md and forms.md — replaced by data-table.md and fields.md"
```

---

## Task 11: Rewrite CLAUDE.md entry point

**Files:**
- Rewrite: `CLAUDE.md`

- [ ] **Step 1: Read current CLAUDE.md**

Read `CLAUDE.md`.

- [ ] **Step 2: Rewrite CLAUDE.md**

Replace entire file with:

```markdown
# Dashboard Rules

This project uses shadcn/ui directly with a 2-tier component model:
- **shadcn tier**: Use shadcn/ui components directly (`@/components/ui/*`)
- **Composed tier**: Domain-specific components with internal logic (`@/components/composed/*` — DataTable, SearchBar, KpiCard only)

Follow these rules for every file you touch.

@.claude/rules/components.md
@.claude/rules/cards.md
@.claude/rules/fields.md
@.claude/rules/data-table.md
@.claude/rules/formatting.md
@.claude/rules/tokens.md
@.claude/rules/forbidden.md
@.claude/rules/naming.md
@.claude/rules/page-templates.md

## Always Apply

- **Imports**: Use shadcn components directly from `@/components/ui/*`. Use `@/components/composed/` only for DataTable, SearchBar, KpiCard.
  // WHY: shadcn components are the standard. Composed is only for domain logic that can't be expressed with direct shadcn usage.

- **Card wrapping**: Every independent dashboard section (chart, table, form) MUST be wrapped in a Card. No Card double-wrapping. See `cards.md`.
  // WHY: Card provides visual consistency across all sections. Double-wrapping breaks spacing.

- **Field system**: All form inputs MUST be inside a `<Field>` with `<FieldLabel>`. Form buttons go in `<CardFooter>`. See `fields.md`.
  // WHY: Field provides accessible labels and validation state. CardFooter gives consistent button placement.

- **Tokens**: Use CSS custom property tokens for ALL color, spacing, and radius values. Never hardcode hex, rgb, or oklch literals.
  // WHY: Hardcoded values break theming and make dark mode impossible to maintain.

- **No inline styles**: Never use `style={{}}` on any element. Exception: third-party library API props (e.g., Recharts Tooltip contentStyle) — but values MUST still be CSS custom property tokens.
  // WHY: Inline styles bypass the token system and are impossible to audit automatically.

- **Formatting**: Use locale-aware format utility functions for all numbers, currency, and percentages. See `formatting.md`.
  // WHY: Consistent number formatting across KPI cards and tables. Supports multi-locale (ko-KR, en-US).

- **Rule files**: When in doubt about what is allowed, read the specific rule file. Do not infer — look it up.
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "refactor: rewrite CLAUDE.md for 2-tier model with Card/Field/DataTable/Formatting rules"
```

---

## Task 12: Rewrite sample — campaign-list.tsx (PAGE-01)

**Files:**
- Rewrite: `tests/samples/campaign-list.tsx`

- [ ] **Step 1: Read current campaign-list.tsx**

Read `tests/samples/campaign-list.tsx` for reference.

- [ ] **Step 2: Rewrite with new rules**

Replace entire file. Key changes from old version:
- Import shadcn components directly (Card, Button, Badge, Input, Select, etc.)
- Import DataTable from `@/components/composed`
- Wrap page in `div.flex.flex-col.gap-6.p-6` (not PageLayout)
- Page header is `div` + `h1` + `p` + `Button` (not PageHeader)
- DataTable inside `Card > CardContent` (not standalone)
- Inline filter toolbar in CardContent above DataTable
- Use `formatCurrency`, `formatNumber` from `@/lib/format` for mock data
- Column definitions use new DataTableColumn interface (accessorKey, pinned, align, cell)
- Standard column order: checkbox → ID → name → status → metrics → actions

```tsx
// Sample: List Page — PAGE-01
// Rules applied: components.md, cards.md, data-table.md, formatting.md,
//                tokens.md, forbidden.md, naming.md, page-templates.md

import {
  Card, CardHeader, CardTitle, CardDescription, CardContent, CardAction,
} from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import {
  Select, SelectTrigger, SelectValue, SelectContent, SelectItem,
} from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import {
  DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem,
} from "@/components/ui/dropdown-menu"
import { DataTable } from "@/components/composed"
import type { DataTableColumn } from "@/components/composed"
import { formatCurrency, formatNumber } from "@/lib/format"
import { MoreHorizontalIcon } from "lucide-react"

type Campaign = {
  id: string
  name: string
  status: "active" | "paused" | "ended" | "draft"
  channel: string
  impressions: number
  clicks: number
  ctr: number
  spend: number
  cpa: number
}

const mockCampaigns: Campaign[] = [
  { id: "1001", name: "Summer Promo 2026", status: "active", channel: "Search", impressions: 120000, clicks: 3400, ctr: 0.0283, spend: 4320000, cpa: 1270 },
  { id: "1002", name: "Brand Awareness Q2", status: "active", channel: "Display", impressions: 98000, clicks: 1800, ctr: 0.0184, spend: 2100000, cpa: 1167 },
  { id: "1003", name: "Retargeting - Spring", status: "paused", channel: "Social", impressions: 75000, clicks: 2200, ctr: 0.0293, spend: 3800000, cpa: 1727 },
  { id: "1004", name: "Product Launch X", status: "ended", channel: "Video", impressions: 310000, clicks: 9100, ctr: 0.0294, spend: 15000000, cpa: 1648 },
]

const locale = "ko-KR"
const currency = "KRW"

const columns: DataTableColumn<Campaign>[] = [
  {
    id: "select",
    header: ({ table }) => (
      <Checkbox
        checked={table.getIsAllPageRowsSelected()}
        onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
        aria-label="Select all"
      />
    ),
    cell: ({ row }) => (
      <Checkbox
        checked={row.getIsSelected()}
        onCheckedChange={(value) => row.toggleSelected(!!value)}
        aria-label="Select row"
      />
    ),
    enableSorting: false,
    pinned: "left",
  },
  {
    accessorKey: "id",
    header: "ID",
    sortable: true,
    pinned: "left",
    cell: (row) => <span className="font-medium text-muted-foreground">{row.id}</span>,
  },
  {
    accessorKey: "name",
    header: "Campaign Name",
    sortable: true,
    pinned: "left",
    cell: (row) => <span className="font-medium text-foreground">{row.name}</span>,
  },
  {
    accessorKey: "status",
    header: "Status",
    sortable: true,
    cell: (row) => <Badge variant="outline">{row.status}</Badge>,
  },
  {
    accessorKey: "channel",
    header: "Channel",
    sortable: true,
  },
  {
    accessorKey: "impressions",
    header: "Impressions",
    sortable: true,
    align: "right",
    cell: (row) => <span className="tabular-nums">{formatNumber(row.impressions, { locale })}</span>,
  },
  {
    accessorKey: "clicks",
    header: "Clicks",
    sortable: true,
    align: "right",
    cell: (row) => <span className="tabular-nums">{formatNumber(row.clicks, { locale })}</span>,
  },
  {
    accessorKey: "ctr",
    header: "CTR",
    sortable: true,
    align: "right",
    cell: (row) => <span className="tabular-nums">{(row.ctr * 100).toFixed(2)}%</span>,
  },
  {
    accessorKey: "spend",
    header: "Spend",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="font-medium tabular-nums">{formatCurrency(row.spend, { locale, currency })}</span>
    ),
  },
  {
    accessorKey: "cpa",
    header: "CPA",
    sortable: true,
    align: "right",
    cell: (row) => <span className="tabular-nums">{formatCurrency(row.cpa, { locale, currency })}</span>,
  },
  {
    id: "actions",
    header: "",
    enableSorting: false,
    cell: (row) => (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon"><MoreHorizontalIcon className="size-4" /></Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem>Edit</DropdownMenuItem>
          <DropdownMenuItem>Duplicate</DropdownMenuItem>
          <DropdownMenuItem className="text-destructive">Delete</DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  },
]

export default function CampaignListPage() {
  const handleRowClick = (row: Campaign) => {
    console.log("Navigate to campaign:", row.id)
  }

  return (
    <div className="flex flex-col gap-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Campaigns</h1>
          <p className="text-sm text-muted-foreground">Manage your campaigns</p>
        </div>
        <Button>New Campaign</Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Campaigns</CardTitle>
          <CardDescription>{mockCampaigns.length} campaigns</CardDescription>
          <CardAction>
            <Button variant="outline" size="sm">Export</Button>
          </CardAction>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2 pb-4">
            <Input placeholder="Filter by name..." className="max-w-sm" />
            <Select>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="paused">Paused</SelectItem>
                <SelectItem value="ended">Ended</SelectItem>
                <SelectItem value="draft">Draft</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <DataTable
            columns={columns}
            data={mockCampaigns}
            onRowClick={handleRowClick}
            emptyMessage="No campaigns found."
          />
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
git add tests/samples/campaign-list.tsx
git commit -m "refactor(samples): rewrite campaign-list.tsx with Card/DataTable/shadcn direct imports"
```

---

## Task 13: Rewrite sample — dashboard-overview.tsx (PAGE-04)

**Files:**
- Rewrite: `tests/samples/dashboard-overview.tsx`

- [ ] **Step 1: Rewrite with new rules**

Key changes:
- Import shadcn Card, Button, Badge directly
- Import KpiCard, DataTable from Composed
- Use ChartContainer from shadcn (not ChartSection Composed)
- Chart wrapped in Card > CardHeader + CardContent (CARD-02 pattern)
- KpiCard in 4-col grid
- Use format utility functions for KPI values
- Recharts still uses token vars (var(--chart-1), var(--border), etc.)

Write the full file following PAGE-04 template from design spec.

- [ ] **Step 2: Commit**

```bash
git add tests/samples/dashboard-overview.tsx
git commit -m "refactor(samples): rewrite dashboard-overview.tsx with Card/KpiCard/shadcn direct imports"
```

---

## Task 14: Rewrite sample — campaign-detail.tsx (PAGE-02)

**Files:**
- Rewrite: `tests/samples/campaign-detail.tsx`

- [ ] **Step 1: Rewrite with new rules**

Key changes:
- Page header with back button (Button ghost + ArrowLeftIcon) and Badge
- KpiCard in 4-col grid with formatCurrencyCompact
- Chart in Card > CardHeader + CardContent (not ChartSection)
- DataTable in Card > CardContent
- All shadcn direct imports

Write the full file following PAGE-02 template from design spec.

- [ ] **Step 2: Commit**

```bash
git add tests/samples/campaign-detail.tsx
git commit -m "refactor(samples): rewrite campaign-detail.tsx with Card/KpiCard/shadcn direct imports"
```

---

## Task 15: Rewrite sample — campaign-form.tsx (PAGE-03)

**Files:**
- Rewrite: `tests/samples/campaign-form.tsx`

- [ ] **Step 1: Rewrite with new rules**

Key changes:
- Import Field, FieldLabel, FieldSet, FieldLegend, FieldGroup, FieldSeparator from shadcn
- Import Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter from shadcn
- Form inside Card > CardContent, buttons in CardFooter
- FieldSet for "Basic Info" and "Budget & Schedule" sections
- FieldSeparator between sections
- 2-col grid with div for side-by-side fields
- form id + Button form attribute linking
- Cancel (outline) before Save in CardFooter

Write the full file following PAGE-03 template from design spec.

- [ ] **Step 2: Commit**

```bash
git add tests/samples/campaign-form.tsx
git commit -m "refactor(samples): rewrite campaign-form.tsx with Card/Field/shadcn direct imports"
```

---

## Task 16: Update check-rules.sh

**Files:**
- Update: `scripts/check-rules.sh`

- [ ] **Step 1: Read current check-rules.sh**

Read `scripts/check-rules.sh`.

- [ ] **Step 2: Update validation rules**

Update grep patterns:
- Remove: check for `@/components/ui/` imports (now allowed)
- Remove: check for PageLayout, PageHeader, FormFieldSet, etc. (no longer required)
- Add: check for Card double-wrapping pattern (Card inside CardContent)
- Add: check for bare Input outside Field
- Add: check for hardcoded color values (keep existing)
- Add: check for inline style={{}} (keep existing)
- Add: check for CardHeader presence in every Card usage
- Keep: check for hardcoded hex/rgb/oklch values

- [ ] **Step 3: Run script against samples**

```bash
bash scripts/check-rules.sh tests/samples/
```

Expected: All 4 samples pass with no violations.

- [ ] **Step 4: Commit**

```bash
git add scripts/check-rules.sh
git commit -m "refactor(scripts): update check-rules.sh for 2-tier model validation"
```

---

## Task 17: Final Verification

- [ ] **Step 1: Run check-rules.sh against all samples**

```bash
bash scripts/check-rules.sh tests/samples/
```

Expected: 0 violations across all 4 samples.

- [ ] **Step 2: Verify all rule file cross-references are valid**

Check that every `@.claude/rules/*.md` reference in CLAUDE.md and within rule files points to an existing file:

```bash
grep -roh '@\.claude/rules/[a-z-]*\.md' .claude/rules/ CLAUDE.md | sort -u | while read ref; do
  file="${ref#@}"
  [ -f "$file" ] || echo "BROKEN: $ref"
done
```

Expected: No "BROKEN" output.

- [ ] **Step 3: Verify deleted files are gone**

```bash
ls .claude/rules/component-interfaces.md .claude/rules/forms.md 2>&1
```

Expected: "No such file or directory" for both.

- [ ] **Step 4: List final rule files**

```bash
ls -la .claude/rules/
```

Expected files:
- cards.md (new)
- components.md (rewritten)
- data-table.md (new)
- fields.md (new)
- forbidden.md (updated)
- formatting.md (new)
- naming.md (updated)
- page-templates.md (rewritten)
- tokens.md (updated)
