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
- @.claude/rules/fields.md — form field patterns with shadcn primitives

## Render Functions in DataTable

When using `render` in DataTable columns, you MAY use `<span>` with token-based Tailwind classes:
```tsx
// ALLOWED — token-based text styling in render functions
render: (value) => <span className="font-medium text-foreground">{value}</span>
render: (value) => <Badge variant="outline">{value}</Badge>

// FORBIDDEN — hardcoded colors or inline styles in render functions
render: (value) => <span style={{ color: "red" }}>{value}</span>
render: (value) => <span className="text-red-500">{value}</span>
```
// WHY: DataTable render functions need lightweight formatting. Token classes keep consistency.

## Chart Library Usage

Charts use shadcn's `ChartContainer`, `ChartTooltip`, and `ChartTooltipContent` from `@/components/ui/chart`.
Recharts axis/grid props that accept string values MUST use token vars. Tooltip styling is handled by `ChartTooltipContent` internally.
```tsx
// CORRECT — shadcn chart components + token vars
<CartesianGrid stroke="var(--border)" />
<ChartTooltip content={<ChartTooltipContent />} />

// FORBIDDEN — raw Recharts Tooltip with inline style
<Tooltip contentStyle={{ backgroundColor: "var(--card)" }} />

// FORBIDDEN — hardcoded colors
<CartesianGrid stroke="#e5e7eb" />
```
// WHY: shadcn's ChartTooltipContent handles theming with token-based classes. No style={{}} needed.

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
