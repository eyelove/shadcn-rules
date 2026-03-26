---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
---

# Component Rules

## Tier Model

Three tiers. AI ONLY uses Composed and Page tiers.

- **Primitive** (`@/components/ui/`): shadcn/ui originals. NEVER import in page or feature files.
- **Composed** (`@/components/composed/`): project wrappers. ONLY legal import source for UI.
- **Page** (`@/components/pages/`): skeleton templates. Use for full-page structure.

// WHY: Direct primitive imports bypass all layout, spacing, and style constraints. Composed
// components encode those decisions — AI cannot accidentally violate them.

## Allowed Imports

DO import ONLY from `@/components/composed/`:

PageLayout · PageHeader · SearchBar · KpiCardGroup · ChartSection · DataTable
FormFieldSet · FormField · FormRow · FormActions · ConfirmDialog · StatusBadge · ActionButton

## Forbidden Imports

NEVER import from these paths in page or feature files:

- `@/components/ui/button` — use ActionButton from composed
- `@/components/ui/input` — use FormField > Input from composed
- `@/components/ui/select` — use FormField > Select from composed
- `@/components/ui/table` — use DataTable from composed
- `@/components/ui/card` — use KpiCardGroup or ChartSection from composed
- `@/components/ui/badge` — use StatusBadge from composed
- `@/components/ui/dialog` — use ConfirmDialog from composed
- `@/components/ui/field` — use FormField from composed
- `@/components/ui/textarea` — use FormField > Textarea from composed
- `@/components/ui/checkbox` — use FormField > Checkbox from composed

## Component Interfaces

No `className` prop on any Composed component.
// WHY: className gives AI a direct path back to primitive-level styling, bypassing all constraints.

### PageLayout
```tsx
interface PageLayoutProps {
  children: React.ReactNode  // PageHeader + page content
}
<PageLayout>{children}</PageLayout>
```

### PageHeader
```tsx
interface PageHeaderProps {
  title: string              // Page title, rendered as h1
  subtitle?: string          // Optional secondary description
  action?: React.ReactNode   // One ActionButton only — right-aligned
  backHref?: string          // If set, renders back navigation link
}
<PageHeader title="Campaigns" subtitle="14 active" action={<ActionButton onClick={onCreate}>New</ActionButton>} />
```

### SearchBar
```tsx
interface FilterConfig {
  type: "text" | "select" | "daterange"
  key: string
  label: string
  options?: { label: string; value: string }[]  // for type="select"
}
interface SearchBarProps {
  filters: FilterConfig[]
  onSearch: (values: Record<string, unknown>) => void
}
<SearchBar filters={[{ type: "text", key: "name", label: "Name" }, { type: "select", key: "status", label: "Status", options: statusOptions }]} onSearch={handleSearch} />
```

### KpiCardGroup
```tsx
interface KpiItem {
  label: string
  value: string | number
  delta?: string           // e.g., "+12%" — styled with kpi-positive/kpi-negative automatically
  deltaPositive?: boolean  // controls color; default false
}
interface KpiCardGroupProps {
  items: KpiItem[]
  cols?: 2 | 4             // Default: 4
}
<KpiCardGroup cols={4} items={[{ label: "Total Campaigns", value: 142, delta: "+8%", deltaPositive: true }]} />
```

### ChartSection
```tsx
interface ChartConfig {
  title: string
  chart: React.ReactNode  // Recharts or similar — rendered inside Card
}
interface ChartSectionProps {
  charts: ChartConfig[]
  cols?: 1 | 2            // Default: 1
}
<ChartSection cols={2} charts={[{ title: "Daily Spend", chart: <SpendLineChart data={data} /> }]} />
```

### DataTable
```tsx
interface DataTableColumn<T> {
  key: keyof T
  header: string
  sortable?: boolean
  render?: (value: T[keyof T], row: T) => React.ReactNode
}
interface DataTableProps<T> {
  columns: DataTableColumn<T>[]
  data: T[]
  onRowClick?: (row: T) => void
  actions?: React.ReactNode  // ActionButton(s) only
  loading?: boolean
  emptyMessage?: string
}
<DataTable columns={columns} data={rows} onRowClick={(r) => router.push(`/campaigns/${r.id}`)} actions={<ActionButton onClick={onCreate}>New</ActionButton>} />
```

### FormFieldSet
```tsx
interface FormFieldSetProps {
  legend: string             // Group title (e.g., "Basic Info")
  children: React.ReactNode  // FormRow and/or FormField components
}
<FormFieldSet legend="Basic Info">{fields}</FormFieldSet>
```

### FormField
```tsx
interface FormFieldProps {
  label: string
  required?: boolean
  description?: string
  children: React.ReactNode  // Input, Select, Textarea, Checkbox, etc.
}
<FormField label="Campaign Name" required><Input placeholder="Enter name" /></FormField>
```

### FormRow
```tsx
interface FormRowProps {
  cols?: 1 | 2              // Default: 1
  children: React.ReactNode  // FormField components
}
<FormRow cols={2}><FormField label="Name" required><Input /></FormField><FormField label="Status"><Select /></FormField></FormRow>
```

### FormActions
```tsx
interface FormActionsProps {
  children: React.ReactNode  // ActionButton only. Cancel uses variant="outline", Save uses default.
}
<FormActions><ActionButton variant="outline" onClick={onCancel}>Cancel</ActionButton><ActionButton type="submit">Save</ActionButton></FormActions>
```

### ConfirmDialog
```tsx
interface ConfirmDialogProps {
  open: boolean
  title: string
  description: string
  onConfirm: () => void
  onCancel: () => void
  confirmLabel?: string      // Default: "Confirm"
  destructive?: boolean      // If true, confirm button uses destructive variant
}
<ConfirmDialog open={isOpen} title="Delete Campaign" description="This cannot be undone." onConfirm={handleDelete} onCancel={() => setOpen(false)} destructive />
```

### StatusBadge
```tsx
type StatusVariant = "active" | "paused" | "ended" | "draft" | "error"
interface StatusBadgeProps {
  status: StatusVariant | string  // string allows extension
  variant?: "default" | "outline"
}
<StatusBadge status="active" />
```

## Escape Hatch

Need a UI element not covered by the 12 components above?
1. STOP — do not reach for `@/components/ui/` directly
2. Describe the needed component and ask for approval to create a new Composed component
3. After approval, create it in `@/components/composed/` with a typed props interface
4. NEVER add className to the new component's props
