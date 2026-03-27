---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
  - "resources/js/**/*.tsx"
---

# DataTable Strategy

DataTable is a Composed component wrapping TanStack Table. This file defines when to use it, its interface, column conventions, and forbidden patterns.

## Principles

1. **DataTable** (`@/components/composed/DataTable`): Composed component built on TanStack Table. Handles sorting, filtering, pagination, row selection internally. Use for dynamic, interactive tabular data.
2. **Table** (`@/components/ui/table`): shadcn primitive. Use ONLY for small, static data (< 20 rows) with no sorting or filtering needs.
3. **Always inside Card**: Both DataTable and Table MUST be rendered inside `Card > CardContent`. DataTable itself is Card-free — the Card wrapper lives in the page file.

// WHY: TanStack Table adds ~15 KB but provides sorting, pagination, and selection out of the box.
// Forcing everything through DataTable for small static lists is wasteful. The Card wrapper rule
// keeps visual consistency without baking Card into the component (composability over coupling).

## TABLE-00 — Selection Flowchart

```
Data > 20 rows? ──yes──> DataTable (Composed)
       │
       no
       │
       v
Sorting/filtering needed? ──yes──> DataTable (Composed)
       │
       no
       │
       v
Table (shadcn direct)
```

// WHY: This binary decision prevents over-engineering small tables and under-engineering large ones.

## TABLE-01 — DataTable Props Interface

```tsx
interface DataTableColumn<T> {
  accessorKey?: keyof T
  id?: string                                    // for checkbox, actions columns without data key
  header: string | (({ table }) => ReactNode)    // string or custom (checkbox header)
  sortable?: boolean                             // default: false
  pinned?: "left" | "right"                      // column pinning
  align?: "left" | "center" | "right"            // default: "left"
  cell?: (row: T) => React.ReactNode
  enableSorting?: boolean                        // false disables sorting (checkbox, actions)
}

interface DataTableProps<T> {
  columns: DataTableColumn<T>[]
  data: T[]
  onRowClick?: (row: T) => void
  onSelectionChange?: (rows: T[]) => void        // checkbox selection callback
  pageSize?: number                              // default: 10
  searchable?: boolean
  searchPlaceholder?: string
  emptyMessage?: string
}
```

// WHY: The Props interface encodes all interactive features (sorting, selection, pagination)
// so page files never need to import TanStack Table primitives directly.

## TABLE-02 — Standard Column Order

| Order | Role | Pinned | Sortable | Example |
|-------|------|--------|----------|---------|
| 1 | Checkbox selection | sticky (left) | No | Select all / individual |
| 2 | ID | sticky (left) | Yes | Campaign ID, AdGroup ID |
| 3 | Title (Name) | sticky (left) | Yes | Campaign name |
| 4+ | Attribute columns | No | Yes | Status, Channel, Period |
| Later | Metric columns (numbers) | No | Yes | Impressions, Clicks, CTR, CPA |
| Last | Actions | No | No | More menu (DropdownMenu) |

- Columns 1-3 (checkbox, ID, title) are pinned left — stay visible on horizontal scroll
- Metric columns use `tabular-nums text-right` alignment
- Actions column is always last and never sortable

// WHY: Pinning identity columns prevents disorientation on wide tables. Right-aligned numbers
// with tabular-nums ensure decimal alignment for scannable comparison.

## TABLE-03 — Built-in Features

| Feature | Location | Description |
|---------|----------|-------------|
| Sorting | Header click | `sortable: true` columns; sort icon in header; asc -> desc -> none cycle |
| Column pinning | `pinned: "left"` | Checkbox + ID + Title pinned, sticky on horizontal scroll |
| Pagination | DataTable bottom | `pageSize`-based; prev/next + page numbers |
| Row selection | Checkbox column | Select all / individual; `onSelectionChange` callback |

## TABLE-04 — Card Combination

DataTable and Table are always rendered inside a Card wrapper at the page level.
For Card wrapping patterns (header with title, description, action button, tabs), see: @.claude/rules/cards.md CARD-03a through CARD-03d.

## TABLE-05 — Full Column Example

Complete column definition demonstrating all column types:

```tsx
import { DataTable } from "@/components/composed"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from "@/components/ui/dropdown-menu"
import { formatNumber, formatCurrency, formatPercent } from "@/lib/format"

// Column definitions for Campaign table
const columns: DataTableColumn<Campaign>[] = [
  // 1. Checkbox selection — pinned left, no sorting
  {
    id: "select",
    pinned: "left",
    enableSorting: false,
    header: ({ table }) => (
      <Checkbox
        checked={table.getIsAllPageRowsSelected()}
        onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
        aria-label="Select all"
      />
    ),
    cell: (row) => (
      <Checkbox
        checked={row.getIsSelected()}
        onCheckedChange={(value) => row.toggleSelected(!!value)}
        aria-label="Select row"
      />
    ),
  },

  // 2. ID — pinned left, sortable, muted text
  {
    accessorKey: "id",
    header: "ID",
    pinned: "left",
    sortable: true,
    cell: (row) => (
      <span className="font-medium text-muted-foreground">{row.id}</span>
    ),
  },

  // 3. Name — pinned left, sortable, foreground text
  {
    accessorKey: "name",
    header: "Campaign Name",
    pinned: "left",
    sortable: true,
    cell: (row) => (
      <span className="font-medium text-foreground">{row.name}</span>
    ),
  },

  // 4. Status — attribute, sortable, Badge
  {
    accessorKey: "status",
    header: "Status",
    sortable: true,
    cell: (row) => <Badge variant="outline">{row.status}</Badge>,
  },

  // 5. Channel — attribute, sortable, plain text
  {
    accessorKey: "channel",
    header: "Channel",
    sortable: true,
  },

  // 6. Period — attribute, sortable, formatted date range
  {
    accessorKey: "period",
    header: "Period",
    sortable: true,
    cell: (row) => (
      <span className="text-muted-foreground">
        {row.startDate} ~ {row.endDate}
      </span>
    ),
  },

  // 7. Impressions — metric, right-aligned, tabular-nums
  {
    accessorKey: "impressions",
    header: "Impressions",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatNumber(row.impressions)}</span>
    ),
  },

  // 8. Clicks — metric, right-aligned, tabular-nums
  {
    accessorKey: "clicks",
    header: "Clicks",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatNumber(row.clicks)}</span>
    ),
  },

  // 9. CTR — metric, right-aligned, tabular-nums, percentage
  {
    accessorKey: "ctr",
    header: "CTR",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatPercent(row.ctr)}</span>
    ),
  },

  // 10. Spend — metric, right-aligned, tabular-nums, currency, medium weight
  {
    accessorKey: "spend",
    header: "Spend",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums font-medium">{formatCurrency(row.spend)}</span>
    ),
  },

  // 11. CPA — metric, right-aligned, tabular-nums, currency
  {
    accessorKey: "cpa",
    header: "CPA",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatCurrency(row.cpa)}</span>
    ),
  },

  // 12. Actions — last column, no sorting, dropdown menu
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
          <DropdownMenuItem onClick={() => handleEdit(row.id)}>Edit</DropdownMenuItem>
          <DropdownMenuItem onClick={() => handleDuplicate(row.id)}>Duplicate</DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem
            className="text-destructive"
            onClick={() => handleDelete(row.id)}
          >
            Delete
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  },
]

// Usage — DataTable inside Card
<Card>
  <CardHeader>
    <CardTitle>Campaigns</CardTitle>
  </CardHeader>
  <CardContent>
    <DataTable
      columns={columns}
      data={campaigns}
      onRowClick={(row) => navigate(`/campaigns/${row.id}`)}
      onSelectionChange={setSelectedCampaigns}
      pageSize={20}
      searchable
      searchPlaceholder="Search campaigns..."
      emptyMessage="No campaigns found."
    />
  </CardContent>
</Card>
```

// WHY: This canonical example demonstrates every column type in correct order. Copy and adapt
// for new tables — do not invent a new column structure from scratch.

**Format utilities** referenced above are imported from `@/lib/format`:
- `formatNumber(value)` — locale-aware number with thousand separators
- `formatCurrency(value)` — currency with symbol and decimals
- `formatPercent(value)` — percentage with fixed decimal places

For full format utility documentation, see: @.claude/rules/formatting.md

## TABLE-06 — Forbidden Patterns

```tsx
// FORBIDDEN — DataTable without Card wrapper
<div className="flex flex-col gap-6 p-6">
  <DataTable columns={columns} data={rows} />
</div>

// CORRECT — DataTable inside Card > CardContent
<Card>
  <CardContent>
    <DataTable columns={columns} data={rows} />
  </CardContent>
</Card>
```
// WHY: Card provides consistent border, padding, and background. Naked DataTable breaks visual rhythm.

```tsx
// FORBIDDEN — DataTable with internal Card (Card baked into DataTable component)
// DataTable must be Card-free; the wrapper lives in the page file.
```
// WHY: Baking Card into DataTable prevents composition (e.g., CardHeader with title/actions above the table).

```tsx
// FORBIDDEN — Large dataset (100+ rows) with shadcn Table directly
<Table>
  {largeDataset.map((row) => <TableRow key={row.id}>...</TableRow>)}
</Table>

// CORRECT — Use DataTable for large or interactive data
<DataTable columns={columns} data={largeDataset} pageSize={25} />
```
// WHY: shadcn Table renders all rows at once with no pagination. 100+ rows degrades scroll performance and usability.

```tsx
// FORBIDDEN — Hardcoded colors in cell rendering
cell: (row) => <span className="text-red-500">{row.status}</span>
cell: (row) => <span style={{ color: "#ef4444" }}>{row.status}</span>

// CORRECT — Token-based classes
cell: (row) => <span className="text-destructive">{row.status}</span>
cell: (row) => <Badge variant="outline">{row.status}</Badge>
```
// WHY: Hardcoded colors break theming and dark mode. Token classes adapt automatically.

## Escape Hatch

If a table need is not covered by DataTable or shadcn Table:
1. STOP — do not build custom table markup with raw `<div>` or `<table>`
2. Describe the requirement (e.g., virtualized rows, tree table, editable cells)
3. Wait for approval to extend DataTable or create a new Composed variant
4. After approval, implement in `@/components/composed/` with typed props, no className passthrough
