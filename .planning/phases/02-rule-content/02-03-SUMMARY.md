---
phase: 02-rule-content
plan: 03
subsystem: ui
tags: [naming, rules, documentation, shadcn, tailwind, barrel-export]

# Dependency graph
requires:
  - phase: 02-rule-content
    plan: 01
    provides: "forbidden.md ready for CLAUDE.md @import wiring"
  - phase: 02-rule-content
    plan: 02
    provides: "forms.md ready for CLAUDE.md @import wiring"
provides:
  - "NAME-01: file naming convention table covering page/component/hook/type/CSS token files"
  - "NAME-02: Composed component naming patterns with barrel export FORBIDDEN/CORRECT pair"
  - "NAME-03: CSS variable prefix conventions and Tailwind color class requirements"
  - "CLAUDE.md wired with all 6 @import directives — complete rule navigation from one entry point"
  - "check-rules.sh extended with 3 new checks (FORB-05 Textarea, FORB-05 Checkbox, rounded-sm)"
affects:
  - sample-generation
  - phase-03-verifier

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CLAUDE.md as single entry point: all 6 rule files reachable via @import chain"
    - "Naming rule structure: table-per-type with WHY comments and FORBIDDEN/CORRECT pairs for barrel export"
    - "check-rules.sh extended pattern: new check() calls appended, bash -n validates syntax"

key-files:
  created:
    - .claude/rules/naming.md
  modified:
    - CLAUDE.md
    - scripts/check-rules.sh

key-decisions:
  - "naming.md stays under 90 lines (89) — all 3 NAME rules plus Directory Structure and Escape Hatch fit in the budget"
  - "Barrel export rule documented in NAME-02 with explicit FORBIDDEN/CORRECT import examples — reinforces D-16 pattern"
  - "FORB-05 checks added with name= attribute heuristic — targets the most common bare-input pattern in form files"
  - "rounded-sm added as check 16 — completes the rounded-* token requirement coverage"

patterns-established:
  - "Phase 2 integration pattern: create rule files first (02-01, 02-02), wire them in one final plan (02-03)"
  - "check-rules.sh extended per-plan as new rules are authored — checker grows with the rule set"

requirements-completed: [NAME-01, NAME-02, NAME-03]

# Metrics
duration: 2min
completed: 2026-03-26
---

# Phase 02 Plan 03: Naming Conventions and Integration Summary

**naming.md with NAME-01/02/03 naming rules, CLAUDE.md wired with all 6 @import directives, check-rules.sh extended to 16 checks — Phase 2 rule authoring complete**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-26T07:56:17Z
- **Completed:** 2026-03-26T07:58:36Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created `.claude/rules/naming.md` (89 lines) with NAME-01 (file naming table, 5 file types), NAME-02 (component naming patterns + barrel export FORBIDDEN/CORRECT pair), NAME-03 (CSS variable prefixes and Tailwind color class requirements), directory structure reference, and Escape Hatch
- Updated `CLAUDE.md` from 24 to 27 lines — added `@.claude/rules/forbidden.md`, `@.claude/rules/forms.md`, `@.claude/rules/naming.md` after existing 3 imports (now 6 total)
- Extended `scripts/check-rules.sh` with 3 new `check()` calls: FORB-05 Textarea pattern, FORB-05 Checkbox pattern, Tailwind `rounded-sm` check
- All 18 checks pass against 4 existing test samples (0 violations) — no false positives introduced

## Task Commits

Each task was committed atomically:

1. **Task 1: Create .claude/rules/naming.md** - `6178cbd` (feat)
2. **Task 2: Update CLAUDE.md imports and extend check-rules.sh** - `ac3f81c` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `.claude/rules/naming.md` — New naming convention rules (89 lines) with NAME-01, NAME-02, NAME-03, Directory Structure, Escape Hatch
- `CLAUDE.md` — 3 new @import directives added (24 → 27 lines, 3 → 6 imports)
- `scripts/check-rules.sh` — 3 new check() calls added for FORB-05 patterns and rounded-sm (13 → 16 check calls)

## Decisions Made

- Barrel export rule placed in NAME-02 (Component Naming) rather than as a separate section — barrel export is a component naming concern, not a file naming concern
- FORB-05 `<Textarea[^/]*name=` heuristic targets bare Textarea elements with a `name` attribute — the most common non-self-closing form element pattern indicating it wraps content outside FormField
- `rounded-sm` added as check 16 to complete rounded-* coverage alongside the existing `rounded-(md|lg|xl|2xl|full)` check from Phase 1

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all rule content is complete and wired. No placeholder text or TODO markers.

## Self-Check: PASSED

All files exist and all task commits verified:
- FOUND: .claude/rules/naming.md
- FOUND: CLAUDE.md (6 @import lines confirmed)
- FOUND: scripts/check-rules.sh (16 check calls, syntax OK)
- FOUND: .planning/phases/02-rule-content/02-03-SUMMARY.md
- FOUND: 6178cbd (Task 1 commit)
- FOUND: ac3f81c (Task 2 commit)
- FOUND: 18/18 checker passes on test samples

---
*Phase: 02-rule-content*
*Completed: 2026-03-26*
