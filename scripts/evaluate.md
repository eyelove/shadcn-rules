# Sample Page Evaluation Checklist

Run `bash scripts/check-rules.sh tests/samples/` first. This checklist covers structural and semantic checks that grep cannot automate.

**Instructions:**
1. Open each sample file in your editor
2. For each row: read the Expected column, check the Actual output in the file, mark Pass/Fail
3. Critical violation = rule broken at the structural level (wrong component hierarchy, forbidden import, inline style)
4. Minor violation = deviation that does not break structure (missing mock data, suboptimal prop value)
5. A sample "passes" when it has zero critical violations

---

## campaign-list.tsx — List Page (PAGE-01)

### Component Hierarchy

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| COMP-02 | All UI imports from @/components/composed barrel only | Single import from `@/components/composed`: PageLayout, PageHeader, SearchBar, DataTable, ActionButton, StatusBadge | Pass |
| COMP-03 | No import from @/components/ui/ | No @/components/ui/ import present | Pass |
| PAGE-01 | Structure: PageLayout → PageHeader → SearchBar → DataTable | PageLayout wraps PageHeader, SearchBar, DataTable in order | Pass |
| PAGE-01 | No KpiCardGroup present | KpiCardGroup not imported or used | Pass |
| PAGE-01 | No ChartSection present | ChartSection not imported or used | Pass |
| PAGE-01 | No TabGroup present | TabGroup not imported or used | Pass |

### Forbidden Patterns

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| FORB-01 | No style={{}} on any element | No style={{}} attributes found | Pass |
| FORB-02 | No hex/rgb/oklch literals | No hex/rgb/oklch literals found | Pass |
| FORB-02 | No bg-zinc/bg-gray/bg-slate Tailwind primitives | No Tailwind color primitives found | Pass |
| FORB-03 | No <div className="flex..."> layout wrappers | No raw div layout wrappers found | Pass |
| FORB-04 | No import from @/components/ui/ | Not present | Pass |
| FORB-05 | No bare <Input> outside <FormField> | No Input elements used (list page, no form) | Pass |

### Naming

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| NAME-01 | File named campaign-list.tsx (kebab-case) | campaign-list.tsx | Pass |
| NAME-02 | Import from @/components/composed (barrel, not direct file) | `from "@/components/composed"` (barrel) | Pass |
| NAME-03 | No CSS variable definitions in TSX file | No `--var:` definitions in file | Pass |

**Score: 15/15 Pass | Critical violations: 0**

---

## campaign-detail.tsx — Detail Page (PAGE-02)

### Component Hierarchy

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| COMP-02 | All UI imports from @/components/composed barrel only | All UI imports from `@/components/composed`; recharts imports are chart library (not UI components) | Pass |
| PAGE-02 | Structure: PageLayout → PageHeader(backHref, action=StatusBadge) → KpiCardGroup → ChartSection → DataTable | PageLayout → PageHeader(backHref="/campaigns", action={StatusBadge}) → KpiCardGroup(cols=4) → ChartSection(cols=1) → DataTable | Pass |
| PAGE-02 | No TabGroup (flat structure required) | TabGroup not imported or used | Pass |
| PAGE-02 | PageHeader has backHref prop | `backHref="/campaigns"` present | Pass |
| PAGE-02 | PageHeader has action=StatusBadge | `action={<StatusBadge status="active" />}` present | Pass |
| PAGE-02 | ChartSection has cols={1} | `<ChartSection cols={1} ...>` | Pass |
| PAGE-02 | KpiCardGroup present with cols prop | `<KpiCardGroup cols={4} items={kpiItems} />` | Pass |

### Forbidden Patterns

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| FORB-01 | No style={{}} on any element | `contentStyle={{...}}` is a recharts Tooltip prop (not a DOM style attribute) — no DOM style={{}} present | Pass |
| FORB-02 | No hex/rgb/oklch literals | No hex/rgb/oklch literals; var(--token) used for chart colors | Pass |
| FORB-03 | No <div className="flex..."> layout wrappers | No raw div layout wrappers found | Pass |
| FORB-04 | No import from @/components/ui/ | Not present | Pass |
| FORB-05 | No bare <Input> outside <FormField> | No Input elements used (detail page, no form) | Pass |

### Naming

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| NAME-01 | File named campaign-detail.tsx (kebab-case) | campaign-detail.tsx | Pass |
| NAME-02 | Import from @/components/composed (barrel) | `from "@/components/composed"` (barrel) | Pass |

**Score: 14/14 Pass | Critical violations: 0**

---

## campaign-form.tsx — Form / Settings Page (PAGE-03)

### Component Hierarchy

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| COMP-02 | All UI imports from @/components/composed barrel only | Single import from `@/components/composed`: PageLayout, PageHeader, FormFieldSet, FormRow, FormField, FormActions, ActionButton, Input, Select, Textarea, DateRangePicker | Pass |
| PAGE-03 | Structure: PageLayout → PageHeader(backHref) → form → FormFieldSet(s) → FormActions | PageLayout → PageHeader(backHref="/campaigns") → form → FormFieldSet("Basic Info") → FormFieldSet("Budget & Schedule") → FormActions | Pass |
| PAGE-03 | PageHeader has backHref prop | `backHref="/campaigns"` present | Pass |
| FORM-01 | FormActions is a sibling of FormFieldSet (not nested inside it) | FormActions appears after both FormFieldSets, outside them, as sibling | Pass |
| FORM-02 | Cancel (variant="outline") appears BEFORE Save (type="submit") in FormActions | `<ActionButton variant="outline">Cancel</ActionButton>` then `<ActionButton type="submit">Save</ActionButton>` | Pass |
| FORM-01 | FormField wraps every Input/Select/Textarea/Checkbox | All Input, Select, Textarea, DateRangePicker elements are wrapped in FormField | Pass |
| FORM-01 | At least one FormFieldSet present | Two FormFieldSets present: "Basic Info" and "Budget & Schedule" | Pass |

### Forbidden Patterns

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| FORB-01 | No style={{}} on any element | No style={{}} attributes found | Pass |
| FORB-02 | No hex/rgb/oklch literals | No hex/rgb/oklch literals found | Pass |
| FORB-03 | No <div className="flex..."> layout wrappers | No raw div layout wrappers; FormRow used for grid layout | Pass |
| FORB-04 | No import from @/components/ui/ | Not present | Pass |
| FORB-05 | No bare <Input> outside <FormField> | All Input elements inside FormField | Pass |
| FORM-03 | No bare <input> (lowercase) element | No bare <input> found | Pass |
| FORM-03 | No bare <label> element | No bare <label> found | Pass |

### Naming

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| NAME-01 | File named campaign-form.tsx (kebab-case) | campaign-form.tsx | Pass |
| NAME-02 | Import from @/components/composed (barrel) | `from "@/components/composed"` (barrel) | Pass |

**Score: 16/16 Pass | Critical violations: 0**

---

## dashboard-overview.tsx — Dashboard Overview Page (PAGE-04)

### Component Hierarchy

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| COMP-02 | All UI imports from @/components/composed barrel only | All UI imports from `@/components/composed`; recharts imports are chart library (not UI components) | Pass |
| PAGE-04 | Structure: PageLayout → PageHeader → KpiCardGroup → ChartSection(cols=2) → DataTable | PageLayout → PageHeader → KpiCardGroup(cols=4) → ChartSection(cols=2) → DataTable | Pass |
| PAGE-04 | KpiCardGroup present (not omitted) | `<KpiCardGroup cols={4} items={kpiItems} />` present | Pass |
| PAGE-04 | ChartSection has cols={2} — CRITICAL requirement | `<ChartSection cols={2} charts={[...]} />` | Pass |
| PAGE-04 | DataTable appears AFTER ChartSection (not before) | DataTable follows ChartSection in JSX order | Pass |
| PAGE-04 | ChartSection has at least 2 chart entries | Two charts: DailySpendChart and ChannelSplitChart | Pass |

### Forbidden Patterns

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| FORB-01 | No style={{}} on any element | `contentStyle={{...}}` is a recharts Tooltip prop (not DOM style={{}}); no DOM style={{}} present | Pass |
| FORB-02 | No hex/rgb/oklch literals | No hex/rgb/oklch literals; var(--token) used for chart colors | Pass |
| FORB-03 | No <div className="flex..."> layout wrappers | No raw div layout wrappers found | Pass |
| FORB-04 | No import from @/components/ui/ | Not present | Pass |
| FORB-05 | No bare <Input> outside <FormField> | No Input elements used (dashboard page, no form) | Pass |

### Naming

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| NAME-01 | File named dashboard-overview.tsx (kebab-case) | dashboard-overview.tsx | Pass |
| NAME-02 | Import from @/components/composed (barrel) | `from "@/components/composed"` (barrel) | Pass |

**Score: 14/14 Pass | Critical violations: 0**

---

## Summary

| Page | Score | Critical Violations | Overall |
|------|-------|---------------------|---------|
| campaign-list.tsx | 15/15 | 0 | Pass |
| campaign-detail.tsx | 14/14 | 0 | Pass |
| campaign-form.tsx | 16/16 | 0 | Pass |
| dashboard-overview.tsx | 14/14 | 0 | Pass |

**Total: 59/59 | System verdict: Pass (0 critical violations across all pages)**

### Violations Found

None. All 4 samples passed every check.

### Notes on Recharts contentStyle

`contentStyle={{...}}` in Tooltip components (campaign-detail.tsx, dashboard-overview.tsx) is a recharts library prop, not a DOM `style={{}}` attribute. It accepts an object to style the tooltip popup and is the only supported API for that component. This is correct usage — it does not violate FORB-01 (which targets direct DOM style attributes on layout elements). The check-rules.sh script correctly passes both files.

### Next Step

All checks pass. Rule system verified.

---

**Verification date:** 2026-03-26
**Final verdict:** PASS — zero critical violations
**Automated check exit code:** 0
