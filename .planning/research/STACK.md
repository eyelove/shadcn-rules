# Stack Research

**Domain:** AI-enforced UI rule system for shadcn/ui dashboards
**Researched:** 2026-03-26
**Confidence:** HIGH (core stack verified via npm registry + official docs; rule format section MEDIUM due to rapid ecosystem evolution)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| shadcn/ui CLI | 4.1.0 | Install and distribute components; run registry | The authoritative CLI for the shadcn/ui ecosystem. Version 4.x introduced the registry system that lets you distribute custom Composed components via JSON — directly enables the 3-layer component architecture |
| Tailwind CSS | 4.2.2 | Design token system + utility classes | v4's `@theme` directive defines tokens as CSS variables and generates utility classes simultaneously. One source of truth: define `--color-primary` once, get both `bg-primary` utility and `var(--color-primary)` at runtime. Eliminates the JS config file entirely |
| TypeScript | 6.0.2 | Rule documents, validation scripts, ESLint rules | Type safety on component prop contracts enforces the allowed-pattern system; custom ESLint rules are written in TS for type-aware AST traversal |
| React | 19.2.4 | Component layer for sample page verification | Required for rendering sample pages that visually validate rule effectiveness |
| class-variance-authority (CVA) | 0.7.1 | Variant API for Composed components | shadcn/ui uses CVA internally. Composed wrapper components must extend CVA for variants to stay consistent with the ecosystem's type-safe API pattern |
| clsx + tailwind-merge | 2.1.1 / 3.5.0 | Class merging utility (`cn()`) | Standard shadcn/ui utility. `twMerge` resolves Tailwind class conflicts; `clsx` handles conditional classes. Every component should expose a `className` prop that passes through `cn()` |

### Rule Document Formats

| Format | Purpose | When to Use |
|--------|---------|-------------|
| `CLAUDE.md` | Claude Code project rules — loaded automatically at session start | Primary format for this project. Claude reads hierarchical CLAUDE.md files; project root CLAUDE.md becomes the AI's standing orders |
| `AGENTS.md` | Cross-tool universal rule file | Add as secondary file for Cursor, GitHub Copilot, Windsurf compatibility. Officially emerged mid-2025 from collaboration between Sourcegraph, OpenAI, Google, Cursor |
| `.cursor/rules/*.mdc` | Cursor-specific scoped rules with YAML frontmatter | Use when you need file-pattern-scoped activation (e.g., `globs: ["**/*.tsx"]` triggers only on TSX files) |
| Plain `.md` rule files | Component library documentation, per-pattern guides | Keep as reference documents linked from CLAUDE.md; not directly consumed by AI tools |

### Violation Detection Tools

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| ESLint | 10.1.0 | Static analysis + custom design system rules | Always. Custom rules can detect: direct `<div>` layout usage, hardcoded hex/rgb colors, `style={{}}` inline props, forbidden primitive component imports |
| typescript-eslint | 8.57.2 | TypeScript-aware AST traversal for custom rules | Write violation detection rules that understand component import types — e.g., flag `import { Button } from "@/components/ui/button"` when the rule requires `import { Button } from "@/components/composed/button"` |
| Bash / shell scripts | — | Quick violation grep for CI pre-commit hooks | Fast path for pattern matching without spinning up ESLint: `grep -rn 'style={{' src/` for inline style detection, `grep -rn 'className=".*#[0-9a-fA-F]' src/` for hardcoded colors |

### Visual Validation Tools

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Storybook | 10.3.3 | Isolated component rendering + documentation | Document each Composed component in isolation. Shows allowed variants, prop API, and sample usage — the visual proof that rules produce consistent output |
| Playwright (`@playwright/test`) | 1.58.2 | Visual screenshot regression — local, no cloud | Self-hosted visual regression. `toHaveScreenshot()` captures baseline renders of sample pages; subsequent runs compare pixel-by-pixel. Zero external dependencies. Choose over Chromatic for personal/single-developer projects |
| Lost Pixel | 3.22.0 | Open-source Storybook visual regression, self-hosted | Alternative to Chromatic. Integrates with Storybook stories. Better for component-level (not page-level) regression. No subscription required |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@radix-ui/react-slot` | 1.2.4 | `asChild` prop pattern for polymorphic Composed components | Any Composed component that should render as a different HTML element — standard shadcn/ui pattern |
| `lucide-react` | 1.7.0 | Icon system | The canonical icon library for shadcn/ui; rule documents should specify that Composed components use `lucide-react` exclusively — never raw SVG or other icon libs |
| Atlassian ESLint plugin (reference) | — | Reference implementation for design token enforcement | Study source for writing custom `no-hardcoded-color` rules; Atlassian's `ensure-design-token-usage` rule is the standard pattern for token enforcement via AST |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `shadcn` CLI | Install components, run registry | `npx shadcn@latest add` pulls components; `npx shadcn@latest build` generates registry JSON for Composed component distribution |
| `eslint --rule` (inline rule syntax) | Test custom rules during development without publishing | Use `--rulesdir ./src/rules` to load local rule files; faster iteration than publishing an ESLint plugin |
| AST Explorer (astexplorer.net) | Visualize JSX/TSX AST for writing ESLint rules | Set parser to `@typescript-eslint/parser` when writing rules that need to understand TypeScript types |
| `@storybook/addon-themes` | Toggle light/dark mode in Storybook | Required because Storybook runs outside app context — must manually apply `dark` class for Tailwind dark mode to work |

---

## Installation

```bash
# Core runtime
npm install react@19 react-dom@19

# shadcn/ui ecosystem
npm install class-variance-authority@0.7.1 clsx@2.1.1 tailwind-merge@3.5.0 @radix-ui/react-slot@1.2.4 lucide-react@1.7.0

# shadcn CLI (dev)
npm install -D shadcn@4.1.0

# Tailwind
npm install -D tailwindcss@4.2.2

# TypeScript
npm install -D typescript@6.0.2

# ESLint + custom rule development
npm install -D eslint@10.1.0 typescript-eslint@8.57.2

# Visual validation (choose one path)
# Path A: Storybook + Lost Pixel (component-level)
npm install -D storybook@10.3.3 lost-pixel@3.22.0 @storybook/addon-themes

# Path B: Playwright (page-level)
npm install -D @playwright/test@1.58.2
npx playwright install chromium
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `AGENTS.md` as secondary rule format | `.cursorrules` (legacy) | Never — `.cursorrules` is deprecated in favor of `.cursor/rules/*.mdc`; AGENTS.md has broader cross-tool support |
| Playwright `toHaveScreenshot()` for local visual regression | Chromatic (cloud) | Use Chromatic when team size > 1 and you need async review UI and PR integration; overkill for single-developer personal use |
| ESLint custom rules for violation detection | Semgrep | Use Semgrep when you need cross-language pattern matching or semantic analysis beyond AST; ESLint is sufficient for JSX/TSX design system rules |
| Lost Pixel for Storybook regression | Percy | Percy requires paid plan; Lost Pixel is self-hosted open-source with equivalent feature set |
| Tailwind CSS v4 `@theme` for design tokens | Style Dictionary + CSS variables | Use Style Dictionary if your tokens originate in Figma and must sync bidirectionally; for code-first projects, v4's native token system is simpler |
| CVA for variant management | `tailwind-variants` | `tailwind-variants` has slightly better TypeScript inference and supports responsive variants; switch if CVA's API feels limiting, but CVA is what shadcn/ui uses internally |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `tailwind.config.js` for design tokens | Deprecated in v4; CSS-in-JS approach loses runtime CSS variable access; creates two-file token maintenance burden | `@theme {}` block in your main CSS file |
| Hardcoded hex/rgb values in className | Breaks dark mode, theming, and token governance — exactly the anti-pattern this rule system is designed to prevent | CSS custom properties via `@theme` tokens (`text-primary`, `bg-muted`, etc.) |
| Direct Radix UI primitives in page code | Bypasses the Composed component layer; defeats the entire architecture | Composed wrapper components that wrap primitives |
| Chromatic subscription for personal projects | Cost barrier for single-developer use; overkill | Playwright `toHaveScreenshot()` or Lost Pixel (both free, self-hosted) |
| Publishing ESLint rules as npm package | Unnecessary complexity for personal project use; adds maintenance overhead | `--rulesdir` to load rules from local directory, or inline `eslint.config.js` rules |
| Emotion / styled-components | Conflicts with Tailwind's utility-first approach; can't be statically analyzed for token violations | Tailwind utilities + CVA for variants |
| Multiple icon libraries | Creates visual inconsistency between components — the exact problem this system prevents | `lucide-react` exclusively, specified in CLAUDE.md rules |

---

## Stack Patterns by Variant

**If validating rule effectiveness at component level:**
- Use Storybook + Lost Pixel
- Each Composed component gets a story with all variants
- Lost Pixel catches regressions when rule changes alter component output

**If validating rule effectiveness at page level:**
- Use Playwright `toHaveScreenshot()`
- Render sample dashboard pages in headless browser
- Compare full-page screenshots across rule iterations

**If writing the CLAUDE.md rule document itself:**
- Structure rules as "USE X" not "DON'T use Y" — positive constraints are easier for AI to follow
- Keep each rule atomic: one constraint per bullet
- Group by component layer (Primitive rules / Composed rules / Page rules)
- Include import path rules — AI compliance depends on knowing exactly which import path is allowed

**If distributing Composed components across projects:**
- Use shadcn registry (`registry.json`) instead of npm
- Registry items can include component files, CSS, and dependency declarations
- `npx shadcn@latest add [registry-url]/[component]` installs into target project

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| tailwindcss@4.2.2 | Storybook@10.3.3 | Requires `@source` directive in CSS to point Tailwind at Storybook story files; import global CSS in `.storybook/preview.ts` |
| typescript-eslint@8.57.2 | eslint@10.1.0 | typescript-eslint v8 uses flat config (`eslint.config.js`) — do NOT use `.eslintrc.json` which is the legacy format |
| react@19.2.4 | @radix-ui/react-slot@1.2.4 | Radix UI components are React 19 compatible as of their current releases |
| shadcn@4.1.0 | tailwindcss@4.x | shadcn CLI v4 is built for Tailwind v4; do NOT mix shadcn v4 with Tailwind v3 |
| CVA@0.7.1 | tailwind-merge@3.5.0 | No conflicts; they serve different purposes (variant API vs class deduplication) and compose via `cn()` |

---

## Sources

- [Tailwind CSS v4.0 release announcement](https://tailwindcss.com/blog/tailwindcss-v4) — `@theme` directive, CSS-first config (HIGH confidence, official)
- [Vercel Academy: Extending shadcn/ui with Custom Components](https://vercel.com/academy/shadcn-ui/extending-shadcn-ui-with-custom-components) — Composition patterns, CVA usage (HIGH confidence, official)
- [shadcn/ui Registry Introduction](https://ui.shadcn.com/docs/registry) — Registry system for component distribution (HIGH confidence, official)
- [CLAUDE.md, AGENTS.md, and Every AI Config File Explained](https://www.deployhq.com/blog/ai-coding-config-files-guide) — Rule format comparison (MEDIUM confidence, third-party analysis)
- [AGENTS.md standard](https://agents.md/) — Cross-tool rule format specification (MEDIUM confidence)
- [Cursor Rules Documentation](https://cursor.com/docs/context/rules) — `.mdc` format, activation modes (HIGH confidence, official)
- [typescript-eslint Custom Rules](https://typescript-eslint.io/developers/custom-rules/) — AST rule authoring (HIGH confidence, official)
- [Atlassian ESLint plugin — ensure-design-token-usage](https://atlassian.design/components/eslint-plugin-design-system/ensure-design-token-usage/) — Reference implementation for token enforcement rules (HIGH confidence, production example)
- [Lost Pixel: Visual Regression Testing of shadcn-ui with Storybook](https://www.lost-pixel.com/blog/visual-regression-testing-of-shadcn-ui-with-storybook) — Lost Pixel + Storybook integration (MEDIUM confidence)
- npm registry (verified 2026-03-26) — All version numbers (HIGH confidence)

---

*Stack research for: AI-enforced UI component rules — shadcn/ui dashboard design system*
*Researched: 2026-03-26*
