---
paths:
  - "src/**/*.tsx"
  - "src/**/*.css"
  - "app/**/*.tsx"
  - "app/**/*.css"
  - "components/**/*.tsx"
  - "components/**/*.css"
---

# Token Rules

All color, spacing, radius, and shadow values MUST use CSS custom property tokens.
NEVER hardcode hex, rgb, oklch, or Tailwind color primitives (gray-100, zinc-800, etc.) in component or page code.
// WHY: Raw values break theming and dark mode. Token names are stable; oklch values can change.

## Color Tokens — Use These

Reference tokens as Tailwind utility classes where available, or as `var(--token-name)` in CSS:

**Surfaces:**
`bg-background` · `bg-card` · `bg-popover` · `bg-muted` · `bg-accent`

**Text:**
`text-foreground` · `text-card-foreground` · `text-muted-foreground` · `text-primary-foreground`

**Actions:**
`bg-primary` · `bg-secondary` · `bg-destructive` · `border-border` · `ring-ring`

**Dashboard extensions (use `var()` syntax — no Tailwind utility class):**
`var(--chart-1)` through `var(--chart-6)` — chart series colors
`var(--kpi-bg)` — KPI card background
`var(--kpi-positive)` — positive delta (green)
`var(--kpi-negative)` — negative delta (red)
`var(--table-row-hover)` — table row hover

Full token list: `tokens/globals.css`

## Radius Tokens

`rounded-[--radius]` · `rounded-[--radius-sm]` · `rounded-[--radius-lg]`
NEVER use `rounded-md`, `rounded-lg` (Tailwind fixed values) — use the token-based form above.
// WHY: Project radius can be customized via --radius without changing all component classes.

## Typography

Font sizes: `text-xs` · `text-sm` · `text-base` · `text-lg` · `text-xl` · `text-2xl`
Font weights: `font-normal` (body) · `font-medium` (labels, captions) · `font-semibold` (headings, KPI values)
// WHY: Tailwind's type scale is in AI training data; custom --font-* tokens are not reliably known.

NEVER use inline `style={{ fontSize: "..." }}` or `style={{ fontWeight: "..." }}`.

## Spacing

Use Tailwind spacing utilities: `p-4`, `px-6`, `gap-4`, `space-y-6`.
NEVER use `style={{ padding: "..." }}` or `style={{ marginTop: "..." }}`.
// WHY: Tailwind's spacing scale produces consistent density; inline style bypasses all constraints.

Semantic spacing conventions:
- Component internal padding: `p-4` or `p-6`
- Between sibling components: `gap-4` or `gap-6`
- Between page sections: `space-y-8` or `gap-8`

## Forbidden Patterns

```
FORBIDDEN — hardcoded color:
  style={{ backgroundColor: "#1a1a2e" }}
  style={{ color: "oklch(0.5 0.2 240)" }}

FORBIDDEN — Tailwind color primitive (not a token):
  bg-zinc-900   bg-gray-100   text-slate-500

CORRECT — token-based:
  bg-background   bg-card   text-foreground   text-muted-foreground
```

## Escape Hatch

If a token does not exist for a legitimate design need (e.g., a one-off data visualization color):
1. Add the token to `tokens/globals.css` first with a comment explaining its purpose
2. THEN reference it via `var(--your-new-token)` in component code
3. NEVER use an inline literal and promise to "add the token later"
