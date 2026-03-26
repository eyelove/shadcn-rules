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
| COMP-02 | All UI imports from @/components/composed barrel only | | |
| COMP-03 | No import from @/components/ui/ | | |
| PAGE-01 | Structure: PageLayout → PageHeader → SearchBar → DataTable | | |
| PAGE-01 | No KpiCardGroup present | | |
| PAGE-01 | No ChartSection present | | |
| PAGE-01 | No TabGroup present | | |

### Forbidden Patterns

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| FORB-01 | No style={{}} on any element | | |
| FORB-02 | No hex/rgb/oklch literals | | |
| FORB-02 | No bg-zinc/bg-gray/bg-slate Tailwind primitives | | |
| FORB-03 | No <div className="flex..."> layout wrappers | | |
| FORB-04 | No import from @/components/ui/ | | |
| FORB-05 | No bare <Input> outside <FormField> | | |

### Naming

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| NAME-01 | File named campaign-list.tsx (kebab-case) | campaign-list.tsx | Pass |
| NAME-02 | Import from @/components/composed (barrel, not direct file) | | |
| NAME-03 | No CSS variable definitions in TSX file | | |

**Score: ___/15 Pass | Critical violations: ___**

---

## campaign-detail.tsx — Detail Page (PAGE-02)

### Component Hierarchy

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| COMP-02 | All UI imports from @/components/composed barrel only | | |
| PAGE-02 | Structure: PageLayout → PageHeader(backHref, action=StatusBadge) → KpiCardGroup → ChartSection → DataTable | | |
| PAGE-02 | No TabGroup (flat structure required) | | |
| PAGE-02 | PageHeader has backHref prop | | |
| PAGE-02 | PageHeader has action=StatusBadge | | |
| PAGE-02 | ChartSection has cols={1} | | |
| PAGE-02 | KpiCardGroup present with cols prop | | |

### Forbidden Patterns

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| FORB-01 | No style={{}} on any element | | |
| FORB-02 | No hex/rgb/oklch literals | | |
| FORB-03 | No <div className="flex..."> layout wrappers | | |
| FORB-04 | No import from @/components/ui/ | | |
| FORB-05 | No bare <Input> outside <FormField> | | |

### Naming

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| NAME-01 | File named campaign-detail.tsx (kebab-case) | campaign-detail.tsx | Pass |
| NAME-02 | Import from @/components/composed (barrel) | | |

**Score: ___/14 Pass | Critical violations: ___**

---

## campaign-form.tsx — Form / Settings Page (PAGE-03)

### Component Hierarchy

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| COMP-02 | All UI imports from @/components/composed barrel only | | |
| PAGE-03 | Structure: PageLayout → PageHeader(backHref) → form → FormFieldSet(s) → FormActions | | |
| PAGE-03 | PageHeader has backHref prop | | |
| FORM-01 | FormActions is a sibling of FormFieldSet (not nested inside it) | | |
| FORM-02 | Cancel (variant="outline") appears BEFORE Save (type="submit") in FormActions | | |
| FORM-01 | FormField wraps every Input/Select/Textarea/Checkbox | | |
| FORM-01 | At least one FormFieldSet present | | |

### Forbidden Patterns

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| FORB-01 | No style={{}} on any element | | |
| FORB-02 | No hex/rgb/oklch literals | | |
| FORB-03 | No <div className="flex..."> layout wrappers | | |
| FORB-04 | No import from @/components/ui/ | | |
| FORB-05 | No bare <Input> outside <FormField> | | |
| FORM-03 | No bare <input> (lowercase) element | | |
| FORM-03 | No bare <label> element | | |

### Naming

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| NAME-01 | File named campaign-form.tsx (kebab-case) | campaign-form.tsx | Pass |
| NAME-02 | Import from @/components/composed (barrel) | | |

**Score: ___/16 Pass | Critical violations: ___**

---

## dashboard-overview.tsx — Dashboard Overview Page (PAGE-04)

### Component Hierarchy

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| COMP-02 | All UI imports from @/components/composed barrel only | | |
| PAGE-04 | Structure: PageLayout → PageHeader → KpiCardGroup → ChartSection(cols=2) → DataTable | | |
| PAGE-04 | KpiCardGroup present (not omitted) | | |
| PAGE-04 | ChartSection has cols={2} — CRITICAL requirement | | |
| PAGE-04 | DataTable appears AFTER ChartSection (not before) | | |
| PAGE-04 | ChartSection has at least 2 chart entries | | |

### Forbidden Patterns

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| FORB-01 | No style={{}} on any element | | |
| FORB-02 | No hex/rgb/oklch literals | | |
| FORB-03 | No <div className="flex..."> layout wrappers | | |
| FORB-04 | No import from @/components/ui/ | | |
| FORB-05 | No bare <Input> outside <FormField> | | |

### Naming

| Rule | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| NAME-01 | File named dashboard-overview.tsx (kebab-case) | dashboard-overview.tsx | Pass |
| NAME-02 | Import from @/components/composed (barrel) | | |

**Score: ___/14 Pass | Critical violations: ___**

---

## Summary

| Page | Score | Critical Violations | Overall |
|------|-------|---------------------|---------|
| campaign-list.tsx | /15 | | Pass/Fail |
| campaign-detail.tsx | /14 | | Pass/Fail |
| campaign-form.tsx | /16 | | Pass/Fail |
| dashboard-overview.tsx | /14 | | Pass/Fail |

**Total: ___/59 | System verdict: Pass (0 critical violations across all pages) / Fail**

### Violations Found

List violations here (copy from FAIL rows above):
- [ ] [page] [Rule ID]: [description]

### Next Step

If violations found: See `docs/refinement-loop.md` for the update process.
If all pass: Rule system verified. Document date and commit evaluate.md with filled results.
