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

  - "resources/js/**/*.tsx"
  - "resources/js/**/*.ts"
  - "resources/css/**/*.css"
---

# Naming Conventions

## NAME-01 — File Naming

| File Type | Convention | Examples |
|-----------|-----------|---------|
| Page files | kebab-case | campaign-list.tsx, campaign-form.tsx |
| Composed components | PascalCase | DataTable.tsx, SearchBar.tsx, KpiCard.tsx |
| Hook files | camelCase with use prefix | useFilters.ts, usePagination.ts |
| Type files | PascalCase | Campaign.ts, AdGroup.ts |
| CSS files | kebab-case | index.css, custom-tokens.css |

## NAME-02 — Component Naming

Composed components use **Noun** pattern: DataTable, SearchBar, KpiCard.
NEVER use UI suffix or Base prefix (UIButton, BaseCard).

shadcn components keep original names. Import from `@/components/ui/`.

**Barrel export** — all Composed components MUST be exported from `@/components/composed/index.ts`:

```tsx
// CORRECT — barrel import
import { DataTable, SearchBar, KpiCard } from "@/components/composed"

// FORBIDDEN — direct file import
import { DataTable } from "@/components/composed/DataTable"
```

## Directory Structure

```
components/
  ui/          <- shadcn primitives — import directly in page files
  composed/    <- Domain-specific: DataTable, SearchBar, KpiCard ONLY
app/ or pages/ <- page files
hooks/         <- custom React hooks
types/         <- shared TypeScript types
lib/           <- utility functions (format.ts, etc.)
```

## Escape Hatch

Ambiguous case → apply convention matching file's primary purpose. NEVER deviate from directory placement.
