# Phase 3: Page Templates - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Define all 4 dashboard page skeleton templates as TSX code examples in a dedicated rule file. Each template specifies the required Composed component sequence so AI produces structurally identical pages regardless of prompt wording.

</domain>

<decisions>
## Implementation Decisions

### Page Template File
- **D-01:** Create `.claude/rules/page-templates.md` — a single file containing all 4 page type skeletons.
- **D-02:** Each template is a complete TSX code example showing the required component sequence with placeholder props.
- **D-03:** Include FORBIDDEN structure example per template (what AI must NOT produce).

### Four Page Types (from Phase 1 D-08)
- **D-04:** **List Page**: PageLayout → PageHeader(title, action) → SearchBar(filters) → DataTable(columns, data)
- **D-05:** **Dashboard Page**: PageLayout → PageHeader(title, subtitle, action) → KpiCardGroup(cols=4) → ChartSection(cols=2) → DataTable
- **D-06:** **Form Page**: PageLayout → PageHeader(title, backHref) → form → FormFieldSet(s) → FormActions
- **D-07:** **Detail Page**: PageLayout → PageHeader(title, backHref, action=StatusBadge) → KpiCardGroup → ChartSection → DataTable

### Template Quality
- **D-08:** Templates reference ONLY Composed components from component-interfaces.md — no primitives.
- **D-09:** Templates should match the structure of existing test samples (tests/samples/*.tsx) which have been validated.
- **D-10:** Wire page-templates.md into CLAUDE.md via @import.

### Claude's Discretion
- Whether to include optional sections per template (e.g., empty state hints, loading state)
- Level of detail in placeholder props
- Whether Detail page needs TabGroup (Phase 1 D-08 mentioned it, test sample used flat KPI+Chart+Table)

</decisions>

<canonical_refs>
## Canonical References

### Validated Test Samples (match templates to these)
- `tests/samples/campaign-list.tsx` — List page reference
- `tests/samples/dashboard-overview.tsx` — Dashboard page reference
- `tests/samples/campaign-form.tsx` — Form page reference
- `tests/samples/campaign-detail.tsx` — Detail page reference

### Existing Rule Files
- `.claude/rules/component-interfaces.md` — Props contracts templates must reference
- `.claude/rules/components.md` — Tier model and import rules
- `.claude/rules/forms.md` — Form structure rules (templates must be consistent)
- `CLAUDE.md` — Will need @import for page-templates.md

### Idea Document
- `/Users/eyelove/workspace/cc-note/ideas/2026-03-25-ai-dashboard-design-workflow/ai-dashboard-design-workflow.md` — Original page type definitions (lines 163-191)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- 4 test samples are the validated reference implementations — templates should extract their structure
- check-rules.sh has 18 checks — may need extension for page structure validation

### Established Patterns
- Rule files use YAML frontmatter with paths: for scope
- Imperative English tone with // WHY: comments
- ~120 lines per file budget

</code_context>

<specifics>
## Specific Ideas

- Test samples already demonstrate the exact structures — templates are essentially formalizing what was validated
- Detail page in test sample used flat structure (KPI → Chart → DataTable), not TabGroup from original D-08. Templates should match the tested pattern.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-page-templates*
*Context gathered: 2026-03-26*
