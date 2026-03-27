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

These 6 patterns are NEVER allowed. Each entry has a rule statement, WHY comment, FORBIDDEN example, and CORRECT replacement.

## FORB-01 — No Inline Styles

NEVER use `style={{}}` on any HTML element or component.
// WHY: Inline styles bypass the token system entirely and cannot be audited by grep or linting.

```tsx
// FORBIDDEN
<div style={{ marginTop: "24px", padding: "16px" }}>

// CORRECT
<div className="mt-6 p-4">
```

**Exception (third-party library API only):** Recharts and similar libraries have props that ONLY accept style objects (e.g., `contentStyle`, `labelStyle`). These are allowed IF AND ONLY IF all values use CSS custom property tokens:
```tsx
// ALLOWED — library prop, values are tokens
<Tooltip contentStyle={{ backgroundColor: "var(--card)", borderColor: "var(--border)", color: "var(--card-foreground)" }} />

// FORBIDDEN — library prop with hardcoded values
<Tooltip contentStyle={{ backgroundColor: "#fff", color: "black" }} />
```

## FORB-02 — No Hardcoded Colors

NEVER use hex, rgb(), oklch(), or Tailwind color primitives directly in page or component code.
// WHY: Hardcoded values break theming. Token names are stable; color values can change.

```tsx
// FORBIDDEN — hex color
<div style={{ backgroundColor: "#1a1a2e" }} />

// FORBIDDEN — Tailwind color primitive (not a token)
<div className="bg-zinc-900 text-gray-100 border-slate-200" />

// FORBIDDEN — rgb/oklch literal
stroke="oklch(0.5 0.2 240)"

// CORRECT — token-based
<div className="bg-background text-foreground border-border" />
stroke="var(--chart-1)"
```

## FORB-03 — No div as Card Substitute

NEVER use a raw `<div>` with border/background/padding classes as a substitute for `Card` in dashboard sections (KPI groups, charts, tables, forms).
// WHY: Card is the standard visual container with token-based surfaces (bg-card, border-border, rounded-[--radius]). Raw divs with ad-hoc border/background classes fragment theming and bypass Card's consistent structure.

```tsx
// FORBIDDEN — div pretending to be a Card
<div className="rounded-lg border bg-card p-4">
  <h3 className="font-semibold">Revenue</h3>
  <p>$12,345</p>
</div>

// FORBIDDEN — div with shadow/border mimicking a card section
<div className="border border-border rounded-[--radius] p-6 shadow-sm">
  <BarChart />
</div>

// CORRECT — use Card with proper internal structure
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"

<Card>
  <CardHeader><CardTitle>Revenue</CardTitle></CardHeader>
  <CardContent><p>$12,345</p></CardContent>
</Card>
```

**Allowed uses of div:** `<div>` with layout classes (`flex`, `grid`, `gap-*`, `space-*`) IS allowed for page-level layout structure such as page header areas, grid wrappers for Card columns, and spacing containers.
```tsx
// ALLOWED — div for page layout grid
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
  <Card>...</Card>
  <Card>...</Card>
</div>

// ALLOWED — div for page header layout
<div className="flex items-center justify-between">
  <h1 className="text-xl font-semibold">Dashboard</h1>
  <Button>New Campaign</Button>
</div>
```

For Card structure rules, see: @.claude/rules/cards.md

## FORB-04 — No Unnecessary Composed Wrappers

NEVER create wrapper components that merely pass through to a shadcn component without adding meaningful logic, layout, or constraint.
// WHY: Thin wrappers add indirection with no benefit. They create a parallel API surface that drifts from upstream shadcn, making upgrades harder and documentation less useful.

```tsx
// FORBIDDEN — wrapper that adds nothing
// components/composed/ActionButton.tsx
import { Button } from "@/components/ui/button"

interface ActionButtonProps {
  children: React.ReactNode
  onClick?: () => void
  variant?: "default" | "outline" | "destructive"
  disabled?: boolean
}
export function ActionButton({ children, ...props }: ActionButtonProps) {
  return <Button {...props}>{children}</Button>  // just passes through
}

// CORRECT — use shadcn directly when no extra logic is needed
import { Button } from "@/components/ui/button"

<Button onClick={handleCreate}>New Campaign</Button>
<Button variant="outline" onClick={onCancel}>Cancel</Button>
```

```tsx
// ALLOWED — wrapper that adds real value (layout, composition, business logic)
// A ConfirmDialog that composes AlertDialog + destructive styling + standard button layout
export function ConfirmDialog({ open, title, description, onConfirm, onCancel, destructive }: ConfirmDialogProps) {
  return (
    <AlertDialog open={open}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{title}</AlertDialogTitle>
          <AlertDialogDescription>{description}</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel onClick={onCancel}>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={onConfirm} variant={destructive ? "destructive" : "default"}>
            Confirm
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}
```

## FORB-05 — No Bare Input (Outside Field)

NEVER use `<Input>`, `<Select>`, `<Textarea>`, or `<Checkbox>` outside a `<Field>` wrapper in form contexts.
// WHY: Field provides label, required indicator, description, and validation state. Bare inputs have no accessible label and skip all validation UI. See fields.md for the full Field component hierarchy.

```tsx
// FORBIDDEN — bare Input with no Field
import { Input } from "@/components/ui/input"

<Card>
  <CardContent>
    <Input placeholder="Campaign name" />
  </CardContent>
</Card>

// CORRECT — Input inside Field
import { Input } from "@/components/ui/input"
import { Field, FieldLabel } from "@/components/ui/field"

<Field>
  <FieldLabel>Campaign Name</FieldLabel>
  <Input placeholder="Campaign name" />
</Field>
```

**Exception (search/filter toolbar):** Inputs used in search or filter toolbars above a DataTable are allowed without a Field wrapper, since they function as transient filters rather than form fields with validation state.
```tsx
// ALLOWED — search input in a filter toolbar
<div className="flex items-center gap-2">
  <Input placeholder="Search campaigns..." value={search} onChange={onSearchChange} />
  <Select value={statusFilter} onValueChange={setStatusFilter}>
    <SelectTrigger><SelectValue placeholder="Status" /></SelectTrigger>
    <SelectContent>{statusOptions}</SelectContent>
  </Select>
</div>
<DataTable columns={columns} data={filteredRows} />
```

For full Field rules and hierarchy, see: @.claude/rules/fields.md

## FORB-06 — No Card Double Wrapping

NEVER nest a Card inside another Card. One Card per section, one level deep.
// WHY: Double wrapping creates redundant padding, doubled borders, and broken visual hierarchy. If content needs sub-grouping inside a Card, use Separator or gap utilities.

```tsx
// FORBIDDEN — Card inside Card
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"

<Card>
  <CardContent>
    <Card>
      <CardHeader><CardTitle>Nested Section</CardTitle></CardHeader>
      <CardContent><p>This is double wrapped</p></CardContent>
    </Card>
  </CardContent>
</Card>

// CORRECT — single Card, use Separator for sub-grouping
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"

<Card>
  <CardHeader><CardTitle>Section</CardTitle></CardHeader>
  <CardContent>
    <div className="space-y-4">
      <div>
        <h4 className="text-sm font-medium text-muted-foreground">Sub-section A</h4>
        <p>Content A</p>
      </div>
      <Separator />
      <div>
        <h4 className="text-sm font-medium text-muted-foreground">Sub-section B</h4>
        <p>Content B</p>
      </div>
    </div>
  </CardContent>
</Card>
```

For Card structure rules and patterns, see: @.claude/rules/cards.md

## Escape Hatch Process

If you believe a forbidden pattern is genuinely required:
1. STOP — do not implement the forbidden pattern
2. Describe the specific need and why no allowed pattern covers it
3. Wait for explicit approval
4. If approved, document the exception inline with a `// EXCEPTION:` comment explaining why
5. NEVER assume a pattern is "close enough" to an allowed exception without asking
