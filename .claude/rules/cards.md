---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
  - "resources/js/**/*.tsx"
---

# Card Usage Strategy

## Principles

1. **Card = section container.** Every dashboard section (KPI, chart, table, form) lives inside a Card. No floating content with ad-hoc borders/backgrounds.
2. **No double wrapping.** NEVER nest Card inside Card. Sub-grouping uses Separator or gap utilities inside one Card.
3. **Unified structure.** Every Card MUST have CardHeader with at least CardTitle. CardContent for body, CardFooter optional.

## Card Patterns

### CARD-01 — KPI Card

Grid: `grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4`. Each Card uses CardHeader only (no CardContent).
Structure: CardHeader > CardDescription(label) + CardTitle(`text-2xl font-semibold tabular-nums`, value) + CardAction(Badge delta). CardFooter for supplementary text.

- Delta badge in CardAction, token colors: `text-[--kpi-positive]` / `text-[--kpi-negative]`
- `tabular-nums` on value prevents layout shift
- No CardContent -- KPI cards are dense, CardContent adds unnecessary padding

### CARD-02 — Chart Card

Card > CardHeader(title, description, CardAction with period selector) > CardContent > ChartContainer > Recharts chart.
Period selector default: Select (7d/30d/90d). Custom range: Popover + Select(presets) + Calendar(range, numberOfMonths={2}).

```tsx
const chartConfig = {
  desktop: { label: "Desktop", color: "var(--chart-1)" },
  mobile: { label: "Mobile", color: "var(--chart-2)" },
} satisfies ChartConfig
```

- Chart colors defined in `chartConfig`, referenced as `var(--color-KEY)` on elements (e.g. `stroke="var(--color-desktop)"`)
- `ChartContainer` MUST have `min-h-[VALUE]` or `aspect-*`
- `accessibilityLayer` on chart root
- Tooltip: `<ChartTooltip content={<ChartTooltipContent />} />` -- NEVER raw Recharts Tooltip/contentStyle
- Legend: `<ChartLegend content={<ChartLegendContent />} />` when needed
- Do NOT pass `stroke` to CartesianGrid/XAxis/YAxis -- ChartContainer handles axis styling

### CARD-03 — Table Card

Four sub-patterns, all follow Card > CardHeader > CardContent structure:

| Sub-pattern | Description |
|-------------|-------------|
| **CARD-03a** Simple Table | Static data (<20 rows), shadcn Table directly in CardContent |
| **CARD-03b** DataTable + Inline Filter | Filter toolbar (`flex items-center gap-2 pb-4`) above DataTable, both inside CardContent |
| **CARD-03c** DataTable + Tabs | Tabs inside CardContent, each TabsContent contains a DataTable |
| **CARD-03d** Full-Width Main Table | CardAction for export, CardFooter for pagination controls |

### CARD-04 — Form Card

Card > CardHeader > CardContent(`<form id="X">`) > CardFooter(`gap-2`, buttons with `form="X"`).

- `<form>` gets `id`, submit button uses `form="form-id"` to link from CardFooter
- CardFooter MUST have `className="gap-2"` (shadcn CardFooter has no default gap)
- Secondary action: `variant="outline"`, primary: default variant
- Submit/cancel buttons MUST be in CardFooter, NEVER inside CardContent
- Single form = one Card. Multiple Cards only for wizard/multi-step flows

### CARD-05 — Mixed Card (Content Grouping)

Multiple related elements in one Card, separated by `space-y-4` on CardContent or Separator.

- Use `space-y-4` or Separator to divide sub-sections inside CardContent
- NEVER split related content into separate Cards -- shared context stays in one Card

## Escape Hatch

If no CARD pattern fits: STOP, describe the need and wait for approval. Do not substitute raw divs with border/background.
