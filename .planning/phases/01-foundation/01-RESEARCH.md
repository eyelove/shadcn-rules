# Phase 1: Foundation — Research

**Researched:** 2026-03-26
**Domain:** shadcn/ui CSS variable system, Claude Code rules format, AI-enforceable component hierarchy design
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Use shadcn/ui's existing CSS variable system (`--background`, `--foreground`, `--primary`, etc.) as the base token layer. Do not reinvent a custom token system.
- **D-02:** Extend with dashboard-specific tokens only where shadcn defaults are insufficient (e.g., `--chart-1` through `--chart-6`, `--kpi-bg`).
- **D-03:** Tokens must be short, opinionated, and directly referenced by name — no multi-hop token chains. WHY: AI collapses complex token chains to nearest familiar Tailwind primitive.
- **D-04:** 3-tier component hierarchy is confirmed: Primitive (shadcn/ui originals — AI must NOT import directly), Composed (project wrappers — AI's ONLY entry point), Page (skeleton templates — enforce page-level structure).
- **D-05:** Composed components defined at interface level only — component name + props type + usage example code in TSX. No stub implementation code in rule documents.
- **D-06:** Component count left to Claude's judgment, based on the idea document's component list (PageLayout, PageHeader, SearchBar, KpiCardGroup, ChartSection, DataTable, FormFieldSet, FormField, FormRow, FormActions, ConfirmDialog, StatusBadge).
- **D-07:** className passthrough is forbidden on Composed components. WHY: It gives AI a free path back to primitives, bypassing all constraints.
- **D-08:** Four page types, each defined as an ordered sequence of Composed components: Dashboard (TitleBar → FilterBar → KpiCardGroup(2 or 4) → ChartSection → DataTable), List (TitleBar → FilterBar → DataTable), Form (TitleBar → FormFieldSet(s) → FormActions), Detail (TitleBar(back nav) → TabGroup → per-tab content).
- **D-09:** Templates provided as TSX code examples — AI copies/references the structure directly.
- **D-10:** Each Composed component template defines internal structure with TSX.
- **D-11:** Modular structure: `CLAUDE.md` (overview, ~80 lines) + `.claude/rules/*.md` (domain-scoped rules).
- **D-12:** Claude Code only — no .cursorrules, no AGENTS.md.
- **D-13:** Rule file budget: ~120 lines / ~1,500 tokens per file. WHY: AI compliance drops significantly for longer files.
- **D-14:** Imperative tone in English ("DO use...", "NEVER use...").
- **D-15:** Example code inclusion level at Claude's discretion — may include Good/Bad pairs where contrast is high-value.
- **D-16:** Every critical rule includes inline WHY comment.

### Claude's Discretion

- Exact number of initial Composed components (guided by idea document list)
- Example code depth per rule (Good-only vs Good/Bad pairs — choose based on impact)
- Dashboard-specific token names and values

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TOKN-01 | Color token rules (Background, Text, Border, Brand, Chart categories) | shadcn/ui CSS variables provide the base; exact variable names documented below |
| TOKN-02 | Typography token rules (font-family, size system, weight by usage) | shadcn/ui doesn't define typography CSS vars natively; must extend with `--font-*` and `--text-*` conventions |
| TOKN-03 | Spacing token rules (component padding, component gap, section gap) | Tailwind v4 spacing scale is the base; semantic aliases (`--space-section`, `--space-component`) must be added |
| TOKN-04 | Other token rules (border-radius, shadow, transition) | shadcn/ui provides `--radius` and derived `--radius-*`; shadow and transition need custom additions |
| TOKN-05 | Tokens are short and clear — no multi-hop chains, direct CSS variable reference | Validated: shadcn/ui's own system uses direct single-hop CSS vars |
| COMP-01 | 3-tier component separation rule definition | Architecture confirmed; rule format patterns documented below |
| COMP-02 | Allowed component list (Composed tier only) for AI | Composed component list from idea document fully enumerated below |
| COMP-03 | Forbidden component list (Primitive tier) for AI | shadcn/ui ui/ directory components documented with exact import paths |
| COMP-04 | Interface contracts (props, usage examples) for core Composed components | Pattern confirmed: props type + TSX usage example is the minimum viable interface definition |
| RFMT-01 | Rule file token budget guide (~120 lines / 1,500 tokens) | Confirmed: official Claude Code docs say "target under 200 lines per CLAUDE.md" and specifically flag files over 200 lines as problematic; 120-line cap for scoped rules files is conservative and safe |
| RFMT-02 | Modular strategy — CLAUDE.md (root) + .claude/rules/*.md (path-scoped) | Official docs confirm `.claude/rules/` with YAML `paths:` frontmatter; exact format documented below |
| RFMT-03 | All critical rules include WHY rationale comment | Pattern confirmed; inline WHY comments improve AI rule adherence |
| RFMT-04 | Legitimate escape hatches documented | Pattern: escape hatch = explicit named exception, not silent passthrough |
</phase_requirements>

---

## Summary

Phase 1 produces three outputs: (1) a design token definition that extends shadcn/ui's CSS variable system, (2) a Composed component interface catalog that locks down the AI's only legal entry points, and (3) the rule document structure (CLAUDE.md + .claude/rules/ files) that will contain all subsequent rules.

The prior project-level research (SUMMARY.md, STACK.md, ARCHITECTURE.md, PITFALLS.md) is thorough and covers the architectural decisions well. Phase 1 research focuses on the specific details that were left as open questions: the exact shadcn/ui CSS variable names available in v4, the precise `.claude/rules/` frontmatter syntax for path-scoped rules, and the exact Composed component interface patterns that make AI follow them reliably.

Key finding: shadcn/ui v4 now uses oklch() color values by default (not hsl), and the CSS variable set has expanded to include `--sidebar-*` variables and a full `--radius-*` scale. The `--chart-1` through `--chart-5` baseline can be freely extended to `--chart-6` and beyond for dashboard needs. The Claude Code rules system has been confirmed with official documentation — YAML frontmatter `paths:` field is the correct mechanism for path-scoped rules.

**Primary recommendation:** Author the token file first, then the Composed component interface catalog, then the rule documents. In that exact order — tokens gate component rules, component rules gate page templates.

---

## Standard Stack

### Core (Phase 1 deliverables)

| File/Directory | Purpose | Format |
|----------------|---------|--------|
| `tokens/globals.css` | CSS custom property definitions (`--background`, `--foreground`, etc.) | CSS, `:root { }` block |
| `CLAUDE.md` | Universal rules — always loaded | Markdown, ~80 lines max |
| `.claude/rules/components.md` | Component tier rules, allowed/forbidden imports | Markdown + YAML frontmatter |
| `.claude/rules/tokens.md` | Token usage rules, forbidden raw values | Markdown + YAML frontmatter |

### Supporting Libraries (already researched, confirmed)

| Library | Version | Purpose |
|---------|---------|---------|
| shadcn/ui CLI | 4.1.0 | Install primitive components |
| Tailwind CSS | 4.2.2 | `@theme` CSS-first token utilities |
| TypeScript | 6.0.2 | Component prop type contracts |
| CVA | 0.7.1 | Variant API for Composed components |
| clsx + tailwind-merge | 2.1.1 / 3.5.0 | `cn()` class merging |
| lucide-react | 1.7.0 | Icon system (only allowed icon library) |

---

## Architecture Patterns

### Recommended Project Structure (Phase 1 scope)

```
shadcn-rules/
├── CLAUDE.md                      # Universal rules, ~80 lines, always loaded
├── .claude/
│   └── rules/
│       ├── components.md          # paths: src/**/*.tsx — tier rules, import rules
│       └── tokens.md              # paths: src/**/*.{tsx,css} — token usage rules
└── tokens/
    └── globals.css                # :root CSS variables + @theme mappings
```

Phases 2–4 will add `.claude/rules/forms.md`, `.claude/rules/pages.md`, and `validation/` content to this structure.

### Pattern 1: CLAUDE.md Import Chain

Claude Code supports `@path/to/file` import syntax inside CLAUDE.md. This allows the root CLAUDE.md to stay under 80 lines by referencing rule files rather than containing all rules inline.

**Structure:**
```markdown
# Project Rules

@.claude/rules/components.md
@.claude/rules/tokens.md

## Universal Constraints
- [rules that apply everywhere — 5-10 lines max]
```

**Confidence:** HIGH — verified with official Claude Code documentation (code.claude.com/docs/en/memory).

### Pattern 2: Path-Scoped Rules with YAML Frontmatter

Rules files in `.claude/rules/` can include YAML frontmatter to restrict when they load. Without frontmatter, a rules file loads every session alongside CLAUDE.md. With `paths:` frontmatter, the file only activates when Claude opens matching files.

**Exact format (verified with official docs):**
```markdown
---
paths:
  - "src/**/*.tsx"
---

# Component Usage Rules
[rules content]
```

**Multi-pattern example:**
```markdown
---
paths:
  - "src/**/*.{ts,tsx}"
  - "lib/**/*.ts"
---
```

**Important behavior (from official docs):** Path-scoped rules "trigger when Claude reads files matching the pattern, not on every tool use." Rules without a `paths` field load unconditionally at launch with the same priority as CLAUDE.md.

**Confidence:** HIGH — verified directly from code.claude.com/docs/en/memory.

### Pattern 3: Composed Component Interface Contract

The minimum viable interface contract for a Composed component in a rule document is:

1. Component name (PascalCase)
2. Props TypeScript interface (type names + descriptions in comments)
3. A single TSX usage example showing the canonical invocation

**Why this pattern works:** The AI has enough to write a call site. It does not need the implementation. The interface contract functions as an API contract, not a component implementation guide.

**Template:**
```typescript
// PageHeader — page title bar with optional primary action
interface PageHeaderProps {
  title: string               // Page title displayed as h1
  subtitle?: string           // Optional secondary description
  action?: React.ReactNode    // Single primary action (ActionButton only)
}

// Usage
<PageHeader
  title="Campaigns"
  subtitle="Manage all active campaigns"
  action={<ActionButton onClick={handleCreate}>New Campaign</ActionButton>}
/>
```

**Critical constraint (D-07):** `className` is explicitly absent from the props interface. This is intentional — omitting it removes the escape hatch. If the AI asks about className, the answer in the rule document is "not supported."

**Confidence:** HIGH — confirmed by project PITFALLS.md pitfall 3, backed by multiple practitioner sources.

### Pattern 4: Token Definition Order

Tokens must be defined in a specific order to prevent multi-hop chain dependencies:

1. Define raw values at the shadcn/ui CSS variable names (single-hop: name → value)
2. Tailwind `@theme` maps CSS variable names to utility class names
3. Rule documents reference only the Tailwind utility name OR the CSS variable name — never both in the same rule

**Anti-pattern to avoid:**
```css
/* WRONG: multi-hop chain */
--color-surface-elevated: var(--color-gray-100); /* hop 1 */
--color-gray-100: var(--background);             /* hop 2 — AI will collapse this */
```

**Correct pattern:**
```css
/* RIGHT: single-hop */
:root {
  --background: oklch(1 0 0);          /* direct value */
  --card: oklch(1 0 0);                /* direct value */
  --kpi-bg: oklch(0.97 0.01 250);      /* dashboard extension, direct value */
}
```

**Confidence:** HIGH — D-03 decision validated by PITFALLS.md pitfall 4 with empirical basis.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Class variant API for Composed components | Custom variant switch logic | CVA 0.7.1 | shadcn/ui uses CVA internally; consistent variant type signatures |
| Icon system | Custom SVG components or multiple icon libs | lucide-react exclusively | Visual inconsistency between components is the exact problem being solved |
| CSS variable token aliasing | Multi-hop CSS variable chains | Direct value assignment in `:root` | AI collapses chains to nearest Tailwind primitive |
| Form field accessibility | Custom htmlFor/id management | shadcn Form component encapsulation | Manual linkage is error-prone; FormControl manages this automatically |
| Component prop class merging | Manual string concatenation | `cn()` from clsx + tailwind-merge | Class conflict resolution is non-trivial; twMerge handles it correctly |

**Key insight:** In this phase, "don't hand-roll" applies to the rule document format itself. Do not invent a custom rules schema — use the verified YAML frontmatter format that Claude Code already understands.

---

## shadcn/ui v4 CSS Variable Reference

### Complete Variable Inventory (HIGH confidence — verified from ui.shadcn.com/docs/theming)

**Background and surface:**
```
--background          Page background
--foreground          Default text on background
--card                Elevated card surface
--card-foreground     Text on card
--popover             Floating surface (dropdown, tooltip)
--popover-foreground  Text on popover
```

**Action and brand:**
```
--primary             High-emphasis actions, brand color
--primary-foreground  Text on primary
--secondary           Lower-emphasis filled actions
--secondary-foreground Text on secondary
--accent              Interactive hover and focus states
--accent-foreground   Text on accent
--muted               Subtle surfaces
--muted-foreground    Subdued / helper text
--destructive         Destructive actions, errors
```

**UI structure:**
```
--border              Default borders and separators
--input               Form control borders
--ring                Focus rings
```

**Chart (extendable):**
```
--chart-1 through --chart-5   Default palette (can add --chart-6, --chart-7, etc.)
```

**Sidebar (dashboard-relevant):**
```
--sidebar              Sidebar background
--sidebar-foreground   Sidebar text
--sidebar-primary      Active nav item
--sidebar-primary-foreground
--sidebar-accent       Hover state in sidebar
--sidebar-accent-foreground
--sidebar-border
--sidebar-ring
```

**Radius scale:**
```
--radius               Base radius (default: 0.625rem)
--radius-sm
--radius-md
--radius-lg
--radius-xl
--radius-2xl
--radius-3xl
--radius-4xl
```

### Dashboard-Specific Extensions (Claude's Discretion — D-06)

These tokens are NOT in shadcn/ui defaults and must be added:

| Token | Suggested Value | Purpose |
|-------|-----------------|---------|
| `--chart-6` | oklch(0.55 0.18 280) | 6th chart series color |
| `--kpi-bg` | use `--card` initially | KPI card background (can equal `--card`) |
| `--kpi-positive` | oklch(0.55 0.18 142) | Positive delta indicator (green) |
| `--kpi-negative` | oklch(0.6 0.22 25) | Negative delta indicator (red) |
| `--table-row-hover` | use `--accent` initially | Table row hover (can equal `--accent`) |

**Recommendation:** Start by aliasing `--kpi-bg: var(--card)` and `--table-row-hover: var(--accent)`. This satisfies D-05's interface-only requirement while keeping the token vocabulary small. Expand only if sample page evaluation shows the need.

### v4 Breaking Change: Color Format

shadcn/ui v4 uses **oklch()** color values by default (previously hsl()). The oklch format has better perceptual uniformity, especially for chart colors. When extending with dashboard tokens, use oklch() to match the system.

**Confidence:** HIGH — verified from ui.shadcn.com/docs/theming.

---

## Composed Component Interface Catalog

### Recommendation: 12 Core Components

Based on the idea document component list (D-06), all 12 components from the list should be included. The idea document's table is the primary source of truth.

| Component | Tier | AI Controls | shadcn Primitives Wrapped |
|-----------|------|-------------|--------------------------|
| PageLayout | Page | children | — (structural shell) |
| PageHeader | Composed | title, subtitle?, action? | — |
| SearchBar | Composed | filters[] array | Input, Select, Button, DateRangePicker |
| KpiCardGroup | Composed | items[], cols (2 or 4) | Card, CardHeader, CardContent |
| ChartSection | Composed | charts[], cols (1 or 2) | Card |
| DataTable | Composed | columns[], data[], actions? | Table, TableHeader, TableBody, TableRow, TableCell |
| FormFieldSet | Composed | legend, children | — (layout only) |
| FormField | Composed | label, required?, description?, children | Field, FieldLabel, FieldDescription, FieldError (shadcn v4 form) |
| FormRow | Composed | cols (1 or 2), children | — (grid layout only) |
| FormActions | Composed | children (ActionButton only) | — |
| ConfirmDialog | Composed | title, description, onConfirm, onCancel, open | Dialog primitives |
| StatusBadge | Composed | status (string union), variant? | Badge |

### Critical Interface Note: shadcn/ui v4 Form Primitives

The shadcn/ui v4 form system uses `Field`, `FieldGroup`, `FieldLabel`, `FieldDescription`, `FieldError` from `@/components/ui/field` — **not** the older `FormField`, `FormItem`, `FormLabel`, `FormControl`, `FormMessage` chain that shadcn v3 documentation shows.

This matters for the `FormField` Composed component: it must wrap the v4 `Field > FieldLabel + Input + FieldError` structure, not the v3 structure.

**v4 form structure verified:**
```typescript
import { Field, FieldLabel, FieldDescription, FieldError } from "@/components/ui/field"
import { Input } from "@/components/ui/input"

// The correct shadcn v4 field structure (used inside FormField composed wrapper)
<Field data-invalid={fieldState.invalid}>
  <FieldLabel htmlFor="field-id">Label</FieldLabel>
  <Input id="field-id" aria-invalid={fieldState.invalid} {...field} />
  <FieldDescription>Helper text</FieldDescription>
  {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
</Field>
```

**Confidence:** MEDIUM — confirmed from ui.shadcn.com/docs/forms/react-hook-form, but the v4 form API shows `Field`/`FieldGroup` components that differ from classic shadcn form docs. The planner should verify this against the actual installed shadcn CLI version before implementing FormField interface contract.

### Forbidden Primitive Import Paths

These import paths are forbidden in page files. The rule document must list them explicitly:

```typescript
// ALL of these are FORBIDDEN in page files:
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Table, TableBody, ... } from "@/components/ui/table"
import { Card, CardHeader, ... } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Dialog, ... } from "@/components/ui/dialog"
import { Field, FieldLabel, ... } from "@/components/ui/field"
import { Select, ... } from "@/components/ui/select"
```

The allowed import path is:
```typescript
import { [ComponentName] } from "@/components/composed/[component-name]"
// or whatever the project's Composed layer import path is
```

---

## Common Pitfalls

### Pitfall 1: Rule File Exceeds Token Budget

**What goes wrong:** CLAUDE.md grows past the 80-line target as Phase 1 rules are added. The token and component hierarchy rules combined easily reach 150+ lines if not split.

**Prevention strategy:** From the first commit, CLAUDE.md contains only: (1) a single paragraph describing the project, (2) import directives pointing to `.claude/rules/*.md`, (3) 5–10 universal constraints that apply everywhere. All specific rules live in the scoped files.

**Warning sign:** `wc -l CLAUDE.md` returns more than 80.

### Pitfall 2: shadcn v3 Form Pattern Used Instead of v4

**What goes wrong:** Rule documents are written with the v3 `FormField > FormItem > FormControl > FormLabel` hierarchy, which is wrong for a shadcn/ui v4 installation. AI follows the rule but generates non-working code because the components don't exist.

**Prevention strategy:** Verify the installed shadcn version before writing form-related interface contracts. Check `package.json` for `shadcn` version and confirm the form primitives exist.

**Warning sign:** Generated code imports `FormControl` from `@/components/ui/form` but this file doesn't exist.

### Pitfall 3: className Appears in a Composed Component Interface

**What goes wrong:** During interface authoring, `className?: string` is added "just for flexibility." This immediately creates the escape hatch that D-07 was designed to prevent.

**Prevention strategy:** Perform an explicit "className audit" after writing all 12 component interfaces. Zero occurrences of `className` must appear in any Composed component's props type.

**Warning sign:** `grep -r "className" .claude/rules/` returns any result.

### Pitfall 4: Token Reference Too Long to Fit in Rules File

**What goes wrong:** All ~30 CSS variable names are listed in the token rule file, pushing it over the line budget. Alternatively, the rule file only references a separate token reference document that the AI won't consult during generation.

**Prevention strategy:** The token rule file lists only the 10–12 most-used tokens inline. The full token list lives in `tokens/globals.css` which is referenced but not recited. Rules say "use token names from tokens/globals.css; the most common are: [inline list]."

**Warning sign:** `.claude/rules/tokens.md` exceeds 120 lines.

### Pitfall 5: Component Interfaces Define Implementation Details

**What goes wrong:** The Composed component interface in the rule document includes rendering hints, internal layout descriptions, or pseudo-implementation code. AI treats these as constraints and either ignores them as too prescriptive or follows them rigidly and produces brittle code.

**Prevention strategy:** Interface contracts contain ONLY: (1) component name, (2) props TypeScript type, (3) one canonical TSX usage example. Nothing about internal structure.

**Warning sign:** Any Composed component interface section is longer than 15 lines.

---

## Code Examples

### CLAUDE.md Root File (Phase 1 Template)

```markdown
# Dashboard Rules

This project uses shadcn/ui with a strict 3-tier component hierarchy.
Read the scoped rules files below for all constraints.

@.claude/rules/components.md
@.claude/rules/tokens.md

## Always Apply

- Import Composed components from `@/components/composed/` ONLY. Never from `@/components/ui/`.
- Use CSS variable tokens for all color, spacing, and radius values. Never hardcode hex or rgb.
- Ask before creating a new component. Extend existing Composed components via typed variant props.
```

**Line count:** ~14 lines. Well within the 80-line budget.

### Component Rules File Structure

```markdown
---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
---

# Component Rules

## Tier Model

Three tiers. AI ONLY touches Composed and Page tiers.

- **Primitive** (`@/components/ui/`): shadcn/ui originals. AI must NEVER import these in page files.
- **Composed** (`@/components/composed/`): project wrappers. AI's ONLY import source.
- **Page** (`@/components/pages/`): skeleton templates. AI assembles these for each new page.

## Allowed Imports (Composed tier)

DO import these and ONLY these in page files:

- `PageLayout`, `PageHeader`
- `SearchBar`, `FilterBar`
- `KpiCardGroup`, `ChartSection`
- `DataTable`
- `FormFieldSet`, `FormField`, `FormRow`, `FormActions`
- `ConfirmDialog`, `StatusBadge`, `ActionButton`

## Forbidden Imports

NEVER import directly from `@/components/ui/` in page files.
// WHY: Direct primitive imports bypass all layout and style constraints.

## Component Interfaces
[interface contracts follow — one per component]
```

### Token Rules File Structure

```markdown
---
paths:
  - "src/**/*.{tsx,css}"
  - "app/**/*.{tsx,css}"
---

# Token Rules

## Rule: No Raw Values

NEVER use hex, rgb, or oklch literals in component code.
NEVER use Tailwind color primitives (gray-100, zinc-800, slate-50, etc.).
// WHY: Raw values bypass the token system and break dark mode / theming.

## Rule: Use These Tokens

Color: text-foreground, text-muted-foreground, bg-background, bg-card, bg-primary,
       text-primary-foreground, border, ring, text-destructive

Chart: var(--chart-1) through var(--chart-6)

KPI: bg-[--kpi-bg], text-[--kpi-positive], text-[--kpi-negative]

Radius: rounded-[--radius], rounded-[--radius-sm], rounded-[--radius-lg]

## Rule: Typography

Font sizes via Tailwind: text-xs, text-sm, text-base, text-lg, text-xl, text-2xl
Font weights: font-medium (labels), font-semibold (headings), font-normal (body)
// WHY: Custom font-size tokens are not in AI training data; Tailwind scale is.
```

### Composed Component Interface Example (PageHeader)

```typescript
// Source: component interface contract — no implementation
interface PageHeaderProps {
  title: string             // Required. Page title, rendered as h1.
  subtitle?: string         // Optional. Secondary description below title.
  action?: React.ReactNode  // Optional. One ActionButton only. Right-aligned.
}

// Canonical usage:
<PageHeader
  title="Campaigns"
  subtitle="14 active campaigns"
  action={<ActionButton onClick={onCreate}>New Campaign</ActionButton>}
/>

// Minimal usage (no action):
<PageHeader title="Reports" />
```

### Composed Component Interface Example (DataTable)

```typescript
interface DataTableColumn<T> {
  key: keyof T
  header: string
  sortable?: boolean        // Default: false
  render?: (value: T[keyof T], row: T) => React.ReactNode
}

interface DataTableProps<T> {
  columns: DataTableColumn<T>[]
  data: T[]
  onRowClick?: (row: T) => void
  actions?: React.ReactNode  // Toolbar actions (ActionButton only)
  loading?: boolean
  emptyMessage?: string      // Shown when data is empty
}

// Canonical usage:
<DataTable
  columns={[
    { key: "name", header: "Campaign", sortable: true },
    { key: "status", header: "Status", render: (v) => <StatusBadge status={v} /> },
    { key: "budget", header: "Budget", sortable: true },
  ]}
  data={campaigns}
  onRowClick={(row) => router.push(`/campaigns/${row.id}`)}
  actions={<ActionButton onClick={onCreate}>New</ActionButton>}
/>
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| hsl() CSS variable values in shadcn/ui | oklch() values | shadcn/ui v4 (2025) | Better perceptual uniformity; dashboard extension tokens should use oklch() |
| `.eslintrc.json` format | `eslint.config.js` flat config | ESLint v9+ | typescript-eslint v8 requires flat config; do not use legacy `.eslintrc` |
| shadcn v3 form: `FormField > FormItem > FormControl > FormLabel > FormMessage` | shadcn v4 form: `Field > FieldLabel + Input + FieldError` from `@/components/ui/field` | shadcn CLI v4 (2025) | FormField Composed component must wrap the v4 structure, not v3 |
| `tailwind.config.js` with theme extension | `@theme {}` CSS block in globals.css | Tailwind v4 | JS config is deprecated; CSS-first token definition is the only supported approach |

---

## Open Questions

1. **shadcn v4 form API stability**
   - What we know: The fetched docs show `Field`, `FieldGroup`, `FieldLabel`, `FieldDescription`, `FieldError` from `@/components/ui/field`
   - What's unclear: Is this the final v4 form API, or is it in transition? The older `FormField`/`FormControl` pattern still appears in many tutorials
   - Recommendation: Before writing the FormField interface contract in a plan task, run `npx shadcn@latest add form` in a test directory and inspect what components are generated

2. **Composed component import path convention**
   - What we know: Rule documents must specify the exact import path (`@/components/composed/` or similar)
   - What's unclear: The project has no existing code; the import path alias is undefined
   - Recommendation: Plan task should establish the import path alias (`@/components/composed/`) as the first step before writing interface contracts that reference it

3. **Typography token strategy**
   - What we know: shadcn/ui does not provide typography CSS variables by default
   - What's unclear: Whether to (a) use Tailwind's built-in type scale (text-sm, text-base, etc.) directly, or (b) add custom `--font-body`, `--font-heading` CSS variables
   - Recommendation: Use Tailwind's built-in type scale directly for TOKN-02. It's in the AI's training data. Custom typography variables are low-value complexity.

---

## Environment Availability

Step 2.6: SKIPPED (Phase 1 is documentation-only — no external runtime dependencies. The output artifacts are Markdown files and a CSS file. No tools beyond a text editor and `wc -l` are required for Phase 1.)

---

## Validation Architecture

Phase 1 produces rule documents and token definitions. There are no automated tests for these — they are validated in Phase 4 (VERF-01 through VERF-05). However, Phase 1 outputs must meet these measurable criteria before being considered complete:

| Deliverable | Measurable Pass Criteria |
|-------------|--------------------------|
| `tokens/globals.css` | `grep -c "^  --" tokens/globals.css` returns ≤ 35 (token count stays manageable) |
| `CLAUDE.md` | `wc -l CLAUDE.md` returns ≤ 80 |
| Each `.claude/rules/*.md` | `wc -l .claude/rules/[file].md` returns ≤ 120 |
| Composed component interfaces | `grep -r "className" .claude/rules/` returns 0 results |
| Composed component interfaces | All 12 components from idea document have interface contracts |
| Token rules file | Top 10-12 most-used tokens listed inline (not only in external file) |

These checks can be run as a shell one-liner at the end of each plan task to confirm the work meets the budget constraints.

---

## Sources

### Primary (HIGH confidence)

- [code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory) — Official Claude Code docs: CLAUDE.md format, `.claude/rules/` frontmatter syntax, `paths:` field, file loading behavior, size guidance
- [code.claude.com/docs/en/best-practices](https://code.claude.com/docs/en/best-practices) — Official Claude Code best practices: CLAUDE.md content guidance, pruning strategy
- [ui.shadcn.com/docs/theming](https://ui.shadcn.com/docs/theming) — Complete CSS variable list, oklch values, chart/sidebar/radius variables
- [ui.shadcn.com/docs/components/card](https://ui.shadcn.com/docs/components/card) — Card component API: CardHeader, CardContent, CardTitle, CardDescription, CardAction, CardFooter
- [ui.shadcn.com/docs/components/button](https://ui.shadcn.com/docs/components/button) — Button variants (default, outline, secondary, ghost, destructive, link) and sizes
- [ui.shadcn.com/docs/components/table](https://ui.shadcn.com/docs/components/table) — Table component API: Table, TableHeader, TableBody, TableRow, TableHead, TableCell, TableFooter
- [ui.shadcn.com/docs/components/badge](https://ui.shadcn.com/docs/components/badge) — Badge variants (default, secondary, destructive, outline, ghost)
- [ui.shadcn.com/docs/forms/react-hook-form](https://ui.shadcn.com/docs/forms/react-hook-form) — v4 form component hierarchy (Field, FieldLabel, FieldError from @/components/ui/field)
- `.planning/research/STACK.md` — Technology versions, installation commands (verified 2026-03-26)
- `.planning/research/PITFALLS.md` — 10 critical pitfalls with phase attribution
- `.planning/research/ARCHITECTURE.md` — Build order, component boundary analysis
- `.planning/research/SUMMARY.md` — Executive summary of project-level research

### Secondary (MEDIUM confidence)

- [claudefa.st/blog/guide/mechanics/rules-directory](https://claudefa.st/blog/guide/mechanics/rules-directory) — `.claude/rules/` with path targeting patterns (mirrors official docs)
- `/Users/eyelove/workspace/cc-note/ideas/2026-03-25-ai-dashboard-design-workflow/ai-dashboard-design-workflow.md` — Idea document: primary source for component list, page patterns, form structure

---

## Metadata

**Confidence breakdown:**
- shadcn/ui CSS variables: HIGH — fetched directly from official theming docs
- .claude/rules/ frontmatter format: HIGH — fetched from official Claude Code memory docs
- Composed component interface pattern: HIGH — validated by pitfalls research + official shadcn composition guides
- shadcn v4 form API: MEDIUM — documented at official URL but differs from widely-circulated v3 tutorials; verify before implementing
- Dashboard token extension names: LOW (discretionary) — names proposed here are reasonable starting points, not authoritative

**Research date:** 2026-03-26
**Valid until:** 2026-06-26 (shadcn/ui and Claude Code docs are relatively stable; form API may shift)
