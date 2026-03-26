---
paths:
  - "src/**/*.tsx"
  - "src/**/*.ts"
  - "src/**/*.css"
  - "app/**/*.tsx"
  - "app/**/*.ts"
  - "components/**/*.tsx"
  - "components/**/*.ts"
  - "hooks/**/*.ts"
  - "types/**/*.ts"
  - "tokens/**/*.css"
---

# Naming Conventions

## NAME-01 — File Naming

| File Type | Convention | Examples |
|-----------|-----------|---------|
| Page files | kebab-case | campaign-list.tsx, campaign-form.tsx, ad-group-detail.tsx |
| Composed components | PascalCase | DataTable.tsx, SearchBar.tsx, FormFieldSet.tsx |
| Hook files | camelCase with use prefix | useFilters.ts, usePagination.ts, useCampaignData.ts |
| Type files | PascalCase | Campaign.ts, AdGroup.ts, FilterConfig.ts |
| CSS token files | kebab-case | globals.css, dashboard-tokens.css |

// WHY: Convention-per-type makes file intent obvious without opening the file. AI infers
// where to create new files based on type alone — no ambiguity about page vs component files.

## NAME-02 — Component Naming

Composed components MUST follow these naming patterns:

| Pattern | Use For | Examples |
|---------|---------|---------|
| Noun | Single-purpose display | DataTable, StatusBadge, PageHeader |
| NounGroup | Multi-item container | KpiCardGroup, ChartSection |
| FormNoun | Form-specific | FormField, FormFieldSet, FormRow, FormActions |
| ActionNoun | Interactive | ActionButton, ConfirmDialog |

NEVER use a UI suffix or Base prefix (UIButton, BaseCard).
// WHY: UI/Base prefixes are shadcn primitive naming conventions. Using them implies
// the component is a primitive, not a Composed wrapper — this breaks the tier model.

Barrel export — all Composed components MUST be exported from `@/components/composed/index.ts`:

```tsx
// CORRECT — barrel import
import { DataTable, FormField, ActionButton } from "@/components/composed"

// FORBIDDEN — direct file import bypassing barrel
import { DataTable } from "@/components/composed/DataTable"
```

// WHY: The barrel is a single choke point. Every new component must be registered here
// to be usable. All 4 Phase 1 test samples confirmed consistent barrel usage.

## NAME-03 — CSS Variable and Class Naming

CSS custom properties (tokens):
- Dashboard extension tokens use prefixes: `--kpi-*`, `--chart-*`, `--table-*`
- All tokens defined in `tokens/globals.css` — NEVER define CSS variables in component files
// WHY: Centralized token definition makes theme overrides a single-file operation.

Tailwind class usage:
- Layout and spacing: `flex`, `grid`, `gap-4`, `p-6` (Tailwind utilities — allowed)
- Color: `bg-background`, `text-foreground`, `border-border` (token-aliased — required)
- NEVER: `bg-zinc-900`, `text-gray-500` (raw Tailwind color primitives — hardcode the value)

CSS module file naming (if used): `ComponentName.module.css` — matches the component file name.

## Directory Structure

```
components/
  ui/          <- shadcn primitives — DO NOT edit or import directly
  composed/    <- AI creates new components here ONLY
app/ or pages/ <- page files (framework-dependent)
hooks/         <- custom React hooks (useX naming required)
types/         <- shared TypeScript types
tokens/        <- CSS custom property files
```

## Escape Hatch

If the naming rule creates an ambiguous case:
1. Apply the convention that best reflects the file PRIMARY purpose
2. Document the reasoning in a comment at the top of the file
3. NEVER deviate from directory placement rules — directory determines tier
