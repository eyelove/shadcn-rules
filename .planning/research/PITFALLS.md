# Pitfalls Research

**Domain:** AI-enforced UI rules for shadcn/ui dashboards
**Researched:** 2026-03-26
**Confidence:** HIGH

---

## Critical Pitfalls

### Pitfall 1: Rule Volume Causes Silent Compliance Drift

**What goes wrong:**
The rule document grows past the threshold where an LLM reliably follows every rule simultaneously. When a CLAUDE.md or rules file contains 30+ distinct directives, the model selectively applies rules it finds "nearby" in the file while quietly ignoring those buried in the middle. The result looks correct at a glance but violates 3–5 rules in every generated page.

**Why it happens:**
LLMs exhibit a U-shaped attention curve — instructions near the beginning and end of a context window get stronger signal than those in the middle. Rule files over ~1,500 tokens begin exhibiting this effect measurably. Most authors keep adding rules when something breaks, never removing old ones. The file compounds silently.

**How to avoid:**
- Cap the core rules file at 80–120 lines maximum. Every rule must earn its place.
- Apply the deletion test: "If I removed this line, would the AI make this specific mistake?" If the answer is no or "probably not," cut it.
- Split concerns: use a short "always apply" rules file + separate per-topic references the AI loads only when relevant.
- Express rules as "use X" rather than "do not use Y" — positive constraints are followed more reliably than prohibitions.

**Warning signs:**
- Sample pages start using inline styles or raw HTML tags after 10+ generation turns.
- Rules near line 50–80 of the file get violated while rules at line 5 and line 100 hold.
- AI "acknowledges" a rule in a follow-up when prompted, proving it was never forgotten — just probabilistically deprioritized.

**Phase to address:** Rule Document Design phase (Phase 1). Set rule count budget before writing a single rule.

---

### Pitfall 2: Rules Block Legitimate Patterns ("규칙 과잉" / Over-Policing)

**What goes wrong:**
A rule written to prevent one bad pattern eliminates an entire class of valid solutions. The most common example: "never use inline styles" blocks `style={{ gridTemplateColumns: dynamicValue }}` — the only correct way to apply runtime-computed grid layouts in React. The AI then generates either broken layouts or ugly workarounds like CSS-in-JS interpolation.

**Why it happens:**
Rules are written reactively, in response to a specific mistake observed. The author generalizes too broadly, not considering the edge cases where the prohibited pattern is actually correct. "Never X" is simpler to write than "never X except when Y."

**How to avoid:**
- Write rules as "prefer X over Y for [specific context]" with an explicit carve-out.
- For every prohibition, identify 2–3 legitimate uses of the prohibited pattern and encode the distinction.
- Test rules against a broader sample (>5 page types) before canonizing them.
- Build a "known legitimate exceptions" annex into the rules document itself.

**Warning signs:**
- AI produces verbose workarounds for simple layout problems.
- AI hedges with comments like "I know you said not to use X, but..." and then uses it correctly anyway.
- Validation scripts flag 20%+ of generated code as violations, suggesting the rules are too broad.

**Phase to address:** Rule refinement loop (Phase 3). False positive rate above 15% in the automated checker signals over-restriction requiring rule revision.

---

### Pitfall 3: Composed Component Layer Leaks shadcn Primitives

**What goes wrong:**
The 3-layer hierarchy (Primitive → Composed → Page) is designed so the AI only touches Composed components. But if Composed components expose their internal shadcn props — e.g., `<DataTable>` accepting `TableProps` passthrough — the abstraction boundary is meaningless. AI will use the passthrough to reach shadcn internals, bypassing every consistency rule attached to the Composed layer.

**Why it happens:**
Developers expose escape hatches intentionally ("flexibility!") without realizing they destroy the boundary. The `className` prop passthrough is the most common offender: any Composed component that accepts `className` gives the AI a free path to override every design token constraint.

**How to avoid:**
- Composed components must not accept `className` or raw shadcn component props as passthrough.
- Use explicit, typed variant props (`variant="primary" | "secondary"`) instead of style overrides.
- If flexibility is needed, encode it as named slot props (`headerSlot`, `actionSlot`) not open style props.
- The rule document should explicitly list which props are allowed on each Composed component.
- Review every Composed component interface for accidental prop exposure before the rules are finalized.

**Warning signs:**
- AI-generated pages pass `className` props to Composed components.
- The generated code imports anything from `@/components/ui/` (the shadcn Primitive layer) directly in page files.
- Color or spacing values appear as Tailwind utilities on Composed component call sites.

**Phase to address:** Component hierarchy design (Phase 1). This must be resolved in the interface contract before sample pages are generated.

---

### Pitfall 4: Design Token System Outgrows the Tailwind Primitive

**What goes wrong:**
A custom design token layer is built on top of Tailwind's `--color-*` variables, creating a multi-hop chain: component uses `bg-surface-elevated`, which resolves to a CSS variable `--color-surface-elevated`, which maps to `--color-gray-100`, which is a Tailwind v4 theme variable. When the AI generates new code, it doesn't know which layer to reference. It sometimes writes `bg-gray-100` directly, collapsing the semantic layer. The token system becomes aspirational documentation rather than lived practice.

**Why it happens:**
Token architects design for Figma-to-code sync or multi-brand scaling — goals this project explicitly doesn't have. The extra indirection adds cognitive load without delivering value at single-project scale. Tailwind's utility classes are already in the AI's training data; custom semantic tokens are not.

**How to avoid:**
- Use at most two layers: semantic tokens (color purpose: `surface`, `border`, `text-primary`) defined as CSS variables → Tailwind `theme()` utilities. No further aliasing.
- Limit token categories to what the dashboard actually uses: 5–8 color roles, 4–6 spacing steps, 2–3 radius values, 2–3 type scales.
- The token names must be short and opinionated enough that an AI can memorize them from the rules file without a lookup.
- Explicitly call out the most-used tokens in the rules file itself, not buried in a separate token reference.

**Warning signs:**
- Generated code uses Tailwind color primitives (`gray-100`, `zinc-800`) instead of semantic tokens.
- Token reference document is longer than 200 lines — it won't be consulted during generation.
- Different sample pages use different tokens for the same semantic role.

**Phase to address:** Token definition (Phase 1). If tokens are not self-contained and short enough to fit in the rules file, redesign them before writing component rules.

---

### Pitfall 5: Validation Script Catches Syntax, Misses Semantics

**What goes wrong:**
The automated violation checker flags `style={{` and direct `<div className=` and raw color literals. It reports "0 violations." But the page is semantically wrong: it uses a `Card` where a `Section` is correct, uses `text-sm` instead of the `body-small` token, or places a table outside a `DataView` wrapper. No linting rule catches "wrong component for the context."

**Why it happens:**
Static analysis can only check for patterns that have exact textual signatures. Semantic and architectural choices — "is this the right component for this intent?" — require human judgment or AI-powered review. Teams mistake the absence of detected violations for correctness.

**How to avoid:**
- The validation system needs two tiers: (1) mechanical/AST-level checks for textual violations, (2) AI-assisted semantic review that evaluates "does the structure match the page type template?"
- Build a "structure checklist" per page type: list/detail/settings/dashboard each has a required skeleton. The checker verifies the skeleton is present.
- Semantic review prompts should be separate from generation prompts — use a dedicated "review mode" that asks the AI to compare output against the rules, not the AI that generated the output.

**Warning signs:**
- Validation passes 100% but sample pages look visually different from each other.
- Two pages that serve the same function use different component compositions.
- The checker has never reported a violation after the first few iterations — real rule drift is going undetected.

**Phase to address:** Validation system design (Phase 2). Build the semantic tier from the start; retrofitting it after 10 sample pages is expensive.

---

### Pitfall 6: Sample Pages Only Represent Happy Paths

**What goes wrong:**
Sample pages are generated for ideal data: a list with 10 clean rows, a form with all fields filled correctly, a dashboard with positive metric trends. Rules are validated against these happy paths. When the AI later generates real-world pages — empty states, error states, long truncated strings, permission-restricted sections — it has no template to follow and reverts to ad-hoc patterns that violate structural rules.

**Why it happens:**
Happy-path samples are fast to generate and visually satisfying. Edge-case samples require explicit thought about failure states, and they are less rewarding to look at. Most design system sample suites skip them entirely.

**How to avoid:**
- For each page type, require at minimum: empty state variant, error state variant, loading state variant, and data-heavy/truncation variant.
- The rules document must explicitly specify how each state is rendered — not just the happy path skeleton.
- Sample generation prompts should include a "generate the same page but with [empty/error/loading] state" follow-up.

**Warning signs:**
- None of the sample pages show an empty list or a form with validation errors.
- "Empty state" and "error state" do not appear anywhere in the rules document.
- When asking the AI to generate an error page, it creates an ad-hoc alert box outside any Composed component.

**Phase to address:** Sample page definition (Phase 2). Mandate state variants in the sample generation spec before running any generation.

---

### Pitfall 7: Self-Review Loop Uses the Generator as the Validator

**What goes wrong:**
The refinement loop asks the same AI session that generated a page to evaluate whether it follows the rules. The AI almost always reports compliance, because the chain-of-thought reasoning that produced the code continues into the evaluation — it rationalizes rather than audits. Genuine violations go undetected. The project gains false confidence that rules are working.

**Why it happens:**
It is operationally simple to add "now check if the above code follows the rules" to the same conversation. The AI is compliant and helpful — it will confirm what it believes it did. But LLM self-critique in the same context window is not independent review.

**How to avoid:**
- Evaluation must be in a fresh context window with only the generated code and the rules document — no generation history.
- Use structured audit prompts: "List every import. List every component used. Compare each against the allowed list." Force enumeration before judgment.
- For mechanical checks, use AST-based tools (eslint custom rules, grep scripts) that are genuinely context-free.
- Rotate evaluation prompts: the same evaluation prompt used repeatedly will find the same patterns and miss the same gaps.

**Warning signs:**
- The AI evaluation always returns "compliant" or very minor notes.
- Running the same code through a fresh context finds violations the in-context review missed.
- The same violation type appears across multiple sample pages without the review loop catching it.

**Phase to address:** Review loop design (Phase 2/3). Establish context-separation discipline before running the first validation cycle.

---

### Pitfall 8: Rule Document Format Degrades AI Processing

**What goes wrong:**
Rules are written as long prose paragraphs, deeply nested sections, or walls of examples. The AI processes the document but retains fewer specific rules because the signal-to-noise ratio is low. A rules document with 500 words of context preamble followed by the actual rules buried at line 60 will result in worse adherence than a front-loaded, structured, scannable format.

**Why it happens:**
Humans write documentation for humans — context-setting prose, rationale paragraphs, motivating examples. These help a human engineer understand the why. For an LLM, they dilute the signal of what must actually be done.

**How to avoid:**
- Lead with the most important constraints, not with project background.
- Use short, imperative bullets for rules: "Use `<DataTable>` for all tabular data. Never use `<table>` directly."
- Reserve prose rationale for a separate "rationale" appendix; keep the main rules file scannable.
- Use a consistent marker for prohibitions (`NEVER:`) and requirements (`ALWAYS:`) so they are syntactically distinguishable.
- Total rules file should be under 1,500 tokens (~1,200 words). If it exceeds this, split into scoped sub-files.
- Put the most critical rules in the first 30 lines and the last 20 lines (exploiting U-curve attention).

**Warning signs:**
- Rules file contains more context/rationale than actual rules.
- Rules are expressed as "it is generally preferable to..." rather than imperative directives.
- File exceeds 200 lines without a clear split into scoped sub-documents.

**Phase to address:** Rule document design (Phase 1). Set format standards before writing any content.

---

### Pitfall 9: Over-Relying on "Rules to Block" Instead of "Components to Enforce"

**What goes wrong:**
The rule document grows as a list of prohibitions: "don't use inline styles," "don't use raw HTML," "don't hardcode colors." These are policing rules — they rely on the AI voluntarily not doing something. An AI that has strong training signal for a pattern (like using `<div>` for layout) will drift back to it under ambiguous conditions, because its base behavior is pulling in that direction. Rules cannot override training data long-term.

**Why it happens:**
Rules-first thinking is faster to iterate than component-first. Writing "don't use X" takes minutes; building a Composed component that makes X unnecessary takes hours. The easy path leads to a rules-heavy, component-light system that degrades over time.

**How to avoid:**
- For every major prohibition, ask: "Can I build a Composed component that makes this prohibition unnecessary?" If yes, build the component first, add the prohibition as a backup second.
- The Composed component library should be expansive enough that an AI never needs to reach for a raw shadcn primitive or HTML element. If the AI keeps grabbing a primitive, that signals a missing Composed component, not a missing rule.
- Rules document should be primarily "use X" (component references) with minimal "never use Y" (prohibitions). A 4:1 ratio of "use" to "never" directives is a healthy target.
- Treat prohibition rules as temporary scaffolding until the corresponding Composed component exists.

**Warning signs:**
- Rules file has more "don't" / "never" / "avoid" statements than component names.
- After 5+ generations, the AI still occasionally uses raw `<Input>` from shadcn despite the rule against it — a signal that `<FormField>` isn't sufficient.
- Rule file grows as pages are generated, but component list stays static.

**Phase to address:** Component design (Phase 1) and validation loop (Phase 3). When a prohibition fires repeatedly, treat it as a component gap, not a stricter rule need.

---

### Pitfall 10: Form Rule Inconsistency Across shadcn Form Primitives

**What goes wrong:**
shadcn/ui's form system is built on `react-hook-form` with `FormField`, `FormItem`, `FormLabel`, `FormControl`, `FormDescription`, `FormMessage`. When rules define a 3-layer form hierarchy (`FormFieldSet → FormField → Input`) without matching exactly to shadcn's internal structure, generated code either skips required elements (like `FormControl` wrapping) or duplicates them. Accessibility breaks silently — the `htmlFor`/`id` linkage that shadcn manages automatically is broken when the wrapper layer is wrong.

**Why it happens:**
The project's conceptual `FormField` (a composed field with label + input + error) maps to multiple shadcn components. If the rules don't resolve this mapping explicitly, the AI guesses. It may implement `FormField` as just `<label>` + `<Input>` — losing the `react-hook-form` integration and the accessible error binding.

**How to avoid:**
- The Composed form components must fully encapsulate the shadcn `FormField > FormItem > FormLabel + FormControl + FormMessage` chain.
- The rules file must show, once, the exact slot structure of each Composed form component with a code example.
- Prohibit direct use of shadcn `FormField`, `FormItem`, `FormControl`, `FormLabel`, `FormMessage` in page files — all form primitives are accessible only through Composed wrappers.
- Test form components against screen reader output, not just visual appearance.

**Warning signs:**
- Generated forms do not have `htmlFor`/`id` associations (inspectable in browser devtools).
- `FormControl` appears or disappears inconsistently across generated forms.
- Validation error messages display but are not announced by screen readers.

**Phase to address:** Component hierarchy design (Phase 1) and sample page validation (Phase 2).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Write prohibition rules instead of building Composed components | Fast iteration, low upfront cost | Rules drift; AI reverts to forbidden patterns over time | Never for structural patterns (layout, form structure); acceptable for minor style details |
| Use Tailwind primitive classes as design tokens | No setup overhead | AI bypasses semantic layer; inconsistent color use across pages | Never after token layer is defined |
| Use same context window for generation and validation | Operationally simple | False confidence; genuine violations go undetected | Never; always use fresh context for evaluation |
| Accept `className` passthrough in Composed components | More flexible for edge cases | Escape hatch defeats abstraction boundaries | Only in explicitly documented "escape" components with clear naming (e.g., `<UnsafeRawCard>`) |
| Skip empty/error/loading state samples | Faster initial validation cycle | Real-world pages break the rules; no template to enforce against | MVP only, must be addressed before treating the system as validated |
| Long prose rationale in rules file | Human-readable context | Dilutes AI signal; rules buried in prose are followed less reliably | Separate rationale appendix; never in the primary rules file |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| shadcn/ui + react-hook-form | Wrapping `<FormControl>` at the wrong level, breaking the Controller context | Composed form component must own the full `FormField > FormItem > FormControl` chain |
| shadcn/ui + Tailwind v4 | Using `tailwind.config.js` token definitions when Tailwind v4 expects `@theme` CSS-first tokens | Define all tokens in CSS `@theme` block; verify shadcn's CSS variables align before writing rules |
| Rule file + Cursor/Claude Code | Rules file loaded as a flat document with no scope — all rules apply to all files | Use scoped rules files (`.cursor/rules/*.mdc`) per domain (forms, layouts, tokens) to reduce token load and improve specificity |
| Composed components + TypeScript | Prop types too loose (accepting `string` for variant) allows invalid values that only break at runtime | Use `as const` union types for all variant props; never accept `string` |
| Validation scripts + CI | Linting scripts catch textual violations but pass all semantic/architectural violations | Two-tier validation: AST/grep for textual, fresh-context AI prompt for semantic |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Rules file too long for effective context loading | Violations of mid-document rules increase over time | Cap file at 1,500 tokens; split into scoped sub-documents | Any file over ~120 lines in a single document |
| Validation prompt reused across all page types | Same violations pass review because same prompt has same blind spots | Rotate review prompts; build page-type-specific checklists | After 3–4 generations with the same prompt |
| Composed component count grows without pruning | AI confusion about which component to use; inconsistent choices | Maintain a single "component decision tree" or quick-reference table | When component count exceeds ~20 composed components |
| Token layer added retroactively to existing components | Components use a mix of old primitive classes and new semantic tokens | Define tokens before any Composed component is written | As soon as the first component is written with primitive classes |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Rules enforce structural consistency but ignore spacing rhythm | Pages are component-consistent but feel visually uneven | Include spacing system rules: which gap/padding values are allowed in which contexts |
| Sample pages all show desktop layout, no responsive behavior in rules | AI generates non-responsive layouts; breaks at smaller viewports | Define responsive behavior rules per page type in the skeleton templates |
| Design direction not fixed but component variants are fixed | Mismatch when project has a different visual style; AI follows structural rules but ignores visual fit | Rules should be visual-direction-agnostic at the component level; visual direction comes through token values, not rule text |
| Rules define component usage but not component composition order | Pages that follow all rules still look inconsistent because element order varies | Include canonical composition order in page skeleton templates: e.g., `PageHeader > Filters > DataTable > Pagination` |

---

## "Looks Done But Isn't" Checklist

- [ ] **Rule file coverage:** Rules address all 4 page types (list, detail, settings, dashboard) — verify each page type has an explicit skeleton template, not just general component rules.
- [ ] **Component boundary integrity:** Every Composed component interface is reviewed for `className` passthrough and raw shadcn prop exposure — verify by running a grep for `className?:` in Composed component prop types.
- [ ] **Token completeness:** Every Tailwind utility class for color, spacing, and radius used in sample pages maps to a defined semantic token — verify no raw `gray-*`, `zinc-*`, or `px-[value]` values appear in page code.
- [ ] **Validation independence:** Evaluation prompts run in fresh context windows, not in the generation conversation — verify by running the same code through a new session and comparing results.
- [ ] **State coverage:** Each page type sample includes empty, error, and loading variants — verify the sample page directory contains `[page-type]-empty.tsx`, `[page-type]-error.tsx` files.
- [ ] **Form accessibility:** Generated forms have complete `htmlFor`/`id` chains — verify with browser devtools accessibility inspector, not visual review.
- [ ] **Prohibition-to-component ratio:** Rules file has more "use X component" directives than "never use Y" prohibitions — count and verify 4:1 or better ratio.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Rule file too long / compliance drift detected | MEDIUM | Audit each rule against deletion test; cut file to 80 lines; split remainder into scoped sub-documents; regenerate 3 sample pages to verify recovery |
| Composed component leaks shadcn props | MEDIUM | Audit all Composed component interfaces; remove `className` and raw shadcn props; update rule file to list allowed props explicitly; regenerate affected sample pages |
| Token layer ignored by AI | MEDIUM | Move the 10 most-used tokens to the top 20 lines of the rules file; add a "token quick reference" table; regenerate sample pages |
| Self-review false confidence discovered | LOW | Establish fresh-context review protocol immediately; re-evaluate all existing sample pages in new sessions; document any violations found |
| Sample pages missing state variants | LOW | Generate missing state variants; add explicit state requirements to skeleton templates in the rules file |
| Prohibition rules drift (AI reverts to forbidden patterns) | HIGH | Identify which Composed component is missing; build it; test; update rules to reference new component; re-run sample generation |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Rule volume / compliance drift | Phase 1: Rule Document Design | Token-count the final rules file; must stay under 1,500 tokens |
| Over-policing / rules block valid patterns | Phase 3: Refinement Loop | False positive rate in automated checker below 15% |
| Composed component layer leaks primitives | Phase 1: Component Hierarchy Design | Grep for `className?:` in Composed prop interfaces; zero results required |
| Token system over-engineered | Phase 1: Token Definition | Token reference fits in under 30 lines inside the rules file |
| Validation catches syntax, misses semantics | Phase 2: Validation System | Semantic review tier defined; structure checklist per page type exists |
| Sample pages only cover happy paths | Phase 2: Sample Generation Spec | Each page type has 4 variants (happy, empty, error, loading) |
| Self-review uses generator as validator | Phase 2: Review Loop Design | Fresh-context protocol documented and followed from first cycle |
| Rule document format degrades AI processing | Phase 1: Rule Document Design | Rules file is front-loaded, imperative, under 1,500 tokens |
| Rules-first over component-first | Phase 1: Component Design | 4:1 "use" vs "never" ratio enforced in rules file |
| Form rules inconsistent with shadcn structure | Phase 1: Component Hierarchy Design | Form components tested for htmlFor/id linkage before rules are finalized |

---

## Sources

- [Best Practices for Claude Code — Claude Code Docs](https://code.claude.com/docs/en/best-practices) — rule file size and format
- [Why AI Agents Ignore Instructions — Limits Blog](https://blog.limits.dev/ai-agent-ignores-instructions-why-it-happens-how-to-fix-it) — probabilistic enforcement, context window degradation
- [5 Critical shadcn/ui Pitfalls — Paul Serban](https://www.paulserban.eu/blog/post/5-critical-shadcnui-pitfalls-that-break-production-apps-and-how-to-avoid-them/) — component wrapping and abstraction misuse
- [Don't Use Tailwind for Your Design System — sancho.dev](https://sancho.dev/blog/tailwind-and-design-systems) — token enforcement, className escape hatch, derived style impossibility
- [Using Linters to Direct Agents — Factory.ai](https://factory.ai/news/using-linters-to-direct-agents) — false positives in validation, linting for AI agents
- [Your Design System Needs an Enforcer — Nielsen Norman Group](https://www.nngroup.com/articles/design-system-enforcer/) — over-policing vs. permissiveness failure modes
- [How LLMs Ignore Middle of Context Window — Medium](https://charlesanthonybrowne.medium.com/how-llms-end-up-ignoring-the-middle-of-a-context-window-c8662000eb67) — U-shaped attention curve
- [Context Engineering for Coding Agents — Martin Fowler](https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html) — context engineering best practices
- [In React, The Wrong Abstraction Kills Efficiency — Jesse Duffield](https://jesseduffield.com/React-Abstractions/) — abstraction level and leaky boundaries
- [Cursor AI Complete Guide 2025 — Medium](https://medium.com/@hilalkara.dev/cursor-ai-complete-guide-2025-real-experiences-pro-tips-mcps-rules-context-engineering-6de1a776a8af) — scoped rules files, context engineering in practice

---
*Pitfalls research for: AI-enforced UI rules for shadcn/ui dashboards*
*Researched: 2026-03-26*
