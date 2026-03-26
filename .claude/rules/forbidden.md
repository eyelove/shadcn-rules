---
paths:
  - "src/**/*.tsx"
  - "src/**/*.css"
  - "app/**/*.tsx"
  - "app/**/*.css"
  - "components/**/*.tsx"
  - "components/**/*.css"
---

# Forbidden Patterns

These 5 patterns are NEVER allowed. Each entry has a rule statement, WHY comment, FORBIDDEN example, and CORRECT replacement.

## FORB-01 — No Inline Styles

NEVER use `style={{}}` on any HTML element or Composed component.
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

## FORB-03 — No Raw div/span Layout

NEVER use `<div>` or `<span>` with layout classes (`flex`, `grid`, `space-`) as structural containers in page files.
// WHY: Raw divs fragment structure. Composed components encode spacing and layout decisions — AI cannot violate them accidentally.

```tsx
// FORBIDDEN — raw div layout
<div className="flex flex-col gap-4">
  <div className="grid grid-cols-2 gap-6">

// FORBIDDEN — raw span as layout wrapper
<span className="flex gap-2 items-center">

// CORRECT — Composed components handle layout
<FormFieldSet legend="Basic Info">
  <FormRow cols={2}>
```

**Exception:** `<span>` with text-styling classes inside DataTable `render` functions is allowed per components.md.

## FORB-04 — No Direct shadcn Primitive Imports

NEVER import from `@/components/ui/` in page or feature files.
// WHY: Primitive imports bypass all layout, spacing, and style constraints encoded in Composed components.

```tsx
// FORBIDDEN — direct primitive import
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card } from "@/components/ui/card"

// CORRECT
import { ActionButton, FormField, KpiCardGroup } from "@/components/composed"
```

Full allowed/forbidden import list: see components.md.

## FORB-05 — No Bare Input (Outside FormField)

NEVER use `<Input>`, `<Select>`, `<Textarea>`, or `<Checkbox>` outside a `<FormField>` wrapper.
// WHY: FormField provides label, required indicator, description, and validation state. Bare inputs have no accessible label and skip all validation UI.

```tsx
// FORBIDDEN — bare Input with no FormField
<Card>
  <Input placeholder="Campaign name" />
</Card>

// CORRECT — Input always inside FormField
<FormField label="Campaign Name" required>
  <Input placeholder="Campaign name" />
</FormField>
```

## Escape Hatch Process

If you believe a forbidden pattern is genuinely required:
1. STOP — do not implement the forbidden pattern
2. Describe the specific need and why no allowed pattern covers it
3. Wait for explicit approval
4. If approved, document the exception inline with a `// EXCEPTION:` comment explaining why
5. NEVER assume a pattern is "close enough" to an allowed exception without asking
