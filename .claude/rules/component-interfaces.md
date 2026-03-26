---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/composed/**/*.tsx"
---

# Component Interface Contracts

Every Composed component's Props type and canonical usage example.
No `className` prop on ANY interface. See components.md for rules.

## PageLayout
```tsx
interface PageLayoutProps {
  children: React.ReactNode  // PageHeader + page content
}
<PageLayout>{children}</PageLayout>
```

## PageHeader
```tsx
interface PageHeaderProps {
  title: string              // Page title, rendered as h1
  subtitle?: string          // Optional secondary description
  action?: React.ReactNode   // One ActionButton only — right-aligned
  backHref?: string          // If set, renders back navigation link
}
<PageHeader title="Campaigns" subtitle="14 active" action={<ActionButton onClick={onCreate}>New</ActionButton>} />
```

## SearchBar
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
<SearchBar filters={[{ type: "text", key: "name", label: "Name" }]} onSearch={handleSearch} />
```

## KpiCardGroup
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
<KpiCardGroup cols={4} items={[{ label: "Total", value: 142, delta: "+8%", deltaPositive: true }]} />
```

## ChartSection
```tsx
interface ChartConfig {
  title: string
  chart: React.ReactNode  // Recharts or similar — rendered inside Card
}
interface ChartSectionProps {
  charts: ChartConfig[]
  cols?: 1 | 2            // Default: 1
}
<ChartSection cols={2} charts={[{ title: "Daily Spend", chart: <SpendLineChart /> }]} />
```

## DataTable
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
<DataTable columns={columns} data={rows} onRowClick={(r) => navigate(r.id)} />
```

## FormFieldSet
```tsx
interface FormFieldSetProps {
  legend: string             // Group title (e.g., "Basic Info")
  children: React.ReactNode  // FormRow and/or FormField components
}
<FormFieldSet legend="Basic Info">{fields}</FormFieldSet>
```

## FormField
```tsx
interface FormFieldProps {
  label: string
  required?: boolean
  description?: string
  children: React.ReactNode  // Input, Select, Textarea, Checkbox from @/components/composed
}
<FormField label="Campaign Name" required><Input placeholder="Enter name" /></FormField>
```

## FormRow
```tsx
interface FormRowProps {
  cols?: 1 | 2              // Default: 1
  children: React.ReactNode  // FormField components
}
<FormRow cols={2}>
  <FormField label="Name" required><Input /></FormField>
  <FormField label="Status"><Select options={options} /></FormField>
</FormRow>
```

## FormActions
```tsx
interface FormActionsProps {
  children: React.ReactNode  // ActionButton only. Cancel=outline, Save=default.
}
<FormActions>
  <ActionButton variant="outline" onClick={onCancel}>Cancel</ActionButton>
  <ActionButton type="submit">Save</ActionButton>
</FormActions>
```

## ConfirmDialog
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
<ConfirmDialog open={isOpen} title="Delete" description="Cannot be undone." onConfirm={del} onCancel={close} destructive />
```

## StatusBadge
```tsx
type StatusVariant = "active" | "paused" | "ended" | "draft" | "error"
interface StatusBadgeProps {
  status: StatusVariant | string
  variant?: "default" | "outline"
}
<StatusBadge status="active" />
```

## ActionButton
```tsx
interface ActionButtonProps {
  children: React.ReactNode
  onClick?: () => void
  type?: "button" | "submit"
  variant?: "default" | "outline" | "destructive"
  disabled?: boolean
}
<ActionButton onClick={handleCreate}>New Campaign</ActionButton>
<ActionButton variant="outline" onClick={onCancel}>Cancel</ActionButton>
```
