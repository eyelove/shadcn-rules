# Dashboard Rules

This project uses shadcn/ui directly with a 2-tier component model:
- **shadcn tier**: Use shadcn/ui components directly (`@/components/ui/*`)
- **Composed tier**: Domain-specific components with internal logic (`@/components/composed/*` — DataTable, SearchBar, KpiCard only)

Follow these rules for every file you touch.

@.claude/rules/components.md
@.claude/rules/cards.md
@.claude/rules/fields.md
@.claude/rules/data-table.md
@.claude/rules/formatting.md
@.claude/rules/tokens.md
@.claude/rules/forbidden.md
@.claude/rules/naming.md
@.claude/rules/page-templates.md

## Always Apply

- **Imports**: Use shadcn components directly from `@/components/ui/*`. Use `@/components/composed/` only for DataTable, SearchBar, KpiCard.
  // WHY: shadcn components are the standard. Composed is only for domain logic that can't be expressed with direct shadcn usage.

- **Card wrapping**: Every independent dashboard section (chart, table, form) MUST be wrapped in a Card. No Card double-wrapping. See `cards.md`.
  // WHY: Card provides visual consistency across all sections. Double-wrapping breaks spacing.

- **Field system**: All form inputs MUST be inside a `<Field>` with `<FieldLabel>`. Form buttons go in `<CardFooter>`. See `fields.md`.
  // WHY: Field provides accessible labels and validation state. CardFooter gives consistent button placement.

- **Tokens**: Use CSS custom property tokens for ALL color, spacing, and radius values. Never hardcode hex, rgb, or oklch literals.
  // WHY: Hardcoded values break theming and make dark mode impossible to maintain.

- **No inline styles**: Never use `style={{}}` on any element. No exceptions. Use shadcn's `ChartTooltip` + `ChartTooltipContent` instead of raw Recharts Tooltip with `contentStyle`.
  // WHY: Inline styles bypass the token system and are impossible to audit automatically.

- **Formatting**: Use locale-aware format utility functions for all numbers, currency, and percentages. See `formatting.md`.
  // WHY: Consistent number formatting across KPI cards and tables. Supports multi-locale (ko-KR, en-US).

- **Rule files**: When in doubt about what is allowed, read the specific rule file. Do not infer — look it up.
