# Phase 1: Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-26
**Phase:** 01-foundation
**Areas discussed:** Token Structure, Composed Components, Document Structure, Rule Writing Style

---

## Token Structure

User clarified early: "shadcn/ui의 테마정의와 컴포넌트 규칙을 정의하자" — this locked the token approach to shadcn/ui's existing CSS variable system before formal options were presented.

**User's choice:** Use shadcn/ui CSS variable system as-is, extend only for dashboard-specific needs.
**Notes:** No separate token design needed — shadcn's system is the standard.

---

## Composed Components

| Option | Description | Selected |
|--------|-------------|----------|
| Interface only | Component name + props type + usage example code only | ✓ |
| Stub code included | Interface + actual implementation stub | |
| You decide | Claude judges appropriate depth | |

**User's choice:** Interface only
**Notes:** No implementation stubs in rule documents.

| Option | Description | Selected |
|--------|-------------|----------|
| Core ~10 | PageLayout, SearchBar, DataTable, KpiCard, FormField etc. essential only | |
| Extended 15~20 | Core + StatusBadge, ConfirmDialog, ChartSection etc. | |
| You decide | Based on idea document's component list | ✓ |

**User's choice:** You decide (Claude's discretion based on idea document)

### User Clarification (free text)

User described a 2-layer rule architecture:
1. Page-level patterns — ordered block sequences per page type
2. Component-level templates — internal structure of each block

Specific examples provided:
- Dashboard: Title,Button → FilterBar → KPI(2,4) → Chart → DataTable
- List: Title,Button → FilterBar → DataTable
- Form: Title → Form → FormActionButtons
- TitleBar: title + main button
- FilterBar: search input, date range, status, search button
- DataTable: sort, search, on/off, column order, per-column UI, row checkboxes

---

## Document Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Single file | All rules in one CLAUDE.md | |
| Modular (Recommended) | CLAUDE.md overview + .claude/rules/ scoped files | ✓ |
| You decide | Claude judges | |

**User's choice:** Modular

| Option | Description | Selected |
|--------|-------------|----------|
| Claude Code only | CLAUDE.md + .claude/rules/ only | ✓ |
| Multi-tool | CLAUDE.md + .cursorrules + AGENTS.md | |
| You decide | Claude judges | |

**User's choice:** Claude Code only

---

## Rule Writing Style

| Option | Description | Selected |
|--------|-------------|----------|
| Imperative (Recommended) | "DO this", "NEVER do that" — direct | ✓ |
| Descriptive | "The reason is..." background-focused | |
| Imperative + WHY | Imperative rule + one-line WHY comment | |

**User's choice:** Imperative

| Option | Description | Selected |
|--------|-------------|----------|
| Good/Bad pairs | Forbidden (✗) + correct (✓) side by side | |
| Good only | Correct pattern only — concise | |
| You decide | Claude judges per rule | ✓ |

**User's choice:** You decide

| Option | Description | Selected |
|--------|-------------|----------|
| English | AI follows English rules better | ✓ |
| Korean | Easier for me to read | |
| Mixed | Rules in English, comments in Korean | |

**User's choice:** English

---

## Claude's Discretion

- Number of Composed components (guided by idea document)
- Example code depth per rule (Good-only vs Good/Bad)
- Dashboard-specific token names and values

## Deferred Ideas

None
