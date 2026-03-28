# Sample Page Evaluation Checklist (2-Tier Model)

Run `bash scripts/check-rules.sh preview/src/pages/` first for automated grep checks.
This checklist covers structural and semantic checks that grep cannot automate.

**Instructions:**
1. Open each sample file in your editor
2. For each row: read the Expected column, check the Actual output, mark Pass/Fail
3. Critical violation = rule broken at the structural level
4. Minor violation = deviation that does not break structure
5. A sample "passes" when it has zero critical violations

---

## dashboard-overview.tsx — Dashboard Overview (PAGE-04)

### Component Imports

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| 2-tier | shadcn imports from `@/components/ui/*` directly | |
| 2-tier | Composed imports from `@/components/composed` barrel only (DataTable, KpiCard) | |
| FORB-04 | No unnecessary Composed wrappers (no ActionButton, StatusBadge, etc.) | |

### Page Structure

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| PAGE-04 | Root: `div.flex.flex-col.gap-4.p-4` | |
| PAGE-04 | Page header: NOT a Card — div with h1 + p + Button | |
| PAGE-04 | Section order: KPI → Chart → Table | |
| PAGE-04 | KPI grid: `grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4` | |
| PAGE-04 | Chart grid: `grid grid-cols-1 gap-4 lg:grid-cols-2` | |

### Card Structure

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| CARD | Every section (KPI group, chart, table) wrapped in Card | |
| CARD | No Card double-wrapping (Card inside Card) | |
| CARD | Every Card has CardHeader with at least CardTitle | |
| CARD-02 | Chart inside Card > CardContent > ChartContainer | |
| CARD-02 | ChartContainer has `min-h-[VALUE]` or `aspect-*` | |
| CARD-02 | `accessibilityLayer` on chart root | |

### Chart Rules

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| FORB-01 | No `<Tooltip>` or `contentStyle={{}}` — use `<ChartTooltip content={<ChartTooltipContent />} />` | |
| FORB-01 | No `stroke` prop on CartesianGrid/XAxis/YAxis | |
| FORB-02 | Chart colors defined in chartConfig, referenced as `var(--color-KEY)` | |
| TOKEN | No hardcoded hex/rgb/oklch in chart props | |

### Formatting

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| FMT | KPI values use `formatCurrencyCompact`/`formatCompact`/`formatDelta` from `@/lib/format` | |
| FMT-03 | All format calls have explicit locale parameter | |
| FMT-01 | No `toLocaleString()` or `Intl.NumberFormat` | |

### Forbidden Patterns

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| FORB-01 | No `style={{}}` on any element | |
| FORB-02 | No hex/rgb/oklch literals, no Tailwind color primitives | |
| FORB-03 | No raw div with border/bg as Card substitute | |
| TOKEN-01 | No `rounded-md`, `rounded-lg` etc. (use `rounded-[--radius]`) | |

---

## campaign-form.tsx — Form Page (PAGE-03)

### Component Imports

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| 2-tier | shadcn imports from `@/components/ui/*` directly (Card, Button, Input, Select, Field, etc.) | |
| 2-tier | No Composed imports needed (form page) | |

### Page Structure

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| PAGE-03 | Root: `div.flex.flex-col.gap-4.p-4` | |
| PAGE-03 | Page header: NOT a Card — div with Back button + h1 | |
| PAGE-03 | Single Card for entire form | |

### Field Hierarchy

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| FIELD | Card > CardContent > form > FieldGroup > FieldSet(s) | |
| FIELD | Every Input/Select/Textarea inside Field > FieldLabel | |
| FIELD | Multi-section: FieldSet + FieldSeparator (NOT multiple Cards) | |
| FIELD | FieldLegend in each FieldSet | |
| FIELD | 2-column fields: `grid grid-cols-1 gap-4 sm:grid-cols-2` inside FieldSet | |

### Form Actions

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| FIELD | Form has `id` attribute | |
| FIELD | Submit button in CardFooter with `form="form-id"` | |
| FIELD | CardFooter has `className="border-t"` | |
| FIELD | Cancel (variant="outline") + Save (type="submit") — variants distinct | |
| FIELD | Submit button NOT inside CardContent | |

### react-hook-form (if applicable)

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| FIELD-04 | Controller renders Field components | |
| FIELD-04 | `data-invalid` on Field, `aria-invalid` on Input | |
| FIELD-04 | FieldError with error state | |

### Forbidden Patterns

| Rule | Expected | Pass/Fail |
|------|----------|-----------|
| FORB-01 | No `style={{}}` on any element | |
| FORB-02 | No hex/rgb/oklch literals, no Tailwind color primitives | |
| FORB-05 | No bare `<input>`, `<select>`, `<button>` HTML tags | |
| FORB-05 | No bare Input/Select outside Field in form context | |
| FIELD | No bare `<label>` tags — use FieldLabel | |
| TOKEN-01 | No `rounded-md`, `rounded-lg` etc. (use `rounded-[--radius]`) | |

---

## Summary Template

| Page | Score | Critical Violations | Overall |
|------|-------|---------------------|---------|
| dashboard-overview.tsx | /__ | __ | |
| campaign-form.tsx | /__ | __ | |

**Verification date:** ____
**Final verdict:** ____
