# Dashboard Rules

This project uses shadcn/ui with a 3-tier component hierarchy enforced by rule documents.
You are building a dashboard UI. Follow these rules for every file you touch.

@.claude/rules/components.md
@.claude/rules/component-interfaces.md
@.claude/rules/tokens.md

## Always Apply

- **Imports**: Use ONLY `@/components/composed/` for UI components. Never import from `@/components/ui/` in page or feature files.
  // WHY: Direct primitive imports bypass all layout and consistency constraints.

- **Tokens**: Use CSS custom property tokens for ALL color, spacing, and radius values. Never hardcode hex, rgb, or oklch literals.
  // WHY: Hardcoded values break theming and make dark mode impossible to maintain.

- **No inline styles**: Never use `style={{}}` on any element. Exception: third-party library API props (e.g., Recharts Tooltip contentStyle) — but values MUST still be CSS custom property tokens.
  // WHY: Inline styles bypass the token system and are impossible to audit automatically.

- **New components**: Before creating a new UI component, propose it. Wait for approval. Create only in `@/components/composed/` with typed props and no className passthrough.
  // WHY: Unauthorized components fragment the system and make rules unenforceable.

- **Rule files**: When in doubt about what is allowed, read `.claude/rules/components.md` for component rules and `.claude/rules/tokens.md` for token rules. Do not infer — look it up.
