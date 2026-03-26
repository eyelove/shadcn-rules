# Phase 2: Rule Content - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Author the complete set of behavioral rules on top of the Phase 1 foundation. Forbidden patterns get explicit Good/Bad examples in a dedicated file. Form rules gain validation and layout depth. Naming conventions cover files and directory structure. After this phase, AI has zero ambiguity about what is and is not allowed.

</domain>

<decisions>
## Implementation Decisions

### Forbidden Patterns
- **D-01:** Create a new `.claude/rules/forbidden.md` file — a dedicated catalogue of all forbidden patterns with FORBIDDEN/CORRECT code pairs.
- **D-02:** Consolidate patterns already scattered in tokens.md and components.md into forbidden.md as the single source of truth. Keep brief reminders in tokens.md/components.md pointing to forbidden.md.
- **D-03:** Cover all 5 FORB requirements: inline style, hardcoded color, div layout, shadcn direct import, bare Input.
- **D-04:** Each forbidden pattern includes: rule statement, WHY comment, FORBIDDEN code example, CORRECT code example.

### Form Rules
- **D-05:** Create a new `.claude/rules/forms.md` file for comprehensive form rules.
- **D-06:** Include validation patterns: required field indicators, error message display convention, how FormField surfaces validation state.
- **D-07:** Include layout rules: FormRow cols usage, FormFieldSet spacing, FormActions positioning.
- **D-08:** Include canonical end-to-end form example: complete form page from PageHeader to FormActions.
- **D-09:** Phase 1 established form structure (FormFieldSet > FormRow > FormField > Input). Phase 2 adds the behavioral rules on top.

### Naming Conventions
- **D-10:** Create a new `.claude/rules/naming.md` file.
- **D-11:** File naming rules:
  - Page files: kebab-case (`campaign-list.tsx`, `campaign-form.tsx`)
  - Composed components: PascalCase (`DataTable.tsx`, `SearchBar.tsx`)
  - Hook files: camelCase with `use` prefix (`useFilters.ts`, `usePagination.ts`)
  - Type files: PascalCase (`Campaign.ts`, `AdGroup.ts`)
- **D-12:** Directory structure rules:
  - `components/ui/` — shadcn primitives (auto-managed, do not edit)
  - `components/composed/` — project wrappers (AI creates here)
  - `app/` or `pages/` — page files (framework-dependent)
  - `hooks/` — custom hooks
  - `types/` — shared type definitions
  - `tokens/` — CSS custom property files

### Escape Hatches
- **D-13:** Every rule file must have an Escape Hatch section documenting legitimate exception paths.
- **D-14:** Escape hatches must describe the PROCESS (ask → approve → implement) not just "it's okay sometimes."

### Claude's Discretion
- Exact forbidden patterns to add beyond the 5 FORB requirements (based on test observations)
- Form validation depth (basic required/error vs comprehensive validation framework)
- Additional naming rules beyond file/directory (CSS variable naming, etc.)
- Whether to update check-rules.sh to cover new forbidden patterns

### Improvements from Phase 1 Testing
- **D-15:** Phase 1 tests revealed: Recharts Tooltip uses `contentStyle={{}}` which looks like inline style. forbidden.md must explicitly address the third-party library exception with concrete examples.
- **D-16:** Phase 1 tests showed all 4 samples used `@/components/composed` (barrel) consistently. Naming rules should reinforce the barrel export pattern.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Rule Files (Phase 1 output — modify/extend, don't duplicate)
- `.claude/rules/tokens.md` — Token rules with forbidden color patterns already included
- `.claude/rules/components.md` — Component rules with tier model, import rules, library styling guide
- `.claude/rules/component-interfaces.md` — 13 Composed component interface contracts
- `CLAUDE.md` — Root rule file (24 lines)

### Test Artifacts (validation reference)
- `tests/samples/campaign-list.tsx` — List page sample (passed all checks)
- `tests/samples/dashboard-overview.tsx` — Dashboard sample (passed all checks)
- `tests/samples/campaign-detail.tsx` — Detail page sample (passed all checks)
- `tests/samples/campaign-form.tsx` — Form page sample (passed all checks)
- `scripts/check-rules.sh` — Automated violation checker

### Idea Document
- `/Users/eyelove/workspace/cc-note/ideas/2026-03-25-ai-dashboard-design-workflow/ai-dashboard-design-workflow.md` — Form structure rules, forbidden/allowed pattern examples

### Project Research
- `.planning/research/PITFALLS.md` — Rule volume limits, escape hatch pitfalls
- `.planning/research/FEATURES.md` — Feature categorization (forbidden patterns are table stakes)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/check-rules.sh` — 15-check automated violation script; should be extended for new forbidden patterns
- `tests/samples/*.tsx` — 4 validated sample pages as positive reference
- Phase 1 rule files are stable and tested — extend, don't rewrite

### Established Patterns
- Rule files use YAML frontmatter with `paths:` for scope
- Imperative English tone with `// WHY:` comments
- Good/Bad code examples where contrast is high-value
- ~120 lines per rule file budget

### Integration Points
- CLAUDE.md `@import` directives need updating for new rule files
- forbidden.md should cross-reference tokens.md and components.md
- forms.md should reference component-interfaces.md for Props contracts
- naming.md should reference the existing directory structure

</code_context>

<specifics>
## Specific Ideas

- Idea document has detailed forbidden/allowed pattern examples for forms (lines 316-387)
- Check-rules.sh already validates 13 forbidden patterns — new rules should be checkable
- Phase 1 test results show existing rules are effective; Phase 2 adds depth, not breadth

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-rule-content*
*Context gathered: 2026-03-26*
