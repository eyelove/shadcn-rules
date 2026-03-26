# Phase 2: Rule Content - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.

**Date:** 2026-03-26
**Phase:** 02-rule-content
**Areas discussed:** Forbidden Patterns, Form Rules, Naming Conventions, Claude's Discretion

---

## Forbidden Patterns

| Option | Description | Selected |
|--------|-------------|----------|
| Separate forbidden.md | All forbidden patterns in one dedicated file with Good/Bad examples | ✓ |
| Augment existing | Add to tokens.md/components.md where patterns already exist | |
| You decide | Claude judges based on test results | |

**User's choice:** Separate forbidden.md

---

## Form Rules

| Option | Description | Selected |
|--------|-------------|----------|
| Validation patterns | Required fields, error message display rules | ✓ |
| Field spacing/layout | FormRow cols, FormFieldSet gap, detailed layout rules | ✓ |
| Basic structure sufficient | Phase 1's FormFieldSet > FormField > Input is enough | |
| You decide | Based on test findings | ✓ |

**User's choice:** Validation + Layout + Claude's discretion

---

## Naming Conventions

| Option | Description | Selected |
|--------|-------------|----------|
| File naming rules | kebab-case pages, PascalCase components, etc. | ✓ |
| Directory structure | components/, pages/, hooks/, types/ organization | ✓ |
| You decide | Follow shadcn/Next.js conventions | |

**User's choice:** File naming + Directory structure

---

## Claude's Discretion

- Additional forbidden patterns beyond 5 FORB requirements
- Form validation depth
- Additional naming rules
- check-rules.sh updates

## Deferred Ideas

None
