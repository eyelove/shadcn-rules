# Phase 1: Foundation - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the foundation for all subsequent rules: shadcn/ui theme token system, 3-tier component hierarchy definition, Composed component interface contracts, and the rule document format/structure. After this phase, every rule file has a stable reference to build on.

Two-layer rule architecture:
1. **Page-level patterns** — Which blocks in which order per page type (Dashboard, List, Form, Detail)
2. **Component-level templates** — Internal structure and props for each block (TitleBar, FilterBar, DataTable, etc.)

</domain>

<decisions>
## Implementation Decisions

### Token System
- **D-01:** Use shadcn/ui's existing CSS variable system (`--background`, `--foreground`, `--primary`, etc.) as the base token layer. Do not reinvent a custom token system.
- **D-02:** Extend with dashboard-specific tokens only where shadcn defaults are insufficient (e.g., `--chart-1` through `--chart-6`, `--kpi-bg`).
- **D-03:** Tokens must be short, opinionated, and directly referenced by name — no multi-hop token chains. WHY: AI collapses complex token chains to nearest familiar Tailwind primitive.

### Component Hierarchy
- **D-04:** 3-tier component hierarchy is confirmed:
  - **Primitive**: shadcn/ui originals — AI must NOT import directly
  - **Composed**: Project wrappers — AI's ONLY entry point
  - **Page**: Skeleton templates — enforce page-level structure
- **D-05:** Composed components defined at **interface level only** — component name + props type + usage example code in TSX. No stub implementation code in rule documents.
- **D-06:** Component count left to Claude's judgment, based on the idea document's component list (PageLayout, PageHeader, SearchBar, KpiCardGroup, ChartSection, DataTable, FormFieldSet, FormField, FormRow, FormActions, ConfirmDialog, StatusBadge).
- **D-07:** className passthrough is forbidden on Composed components. WHY: It gives AI a free path back to primitives, bypassing all constraints.

### Page-Level Patterns
- **D-08:** Four page types, each defined as an ordered sequence of Composed components:
  - **Dashboard**: TitleBar → FilterBar → KpiCardGroup(2 or 4) → ChartSection → DataTable
  - **List**: TitleBar → FilterBar → DataTable
  - **Form**: TitleBar → FormFieldSet(s) → FormActions
  - **Detail**: TitleBar(back nav) → TabGroup → per-tab content
- **D-09:** Templates provided as TSX code examples — AI copies/references the structure directly.

### Component-Level Templates
- **D-10:** Each Composed component template defines internal structure with TSX:
  - TitleBar: title text + primary action button(s)
  - FilterBar: search input, date range, status select, search button
  - DataTable: sortable columns, search, on/off toggles, column ordering, per-column UI, row checkboxes
  - (Other components follow same pattern)

### Rule Document Structure
- **D-11:** Modular structure: `CLAUDE.md` (overview, ~80 lines) + `.claude/rules/*.md` (domain-scoped rules).
- **D-12:** Claude Code only — no .cursorrules, no AGENTS.md.
- **D-13:** Rule file budget: ~120 lines / ~1,500 tokens per file. WHY: AI compliance drops significantly for longer files.

### Rule Writing Style
- **D-14:** Imperative tone in English ("DO use...", "NEVER use...").
- **D-15:** Example code inclusion level at Claude's discretion — may include Good/Bad pairs where contrast is high-value.
- **D-16:** Every critical rule includes inline WHY comment.

### Claude's Discretion
- Exact number of initial Composed components (guided by idea document list)
- Example code depth per rule (Good-only vs Good/Bad pairs — choose based on impact)
- Dashboard-specific token names and values

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Idea Document
- `/Users/eyelove/workspace/cc-note/ideas/2026-03-25-ai-dashboard-design-workflow/ai-dashboard-design-workflow.md` — Full design workflow with component list, page patterns, form rules, forbidden patterns, and allowed patterns. The primary source of truth for component inventory and page structure.

### Project Research
- `.planning/research/STACK.md` — Technology stack recommendations (Tailwind v4, shadcn/ui v4, rule format)
- `.planning/research/FEATURES.md` — Feature landscape with table stakes, differentiators, anti-features
- `.planning/research/ARCHITECTURE.md` — System structure, modular rules architecture, dual-layer enforcement
- `.planning/research/PITFALLS.md` — 10 critical pitfalls including rule volume, className passthrough, token over-engineering

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no existing codebase

### Established Patterns
- shadcn/ui CSS variable convention is the token standard
- shadcn/ui component naming conventions (lowercase kebab-case files, PascalCase exports)

### Integration Points
- CLAUDE.md at project root is the entry point for Claude Code
- `.claude/rules/` directory for scoped rule files

</code_context>

<specifics>
## Specific Ideas

- User's idea document already contains detailed component list with props and responsibilities — use as primary reference
- User explicitly described 2-layer architecture: page patterns (block ordering) + component templates (internal structure)
- FilterBar example from user: search input, date range, status select, search button
- DataTable example from user: sorting, search, on/off toggles, column ordering, per-column UI, row checkboxes
- Form structure from idea doc: Card > FormFieldSet > FormRow/FormField > Input — this is the canonical form pattern

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-03-26*
