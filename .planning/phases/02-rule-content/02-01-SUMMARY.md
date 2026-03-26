---
phase: 02-rule-content
plan: 01
subsystem: ui
tags: [rules, forbidden-patterns, design-tokens, shadcn]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: tokens.md and components.md with existing forbidden content to consolidate
provides:
  - Single-source-of-truth forbidden.md with FORB-01 through FORB-05
  - Consolidated forbidden pattern catalogue with WHY comments and FORBIDDEN/CORRECT pairs
  - Recharts third-party library exception explicitly documented
  - Escape Hatch Process with 5-step approval flow
  - tokens.md and components.md updated with pointers, duplicate content removed
affects: [02-02-forms, 02-03-naming, future AI consumers of rule files]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "forbidden.md as single source of truth: forbidden rules live in one file, other files point to it"
    - "FORB-XX naming convention for forbidden pattern rules enabling precise cross-referencing"
    - "Escape Hatch Process: 5-step ask-before-implement flow for all forbidden pattern exceptions"

key-files:
  created:
    - .claude/rules/forbidden.md
  modified:
    - .claude/rules/tokens.md
    - .claude/rules/components.md

key-decisions:
  - "forbidden.md is the single source of truth — tokens.md and components.md reference it, not duplicate it"
  - "FORB-03 exception: span with text-styling classes inside DataTable render functions is allowed (per existing components.md rule)"
  - "tokens.md Chart & Library Props section preserved as positive usage guide — not a duplicate prohibition"
  - "components.md Forbidden Imports list preserved as-is — it is an allowlist, not duplicate prohibition"

patterns-established:
  - "Rule consolidation: when multiple files share the same prohibition, create a dedicated file and cross-reference"
  - "Escape Hatch sections: document the approval PROCESS (ask → approve → implement), not just 'sometimes okay'"

requirements-completed: [FORB-01, FORB-02, FORB-03, FORB-04, FORB-05]

# Metrics
duration: 5min
completed: 2026-03-26
---

# Phase 2 Plan 01: Forbidden Patterns Summary

**Single forbidden.md catalogue with 5 explicit FORB rules, FORBIDDEN/CORRECT code pairs, Recharts exception, and Escape Hatch Process — duplicate content removed from tokens.md and components.md**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-26T07:50:53Z
- **Completed:** 2026-03-26T07:56:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created `.claude/rules/forbidden.md` with all 5 FORB rules (FORB-01 through FORB-05), each with rule statement, WHY comment, FORBIDDEN code examples, and CORRECT replacement
- Documented Recharts `contentStyle` third-party library exception in FORB-01 with explicit ALLOWED/FORBIDDEN pair (per D-15)
- Added 5-step Escape Hatch Process that enforces ask-before-implement for any forbidden pattern exception
- Condensed tokens.md Forbidden Patterns block (13 lines of duplicate content) to a single pointer line
- Added forbidden.md pointer to components.md Escape Hatch section

## Task Commits

Each task was committed atomically:

1. **Task 1: Create .claude/rules/forbidden.md with all 5 FORB rules** - `ab42603` (feat)
2. **Task 2: Update tokens.md and components.md with pointers to forbidden.md** - `7c12f4d` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `.claude/rules/forbidden.md` - New single-source-of-truth for all 5 forbidden patterns (118 lines)
- `.claude/rules/tokens.md` - Forbidden Patterns section replaced with pointer, reduced from 100 to 89 lines
- `.claude/rules/components.md` - Pointer added to Escape Hatch section, all other content unchanged

## Decisions Made

- Preserved `tokens.md` Chart & Library Props section — it is a positive usage guide with CORRECT/FORBIDDEN examples for chart props, not a duplicate of the color prohibition
- Preserved `components.md` Forbidden Imports list — it is a specific allowlist/blocklist of import paths, not a duplicate of forbidden.md content
- Added `// FORBIDDEN — raw span as layout wrapper` example to FORB-03 to meet the >10 FORBIDDEN instances criterion (template in plan produced only 9; the addition clarified the rule)

## Deviations from Plan

None — plan executed exactly as written with one minor content addition (extra FORB-03 FORBIDDEN example to meet acceptance criteria count of 10+, as the provided plan template only produced 9 FORBIDDEN occurrences).

## Issues Encountered

Minor plan spec inconsistency: The plan template for forbidden.md (when implemented literally) produces 9 occurrences of "FORBIDDEN", but the acceptance criteria required 10 or more. Added one additional FORBIDDEN example to FORB-03 (span layout container case) to satisfy the criterion while improving rule clarity.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- forbidden.md is complete and ready for reference by forms.md (Plan 02-02) and naming.md (Plan 02-03)
- tokens.md and components.md are leaner and cross-referenced — no duplicate rule bodies remain
- CLAUDE.md does not yet import forbidden.md directly — the rule files are accessed through @import chain

## Self-Check: PASSED

All files exist and all task commits verified:
- FOUND: .claude/rules/forbidden.md
- FOUND: .claude/rules/tokens.md
- FOUND: .claude/rules/components.md
- FOUND: .planning/phases/02-rule-content/02-01-SUMMARY.md
- FOUND: ab42603 (Task 1 commit)
- FOUND: 7c12f4d (Task 2 commit)

---
*Phase: 02-rule-content*
*Completed: 2026-03-26*
