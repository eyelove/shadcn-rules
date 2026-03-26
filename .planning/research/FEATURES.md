# Feature Research

**Domain:** AI-enforced UI rules system for shadcn/ui dashboards
**Researched:** 2026-03-26
**Confidence:** HIGH (core rule categories), MEDIUM (automated enforcement tooling), LOW (self-evaluation loop patterns)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features the system must have or it fails to deliver on its core promise. If these are missing, the rule set is not credible and AI agents will keep generating inconsistent code.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Component usage rules (allowed/forbidden) | Core promise: AI uses only approved components, never raw HTML or shadcn primitives directly | LOW | "Use only Composed components" — the single most critical rule category. Pairs with import path restrictions. |
| Forbidden pattern explicit list | AI needs negative constraints as much as positive ones — "never use inline style", "never use raw `<div>` for layout" | LOW | Must be exhaustive and machine-checkable. Vague prohibitions fail in practice. |
| Design token governance rules | Consistent visual output requires all color/spacing/radius values to come from CSS variables, not hardcoded values | LOW | shadcn/ui's CSS variable system already provides the token layer; rules just need to mandate it |
| 3-tier component hierarchy definition | Primitive → Composed → Page is the structural spine; without it AI re-invents structure per prompt | MEDIUM | Must define what belongs at each tier and which tier AI is allowed to touch |
| Form structure rules | Forms are the most abused area — inline labels, mixed validation patterns, inconsistent field spacing | MEDIUM | Enforce FormFieldSet → FormField → Input hierarchy explicitly |
| Page skeleton templates by type | Dashboard, List, Detail, Settings pages have distinct structural conventions; AI needs these as templates not suggestions | MEDIUM | Per-template: required zones, allowed slot components, expected data patterns |
| Naming convention rules | File names, component names, CSS class names — AI generates inconsistent names without rules | LOW | camelCase vs PascalCase distinctions, suffix conventions (Page, Layout, Widget) |
| Rule document format (readable by AI) | CLAUDE.md / .cursorrules / .windsurfrules must be structured for LLM consumption: specific, concrete, machine-readable | LOW | Verbose prose reduces compliance. Bullet lists with explicit examples outperform paragraphs. |
| Accessibility baseline rules | ARIA roles, keyboard navigation, color contrast — shadcn/ui is accessible by default but custom compositions can break it | MEDIUM | Flag required ARIA attributes, prohibit div-based interactive elements |

---

### Differentiators (Competitive Advantage)

These are not expected but dramatically increase the value of the rule system. They align with the core value: "누가 언제 만들든 시각적으로 일관된 결과."

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Automated violation detection script | Manual review doesn't scale; a grep/AST script that catches inline styles, forbidden imports, hardcoded colors creates a fast feedback loop | MEDIUM | Can be a shell script + grep patterns before needing full ESLint rules. Catches 80% of violations cheaply. |
| Sample page generation per page type | Produces a reference artifact that proves rules work end-to-end. Catches rule gaps that text review misses. | MEDIUM | Generate one exemplar page per template type (Dashboard, List, Detail, Settings). The page is the living test. |
| Rule effectiveness evaluation checklist | After generating a sample page, a structured checklist assesses whether each rule produced the expected outcome. Closes the feedback loop. | LOW | Checklist format: rule → expected output → actual output → verdict. Drives iterative rule improvement. |
| Iterative refinement loop documentation | Formalizes the rule → generate → evaluate → fix cycle. Without this, rules become stale. | LOW | Documents the loop itself as a process rule: "when a sample page violates rule X, update rule X before proceeding." |
| Context window budget guidance | Rules files that exceed optimal length cause LLMs to silently ignore sections. Guidance on what to prune vs. keep is differentiating. | LOW | Research confirms: overly long CLAUDE.md leads to partial rule adherence. Modular scoped rules (path-based) outperform monolithic files. |
| Scoped rule activation by file type | Apply component rules only to Page-level files; apply token rules everywhere. Path-pattern-based scoping reduces noise and improves compliance. | MEDIUM | Cursor supports glob-based rule scoping. CLAUDE.md supports `.claude/rules/*.md` path-scoped files. |
| Escape hatch documentation | Rules must document the legitimate exception paths explicitly, otherwise AI either ignores them (too strict) or breaks them routinely | LOW | "When to deviate and how" is as important as the rules themselves. |
| Rule rationale annotations | Rules with "why" explanations outperform bare prohibitions. "Do not use inline style BECAUSE CSS variables are the only theming surface" gives AI the reasoning to extend the rule correctly. | LOW | Annotate every critical rule with a one-sentence rationale. |

---

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem useful but actively degrade the system's reliability or create maintenance burden.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full ESLint plugin for all rules | Feels like "real enforcement" — automated, CI-integrated | Over-engineering for a rules-document project. Requires Node.js toolchain setup per project, version management, and rule maintenance separate from documentation. Misaligns with the "rules document" output format. | Start with grep-based violation detection scripts. Add ESLint only if you need CI enforcement in a real production project. |
| Visual regression screenshot comparison | Catches pixel-level drift; used in design system toolchains (Percy, Chromatic) | Requires running a browser, baseline image management, CI setup, and a production app. This project's output is rule documents, not a running app. | Structured visual checklist evaluated against a sample page; human judgment with defined criteria is sufficient for personal use. |
| Figma-to-code token sync | Keeps design tokens in sync between Figma and code automatically | Requires Figma access, paid tooling, and ongoing integration maintenance. This project targets a code-only workflow. | Define token rules directly in code (CSS variable naming conventions). No Figma dependency needed. |
| Universal/generic rules (not dashboard-specific) | Broader applicability feels more valuable | Generality dilutes specificity. Rules like "use semantic HTML" are ignored because AI already knows them. Dashboard-specific rules ("every list page must use DataTable, not a custom table") are the ones that actually change AI behavior. | Keep all rules tightly scoped to dashboard domain. Generic rules belong in project-level CLAUDE.md, not here. |
| Real-time AI validation during generation | Sounds like closing the loop immediately | Requires an agentic feedback loop with external tooling (eval-driven generation). Complexity is orders of magnitude higher than document-based rules. Creates a system that can modify its own safety rules. | Post-generation evaluation checklist + manual sample page review is the right fidelity for personal use. |
| npm package / shareable library | Broadens reach; others can install and use | Requires versioning, compatibility management, breaking change discipline, and ongoing maintenance. Directly out of scope per PROJECT.md. | Git repository with copy-paste rules is sufficient for personal use and easy to share informally. |
| Dark mode enforcement rules | Seems important for polish | Design direction (including dark mode) is explicitly out of scope. Rules that enforce specific visual directions reduce portability across projects. | Document dark mode as an optional extension note, not a core rule. |

---

## Feature Dependencies

```
[3-Tier Component Hierarchy Definition]
    └──requires──> [Component Usage Rules (allowed/forbidden)]
                       └──requires──> [Forbidden Pattern Explicit List]

[Page Skeleton Templates]
    └──requires──> [3-Tier Component Hierarchy Definition]
    └──requires──> [Component Usage Rules]

[Form Structure Rules]
    └──requires──> [3-Tier Component Hierarchy Definition]

[Sample Page Generation]
    └──requires──> [Page Skeleton Templates]
    └──requires──> [Component Usage Rules]
    └──requires──> [Design Token Governance Rules]

[Rule Effectiveness Evaluation Checklist]
    └──requires──> [Sample Page Generation]

[Iterative Refinement Loop Documentation]
    └──requires──> [Rule Effectiveness Evaluation Checklist]

[Automated Violation Detection Script]
    └──requires──> [Forbidden Pattern Explicit List]
    └──enhances──> [Rule Effectiveness Evaluation Checklist]

[Scoped Rule Activation by File Type]
    └──enhances──> [Component Usage Rules]
    └──enhances──> [Page Skeleton Templates]

[Rule Rationale Annotations]
    └──enhances──> [All rule categories]

[Context Window Budget Guidance]
    └──enhances──> [Rule document format]
```

### Dependency Notes

- **Page Skeleton Templates requires 3-Tier Hierarchy:** You cannot define what a Page skeleton should contain until you have defined what Composed components exist at that tier. Hierarchy first, templates second.
- **Sample Page Generation requires Skeleton Templates + Component Rules + Token Rules:** The sample page is the integration test — it only works if all three rule categories exist.
- **Evaluation Checklist requires Sample Page:** The checklist is the review layer on top of the generated page. No page = nothing to evaluate.
- **Automated Detection enhances Evaluation Checklist:** The script catches mechanical violations (inline styles, forbidden imports); the checklist catches structural violations (wrong component tier, missing page zones). Both are needed.
- **Iterative Refinement requires Evaluation Checklist:** The loop formalization only makes sense after the evaluation mechanism exists. It documents how to use the checklist output to update rules.

---

## MVP Definition

### Launch With (v1)

Minimum viable rule set — enough to produce measurably consistent AI output on the first real project use.

- [ ] **Component usage rules (allowed/forbidden)** — The single most impactful rule category. Without it AI uses raw shadcn primitives and HTML directly.
- [ ] **Forbidden pattern explicit list** — Inline style, hardcoded colors, raw `<div>` layout, direct shadcn primitive imports. Must be specific and exhaustive.
- [ ] **3-tier component hierarchy definition** — Primitive/Composed/Page definitions with explicit examples of what belongs at each level.
- [ ] **Design token governance rules** — All color/spacing/radius via CSS variables. No hex values, no arbitrary Tailwind values.
- [ ] **Form structure rules** — FormFieldSet → FormField → Input hierarchy. Most common repeated-failure area.
- [ ] **Page skeleton templates (4 types)** — Dashboard overview, List/Table, Detail/View, Settings. Each with required zones and allowed components.
- [ ] **Rule document format (CLAUDE.md + scoped rules)** — The structure of the rule files themselves. Modular, path-scoped where applicable.
- [ ] **Basic violation detection script** — Grep-based check for the top 5 forbidden patterns. Runnable in under 30 seconds.

### Add After Validation (v1.x)

Add these after v1 rules have been tested against a real project.

- [ ] **Sample page generation** — Trigger: v1 rules produce inconsistent output in practice. Generate one exemplar per page type to verify rules end-to-end.
- [ ] **Rule effectiveness evaluation checklist** — Trigger: sample pages exist and there are observable violations to categorize and track.
- [ ] **Naming convention rules** — Trigger: inconsistent file/component naming observed in AI-generated pages.
- [ ] **Accessibility baseline rules** — Trigger: AI-generated components missing ARIA attributes in practice.
- [ ] **Scoped rule activation documentation** — Trigger: rules file becomes too long or rules conflict across page types.

### Future Consideration (v2+)

Defer until the v1 rule set is proven stable.

- [ ] **Iterative refinement loop documentation** — Defer: only valuable once enough rule iterations have happened to justify a documented process.
- [ ] **Escape hatch documentation** — Defer: edge cases only emerge from real usage. Premature escape hatches create confusion.
- [ ] **Context window budget guidance** — Defer: premature optimization. Measure rule file length impact empirically first.
- [ ] **Rule rationale annotation pass** — Defer: add rationale to rules that demonstrably fail without explanation, not all rules upfront.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Component usage rules (allowed/forbidden) | HIGH | LOW | P1 |
| Forbidden pattern explicit list | HIGH | LOW | P1 |
| 3-tier component hierarchy definition | HIGH | LOW | P1 |
| Design token governance rules | HIGH | LOW | P1 |
| Form structure rules | HIGH | LOW | P1 |
| Page skeleton templates (4 types) | HIGH | MEDIUM | P1 |
| Rule document format (CLAUDE.md + scoped) | HIGH | LOW | P1 |
| Basic violation detection script | MEDIUM | LOW | P1 |
| Sample page generation | HIGH | MEDIUM | P2 |
| Rule effectiveness evaluation checklist | HIGH | LOW | P2 |
| Naming convention rules | MEDIUM | LOW | P2 |
| Accessibility baseline rules | MEDIUM | MEDIUM | P2 |
| Scoped rule activation by file type | MEDIUM | MEDIUM | P2 |
| Iterative refinement loop documentation | MEDIUM | LOW | P3 |
| Escape hatch documentation | MEDIUM | LOW | P3 |
| Context window budget guidance | MEDIUM | LOW | P3 |
| Rule rationale annotation pass | LOW | LOW | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | shadcn/skills (official) | Cursor .cursorrules community | Our Approach |
|---------|--------------------------|-------------------------------|--------------|
| Component usage enforcement | Project introspection + composition rules via skill context | Reference guide format, not strict enforcement | Explicit allowed/forbidden lists with rationale |
| Design token governance | CSS variables recommended, not enforced | Mentioned but not enforced | Mandatory token-only rule with forbidden hardcoded values list |
| Component hierarchy | Not defined; flat component list | Not defined | 3-tier explicit (Primitive/Composed/Page) with tier ownership |
| Page templates/skeletons | Blocks system (copy-paste sections) | Not defined | 4 typed page skeletons with required zones |
| Form structure | FieldGroup composition rule | Not defined | FormFieldSet → FormField → Input explicit hierarchy |
| Forbidden pattern list | No explicit list | Some (avoid inline styles) | Exhaustive list with automated detection |
| Violation detection | None | None | Grep-based script + evaluation checklist |
| Sample page verification | None | None | Generated exemplar per page type |
| Self-evaluation loop | None | None | Rule → Generate → Evaluate → Fix cycle |
| Accessibility rules | Default from Radix UI | Not defined | Baseline ARIA rules + forbidden interactive div patterns |
| Rule format for AI tools | Skill system (Claude/Cursor) | .cursorrules / .mdc files | CLAUDE.md + path-scoped .claude/rules/*.md |

---

## Sources

- [shadcn/ui skills documentation](https://ui.shadcn.com/docs/skills) — shadcn/skills system, composition rules, project introspection (HIGH confidence)
- [shadcn/ui March 2026 Update: CLI v4, AI Agent Skills and Design System Presets](https://dev.to/codedthemes/shadcnui-march-2026-update-cli-v4-ai-agent-skills-and-design-system-presets-1gp1) — Presets, skills, AI-ready design system (MEDIUM confidence)
- [awesome-cursorrules shadcn-ui .cursorrules](https://github.com/PatrickJS/awesome-cursorrules/blob/main/rules/cursor-ai-react-typescript-shadcn-ui-cursorrules-p/.cursorrules) — Community cursor rule categories (MEDIUM confidence)
- [shadcn-ui cursor rules gist (Jacob Paris)](https://gist.github.com/jacobparis/ee4d1659896d24130651bca780a3fbbb) — Practical cursor rules for shadcn (MEDIUM confidence)
- [AI Keeps Breaking Your Architectural Patterns](https://dev.to/vuong_ngo/ai-keeps-breaking-your-architectural-patterns-documentation-wont-fix-it-4dgj) — Path-based pattern matching, 80% compliance vs 30-40% with documentation (MEDIUM confidence)
- [Design System Governance Tools for Component Library Enforcement](https://www.replay.build/blog/the-best-design-system-governance-tools-for-component-library-enforcement) — Enforcement mechanism categories (MEDIUM confidence)
- [AI-Driven Design System Governance](https://www.stldigital.tech/blog/ai-as-a-design-system-governor-enforcing-architectural-consistency/) — Enforcement engine patterns, AI governor approach (LOW confidence — single source)
- [Accessibility as Design System Policy](https://testparty.ai/blog/accessibility-as-design-system-policy) — Accessibility tokens and guardrails (MEDIUM confidence)
- [How ESLint Can Enforce Your Design System Best Practices](https://backlight.dev/blog/best-practices-w-eslint-part-1) — Code-level enforcement via ESLint rules (MEDIUM confidence)
- [Best Practices for Claude Code](https://code.claude.com/docs/en/best-practices) — CLAUDE.md file structure, scoped rules hierarchy (HIGH confidence)
- [AGENTS.md best practices](https://www.builder.io/blog/agents-md) — Rules file length and specificity guidance (MEDIUM confidence)

---

*Feature research for: AI-enforced UI rules system for shadcn/ui dashboards*
*Researched: 2026-03-26*
