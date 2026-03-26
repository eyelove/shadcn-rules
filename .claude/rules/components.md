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

## Import Convention

Use barrel import from `@/components/composed`:
```tsx
import { PageLayout, PageHeader, DataTable } from "@/components/composed"
```
// WHY: Barrel import keeps imports consistent and discoverable across all pages.

## Allowed Imports

DO import ONLY from `@/components/composed`:

PageLayout · PageHeader · SearchBar · KpiCardGroup · ChartSection · DataTable
FormFieldSet · FormField · FormRow · FormActions · ConfirmDialog · StatusBadge · ActionButton

**Form primitives inside FormField:** `Input`, `Select`, `Textarea`, `Checkbox`, `DateRangePicker`
are imported from `@/components/composed` and used ONLY as children of `FormField`.
NEVER use them standalone outside a FormField wrapper.

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

## No className

No `className` prop on any Composed component.
// WHY: className gives AI a direct path back to primitive-level styling, bypassing all constraints.

## Render Functions in DataTable

When using `render` in DataTable columns, you MAY use `<span>` with token-based Tailwind classes:
```tsx
// ALLOWED — token-based text styling in render functions
render: (value) => <span className="font-medium text-foreground">{value}</span>
render: (value) => <StatusBadge status={value} />

// FORBIDDEN — hardcoded colors or inline styles in render functions
render: (value) => <span style={{ color: "red" }}>{value}</span>
render: (value) => <span className="text-red-500">{value}</span>
```
// WHY: DataTable render functions need lightweight formatting. Token classes keep consistency.

## Third-Party Library Styling

When using chart libraries (Recharts, etc.) that REQUIRE style props in their API:
- Use CSS custom property tokens: `"var(--chart-1)"`, `"var(--border)"`, `"var(--card)"`
- NEVER use hardcoded hex/rgb values even in library props
```tsx
// CORRECT — token-based chart styling
<CartesianGrid stroke="var(--border)" />
<XAxis stroke="var(--muted-foreground)" />
<Tooltip contentStyle={{ backgroundColor: "var(--card)", borderColor: "var(--border)", color: "var(--card-foreground)" }} />
<Line stroke="var(--chart-1)" />

// FORBIDDEN — hardcoded values in library props
<CartesianGrid stroke="#e5e7eb" />
<Line stroke="blue" />
```
// WHY: Library props are the one exception to "no style={{}}". But values MUST still be tokens.

## Escape Hatch

Need a UI element not covered above?
1. STOP — do not reach for `@/components/ui/` directly
2. Describe the needed component and ask for approval to create a new Composed component
3. After approval, create it in `@/components/composed/` with a typed props interface
4. NEVER add className to the new component's props

For FORBIDDEN/CORRECT examples of all 5 forbidden patterns, see: @.claude/rules/forbidden.md

**For full component interface contracts (Props types and usage examples), see:**
@.claude/rules/component-interfaces.md
