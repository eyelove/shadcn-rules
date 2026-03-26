# Project Research Summary

**Project:** shadcn-rules — AI-enforced UI component rules for shadcn/ui dashboards
**Domain:** Rule document system / Design system enforcement
**Researched:** 2026-03-26
**Confidence:** HIGH

## Executive Summary

This project is a rule document system — not a runtime application. It produces CLAUDE.md and scoped `.claude/rules/*.md` files that instruct AI coding tools to generate visually consistent dashboard pages using a strict 3-tier component hierarchy (Primitive → Composed → Page). The proven approach is to build the rule authoring layer and the Composed component stub layer in lockstep, then validate rule effectiveness by asking AI to generate sample pages and evaluating output with both automated grep checks and fresh-context semantic review. The stack is lean: shadcn/ui CLI 4.x, Tailwind v4 with `@theme` CSS tokens, TypeScript, ESLint with custom rules, and Playwright for page-level visual regression.

The most important architectural insight from research is that rules alone cannot override strong AI training signals. Every prohibition rule ("never use raw `<div>`") must be backed by a corresponding Composed component that makes the prohibition structurally unnecessary. A rules-first, component-light system degrades over time; a component-first system with backup prohibition rules stays stable. The recommended ratio is 4:1 — four "use X component" directives for every one "never use Y."

The highest-risk failure modes are (1) rule file bloat past the ~1,500 token threshold where LLMs silently drop mid-document rules, and (2) using the same AI session for both generation and validation — a self-review loop that produces false confidence. Both must be designed against from day one, not retrofitted. The feedback loop architecture (Author Rule → Generate Sample → Automated Check → Fresh-Context Semantic Review → Refine Rule) is the core process this project operationalizes.

---

## Key Findings

### Recommended Stack

The stack centers on the official shadcn/ui CLI v4.1.0 and Tailwind CSS v4.2.2. Tailwind v4's `@theme` directive defines design tokens as CSS custom properties and generates utility classes simultaneously — eliminating the JS config file and providing a single source of truth for all color, spacing, and radius values. CVA (class-variance-authority) 0.7.1 provides the variant API for Composed components, matching shadcn/ui's internal pattern. For violation detection, ESLint 10.x with typescript-eslint 8.x enables type-aware AST traversal custom rules; grep-based shell scripts provide the fast-path CI check for the top forbidden patterns.

For rule document formats, CLAUDE.md is the primary target (Claude Code reads it automatically at session start), with `.claude/rules/*.md` for path-scoped modular rules. AGENTS.md serves as a cross-tool secondary target. `.cursor/rules/*.mdc` adds Cursor glob-based scoping. Visual validation uses Playwright `toHaveScreenshot()` for page-level regression (self-hosted, zero cost) or Storybook + Lost Pixel for component-level regression — both free alternatives to Chromatic/Percy.

**Core technologies:**
- shadcn/ui CLI 4.1.0: install and distribute components via registry JSON
- Tailwind CSS 4.2.2: `@theme` CSS-first token system, no JS config required
- TypeScript 6.0.2: type-safe component prop contracts, custom ESLint rule authoring
- CVA 0.7.1: variant API matching shadcn/ui's internal pattern
- ESLint 10.1.0 + typescript-eslint 8.57.2: custom AST rules for design system enforcement
- Playwright 1.58.2: self-hosted visual regression for sample pages
- CLAUDE.md + `.claude/rules/*.md`: primary AI rule consumption format

### Expected Features

Research identifies a clear P1/P2/P3 split. All P1 features are low-to-medium implementation cost with high user value — the ratio is favorable for a focused v1.

**Must have (table stakes — P1):**
- 3-tier component hierarchy definition (Primitive/Composed/Page) with explicit tier ownership
- Component usage rules (allowed/forbidden imports with exact import paths)
- Forbidden pattern explicit list (inline styles, hardcoded colors, raw `<div>` layout, direct shadcn primitive imports)
- Design token governance rules (all color/spacing/radius via CSS custom properties, no hex values)
- Form structure rules (FormFieldSet → FormField → Input hierarchy, full shadcn form primitive encapsulation)
- Page skeleton templates for 4 types: Dashboard overview, List/Table, Detail/View, Settings
- Rule document format (CLAUDE.md root + path-scoped `.claude/rules/*.md`)
- Basic violation detection script (grep-based, top 5 forbidden patterns, runs in under 30 seconds)

**Should have (competitive — P2, add after v1 validation):**
- Sample page generation (one exemplar per page type for end-to-end rule verification)
- Rule effectiveness evaluation checklist (rule → expected output → actual output → verdict)
- Naming convention rules (file/component/class naming suffixes)
- Accessibility baseline rules (ARIA roles, forbidden interactive div patterns)
- Scoped rule activation documentation (when file growth or rule conflicts require modular splitting)

**Defer (v2+ — P3):**
- Iterative refinement loop documentation (only valuable after multiple rule iterations)
- Escape hatch documentation (edge cases only emerge from real usage)
- Context window budget guidance (measure empirically first)
- Rule rationale annotation pass (add only to rules that demonstrably fail without explanation)

**Anti-features to avoid entirely:**
- Full ESLint plugin as npm package (over-engineering; use `--rulesdir` or inline `eslint.config.js`)
- Figma-to-code token sync (code-only workflow; Figma adds external dependency)
- Universal/generic rules not dashboard-specific (dilutes specificity; AI already knows generic rules)
- Real-time AI validation during generation (agentic feedback loop, orders of magnitude more complex)

### Architecture Approach

The system has four functional layers: Rule Authoring (CLAUDE.md, `.claude/rules/*.md`, `tokens.css`), AI Tool Consumption (Claude Code reads rule files at session start with path targeting), Sample Project (AI-generated pages that use only the Composed layer), and Validation & Feedback (ESLint custom rules + grep checks + fresh-context semantic review). The key insight is that this is a documentation system, not a runtime application — "build order" means authoring order. Tokens must be defined before component rules can reference them; Composed component stubs must exist before page skeleton templates can reference them.

**Major components:**
1. `CLAUDE.md` (root, under 200 lines) — universal rules loaded every session
2. `.claude/rules/*.md` (path-targeted, modular) — domain-scoped rules loaded only for matching file contexts
3. `rules/` directory (human-readable canonical source) — the authoritative source; CLAUDE.md and tool files are derived from this
4. `tokens/globals.css` + `tailwind.config.ts` — single source of truth for all design tokens
5. Composed component stubs (`components/blocks/`) — the only layer AI is permitted to use in page files
6. `samples/` directory — AI-generated reference pages that prove rules produce correct output
7. `validation/check.sh` + ESLint design rules — automated violation detection post-generation

### Critical Pitfalls

1. **Rule file bloat causes silent compliance drift** — Cap root CLAUDE.md at 80-120 lines. Every rule must pass the deletion test. Split into `.claude/rules/` with path targeting when content exceeds ~200 lines. Put the most critical rules in the first 30 and last 20 lines (U-curve attention effect).

2. **Composed component layer leaks shadcn primitives** — Composed components must not accept `className` or raw shadcn prop passthroughs. Use explicit typed variant props (`variant: "primary" | "secondary"`) only. Review every Composed component interface before rules reference it. This must be resolved in Phase 1.

3. **Self-review loop uses the generator as the validator** — Always evaluate generated code in a fresh context window with only the code and rules document — no generation history. Use structured audit prompts that force enumeration before judgment. This is non-negotiable from the first validation cycle.

4. **Rules-first, component-light system degrades over time** — For every major prohibition, build the corresponding Composed component first. Treat prohibition rules as temporary scaffolding until the Composed component exists. Target 4:1 ratio of "use X" directives to "never use Y" directives.

5. **Form rules inconsistent with shadcn form primitive structure** — Composed form components must fully encapsulate the `FormField > FormItem > FormLabel + FormControl + FormMessage` chain. Rules must show the exact slot structure once with a code example. Test for `htmlFor`/`id` linkage before rules are finalized.

---

## Implications for Roadmap

Based on combined research, the dependency graph mandates a specific authoring order. Token definitions gate component rules; Composed component stubs gate page templates; both gate sample generation; sample generation gates validation; validation gates the refinement loop. This naturally produces a 3-phase structure.

### Phase 1: Foundation — Tokens, Hierarchy, and Core Rules

**Rationale:** Everything else depends on this. Token names must exist before rules can reference them. Composed component stubs must exist before page templates can reference them. Rule document format must be established before content is written (format decisions are path-dependent). PITFALLS.md is unambiguous: 6 of 10 pitfalls must be addressed in this phase or they compound irreversibly.

**Delivers:**
- Design token system (`tokens/globals.css` + `tailwind.config.ts`)
- 3-tier component hierarchy definition with explicit tier ownership
- Composed component stubs for all referenced components (at minimum: `DataTable`, `FormFieldSet`, `PageHeader`, `ActionButton`, `StatusBadge`, `DataCard`)
- Component usage rules (allowed/forbidden with exact import paths)
- Forbidden pattern explicit list
- Design token governance rules
- Form structure rules with full shadcn primitive encapsulation
- Rule document format established: root CLAUDE.md under 80 lines, `.claude/rules/` structure defined
- Composed component interface audit (zero `className` passthroughs, typed variant props only)

**Avoids:** Pitfalls 1 (rule bloat), 3 (composed layer leaks), 8 (rule format degrades AI), 9 (rules-first over component-first), 10 (form rule inconsistency)

**Research flag:** Standard patterns — well-documented. No phase research needed.

---

### Phase 2: Page Templates and Sample Generation

**Rationale:** Page skeleton templates depend on knowing which Composed components exist (Phase 1 delivers this). Sample page generation depends on complete skeleton templates plus component rules plus token rules — all three must exist before a sample page can be a valid integration test. The validation system (including the semantic review tier) must be designed before samples are generated, not after.

**Delivers:**
- Page skeleton templates for all 4 types (Dashboard, List/Table, Detail/View, Settings) with required zones and canonical composition order (`PageHeader > Filters > DataTable > Pagination`)
- Sample page generation: one exemplar per page type, including empty/error/loading state variants (not just happy path)
- Two-tier validation system: (1) `validation/check.sh` grep-based mechanical checks, (2) structure checklist per page type for semantic review
- Fresh-context review protocol established and documented
- Rule effectiveness evaluation checklist (rule → expected output → actual output → verdict)

**Implements:** Sample-Evaluate-Refine Loop architectural pattern; Dual-Layer Executable Rule Enforcement pattern

**Avoids:** Pitfalls 5 (validation catches only syntax), 6 (happy-path-only samples), 7 (self-review false confidence)

**Research flag:** Standard patterns — well-documented. No phase research needed.

---

### Phase 3: Refinement and v1.x Features

**Rationale:** Refinement requires observed violations from real validation cycles. Naming convention rules, accessibility rules, and scoped rule activation documentation are all trigger-based additions — add only when the triggering condition is observed in practice. Context window budget guidance and escape hatch documentation require empirical data that only exists after Phase 2.

**Delivers:**
- First iteration of the refinement loop (rules updated based on Phase 2 evaluation output)
- Naming convention rules (triggered by: inconsistent naming observed)
- Accessibility baseline rules (triggered by: missing ARIA attributes in generated components)
- Scoped rule activation documentation (triggered by: rules file length or cross-page-type conflicts)
- AGENTS.md and `.cursorrules` secondary tool files (derived from canonical `rules/` directory)
- "Looks Done But Isn't" checklist verification pass

**Avoids:** Pitfall 2 (over-policing — false positive rate above 15% signals rule revision needed), Pitfall 4 (token system over-engineered — token reference must fit in under 30 lines)

**Research flag:** Refinement loop patterns are well-documented. Accessibility integration with shadcn/ui radix primitives is well-covered. No phase research needed.

---

### Phase Ordering Rationale

- Token-first is mandatory: ARCHITECTURE.md build order is explicit — `tokens/globals.css` must be committed before any rule can reference a token name. Violating this causes Pitfall 4 (token layer ignored by AI, must be retrofitted).
- Composed stubs before page templates: PITFALLS.md Pitfall 3 states unambiguously — "AI will not wait" for components to be built; it will improvise. Rules can only reference components that exist.
- Sample generation gates validation design: ARCHITECTURE.md and PITFALLS.md both confirm the validation system must be designed before the first sample is generated. Retrofitting the semantic review tier after 10 sample pages is costly.
- Refinement deferred to Phase 3: FEATURES.md confirms the iterative refinement loop is only valuable after enough rule iterations have occurred to justify a documented process.

### Research Flags

Phases with standard patterns (skip `/gsd:research-phase`):
- **Phase 1:** shadcn/ui component composition, Tailwind v4 token system, and ESLint custom rule authoring are all thoroughly documented with official sources.
- **Phase 2:** Page skeleton patterns for dashboards, sample page generation workflows, and two-tier validation approaches are well-established.
- **Phase 3:** Rule refinement loop and AGENTS.md/Cursor secondary formats are documented across multiple credible sources.

No phase requires deeper research before roadmap creation.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Core stack verified via npm registry + official docs (Tailwind v4, shadcn CLI v4, typescript-eslint v8 flat config). Rule format section MEDIUM — ecosystem evolving. |
| Features | HIGH (core), MEDIUM (enforcement tooling), LOW (self-eval loop) | Core rule categories well-understood. Automated enforcement tooling has fewer production examples. Self-evaluation loop patterns are inferred from general LLM behavior research. |
| Architecture | HIGH | Verified across official Claude Code docs, shadcn/ui docs, and multiple independent practitioner sources. Build order is explicit and cross-validated. |
| Pitfalls | HIGH | Well-sourced: U-curve attention effect (LLM research), composed layer leaks (practitioner experience), self-review loop failure (LLM evaluation research), form primitive inconsistency (shadcn-specific). |

**Overall confidence:** HIGH

### Gaps to Address

- **Rule format evolution:** AGENTS.md is a relatively new cross-tool standard (mid-2025). Its consumption behavior in tools other than Claude Code is MEDIUM confidence. Validate against Cursor in Phase 3 when secondary tool files are authored.
- **Composed component count limit:** PITFALLS.md notes AI confusion above ~20 Composed components. The optimal count for the initial stub library is not precisely known — start with ~8-10 core components and expand based on observed AI improvisation.
- **LLM-specific rule adherence thresholds:** The 80-120 line / 1,500 token cap is well-supported but may vary across Claude model versions. The threshold should be treated as a guideline, not a hard limit — verify empirically during Phase 2 sample generation.

---

## Sources

### Primary (HIGH confidence)
- [Tailwind CSS v4.0 release announcement](https://tailwindcss.com/blog/tailwindcss-v4) — `@theme` directive, CSS-first config
- [shadcn/ui Registry Introduction](https://ui.shadcn.com/docs/registry) — registry system, CLI v4
- [Best Practices for Claude Code](https://code.claude.com/docs/en/best-practices) — CLAUDE.md format, scoped rules, context window behavior
- [typescript-eslint Custom Rules](https://typescript-eslint.io/developers/custom-rules/) — AST rule authoring
- [Atlassian ESLint plugin — ensure-design-token-usage](https://atlassian.design/components/eslint-plugin-design-system/ensure-design-token-usage/) — reference implementation for token enforcement
- [Using Linters to Direct Agents — Factory.ai](https://factory.ai/news/using-linters-to-direct-agents) — linting for AI agents, false positive rates
- npm registry (verified 2026-03-26) — all version numbers

### Secondary (MEDIUM confidence)
- [Vercel Academy: Extending shadcn/ui with Custom Components](https://vercel.com/academy/shadcn-ui/extending-shadcn-ui-with-custom-components) — CVA composition patterns
- [Claude Code Rules Directory — claudefa.st](https://claudefa.st/blog/guide/mechanics/rules-directory) — modular rules with path targeting
- [AI Keeps Breaking Your Architectural Patterns — dev.to](https://dev.to/vuong_ngo/ai-keeps-breaking-your-architectural-patterns-documentation-wont-fix-it-4dgj) — path-based pattern matching, 80% vs 30-40% compliance
- [How LLMs Ignore Middle of Context Window — Medium](https://charlesanthonybrowne.medium.com/how-llms-end-up-ignoring-the-middle-of-a-context-window-c8662000eb67) — U-shaped attention curve
- [Don't Use Tailwind for Your Design System — sancho.dev](https://sancho.dev/blog/tailwind-and-design-systems) — className escape hatch failure mode
- [AGENTS.md standard](https://agents.md/) — cross-tool rule format specification
- [Cursor Rules Documentation](https://cursor.com/docs/context/rules) — `.mdc` format, activation modes

### Tertiary (LOW confidence)
- [AI-Driven Design System Governance — stldigital.tech](https://www.stldigital.tech/blog/ai-as-a-design-system-governor-enforcing-architectural-consistency/) — enforcement engine patterns (single source)

---
*Research completed: 2026-03-26*
*Ready for roadmap: yes*
