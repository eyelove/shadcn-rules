# Roadmap: shadcn-rules

## Overview

This project produces a rule document system that forces AI coding tools to generate visually consistent, structurally correct shadcn/ui dashboard pages. The journey starts by establishing the token and component hierarchy foundation that all other rules depend on, then authors the full rule content (forbidden patterns, form structure, naming), then codifies page skeleton templates, and finally validates the entire system through sample generation, automated checks, and a structured evaluation loop. The deliverable is a set of CLAUDE.md and `.claude/rules/*.md` files that make AI-generated dashboard pages indistinguishable from human-authored ones in structure and consistency.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Define design tokens, 3-tier component hierarchy, Composed component stubs, and rule document format (completed 2026-03-26)
- [ ] **Phase 2: Rule Content** - Author forbidden pattern rules, form structure rules, and naming conventions
- [ ] **Phase 3: Page Templates** - Define all 4 page skeleton templates (list, detail, settings, dashboard)
- [ ] **Phase 4: Verification** - Build automated violation detection, generate sample pages, and establish evaluation + refinement loop

## Phase Details

### Phase 1: Foundation
**Goal**: The design token system, 3-tier component hierarchy, and rule document format are established so all subsequent rules have stable references to build on
**Depends on**: Nothing (first phase)
**Requirements**: TOKN-01, TOKN-02, TOKN-03, TOKN-04, TOKN-05, COMP-01, COMP-02, COMP-03, COMP-04, RFMT-01, RFMT-02, RFMT-03, RFMT-04
**Success Criteria** (what must be TRUE):
  1. A developer can read CLAUDE.md and immediately know exactly which components AI is allowed and forbidden to import
  2. All color, spacing, typography, and radius values are defined as CSS custom properties and referenced by name in component rules — no hex values or magic numbers appear anywhere in the rule files
  3. The CLAUDE.md root file is under 80 lines with a clear pointer to `.claude/rules/` for domain-scoped rules
  4. Every rule in every file has an inline WHY comment explaining its rationale
  5. Composed component interface contracts exist in rule files for all 12 components, with typed variant props and zero className passthroughs (interface-only per D-05 — no stub implementation files)
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — Token system: tokens/globals.css + .claude/rules/tokens.md (TOKN-01 through TOKN-05, RFMT-01, RFMT-03, RFMT-04)
- [x] 01-02-PLAN.md — Component contracts: .claude/rules/components.md with all 12 Composed interfaces (COMP-01 through COMP-04, RFMT-01, RFMT-03, RFMT-04)
- [x] 01-03-PLAN.md — Root rule file: CLAUDE.md at project root, ties the system together (RFMT-02)

**UI hint**: yes

### Phase 2: Rule Content
**Goal**: The complete set of behavioral rules is authored — forbidden patterns are explicit, form structure is enforced end-to-end, and naming conventions are documented — so AI has no ambiguity about what is and is not allowed
**Depends on**: Phase 1
**Requirements**: FORB-01, FORB-02, FORB-03, FORB-04, FORB-05, FORM-01, FORM-02, FORM-03, NAME-01, NAME-02, NAME-03
**Success Criteria** (what must be TRUE):
  1. A developer can look up any forbidden pattern (inline style, hardcoded color, raw div layout, direct shadcn import, bare Input) and find an explicit rule with a forbidden example AND a correct replacement example
  2. The complete form structure `Card > FormFieldSet > FormRow/FormField > Input` is documented with a canonical code example, escape hatch, and the exact component slot structure
  3. Given any component, page, or CSS file name, a developer can verify it against the naming rules without ambiguity
  4. Every escape hatch (legitimate exception path) is documented so AI does not treat the prohibition as absolute in edge cases
**Plans**: TBD

### Phase 3: Page Templates
**Goal**: All 4 dashboard page types have canonical skeleton templates that define required zones, composition order, and which Composed components fill each zone
**Depends on**: Phase 2
**Requirements**: PAGE-01, PAGE-02, PAGE-03, PAGE-04
**Success Criteria** (what must be TRUE):
  1. Given the instruction "build a list page," AI produces a page with exactly PageHeader → SearchBar → KpiCardGroup → ChartSection → DataTable — no improvised structure
  2. Given the instruction "build a settings page," AI produces a page with exactly PageHeader → Card > FormFieldSet repeated → FormActions — with cancel=outline and save=primary
  3. Given the instruction "build a detail page," AI produces a page with PageHeader (with back navigation) → TabGroup → per-tab content — not a flat single-column layout
  4. Given the instruction "build a dashboard overview," AI produces a page with PageHeader → KpiCardGroup → ChartSection (2-column) → DataTable
**Plans**: TBD
**UI hint**: yes

### Phase 4: Verification
**Goal**: The rule system is proven effective — automated checks catch mechanical violations, sample pages demonstrate all 4 page types under the rules, and a repeatable evaluation loop exists for ongoing refinement
**Depends on**: Phase 3
**Requirements**: VERF-01, VERF-02, VERF-03, VERF-04, VERF-05
**Success Criteria** (what must be TRUE):
  1. Running `check.sh` against a file with known violations (inline style, hardcoded hex, raw div layout) flags each violation in under 30 seconds
  2. A sample page exists for each of the 4 page types (list, detail, settings, dashboard overview), generated in a fresh AI context using only the rule files
  3. Each sample page passes the structured evaluation checklist with zero critical violations (rule → expected output → actual output → verdict)
  4. The fresh-context review protocol is documented and followed — no sample is evaluated in the same context window it was generated in
  5. The refinement loop process is documented so rule updates from evaluation findings can be applied systematically
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 3/3 | Complete   | 2026-03-26 |
| 2. Rule Content | 0/TBD | Not started | - |
| 3. Page Templates | 0/TBD | Not started | - |
| 4. Verification | 0/TBD | Not started | - |
