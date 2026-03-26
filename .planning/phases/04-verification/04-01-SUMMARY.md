---
phase: 04-verification
plan: 01
subsystem: testing
tags: [bash, grep, ci, automation, shadcn, rules]

# Dependency graph
requires:
  - phase: 02-rule-content
    provides: forbidden.md, forms.md, naming.md rule files this checker enforces
  - phase: 03-page-templates
    provides: page-templates.md rules this checker enforces
provides:
  - scripts/check-rules.sh extended from 18 to 33 grep-based checks covering FORB-01/02/03/04/05, FORM-02/03, NAME-02/03, PAGE-02/04 structural rules
  - CI-compatible exit code (0 = clean, N = N violations)
affects: [04-02, 04-03, 04-04]

# Tech tracking
tech-stack:
  added: []
  patterns: ["grep-based violation detection with check()/check_absent() helpers", "Sectioned output with FORBIDDEN PATTERNS / FORM STRUCTURE / NAMING CONVENTIONS / PAGE TEMPLATE STRUCTURE / REQUIRED PATTERNS", "exit $VIOLATIONS for CI integration"]

key-files:
  created: []
  modified:
    - scripts/check-rules.sh

key-decisions:
  - "check_absent used sparingly — only for patterns that MUST be present (barrel import); all new checks use check() to detect violations"
  - "KpiCardGroup check flags presence as a violation on any page — acceptable because only list pages are tested in the single current sample; this will need review when detail/dashboard samples exist"
  - "console.log check added to enforce production code quality; existing sample has 3 violations that will be fixed in 04-02 sample regeneration"

patterns-established:
  - "Pattern: Bash check() helper — grep for forbidden pattern → FAIL if found, PASS if absent"
  - "Pattern: Sections group related checks under echo header banners for readable CI output"
  - "Pattern: exit $VIOLATIONS at script end — only one exit point, numeric exit code"

requirements-completed: [VERF-01]

# Metrics
duration: 5min
completed: 2026-03-26
---

# Phase 4 Plan 01: Extended Violation Checker Summary

**check-rules.sh extended from 18 to 33 grep-based checks with FORM STRUCTURE, NAMING CONVENTIONS, and PAGE TEMPLATE STRUCTURE sections, CI-compatible exit code**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-26T10:54:30Z
- **Completed:** 2026-03-26T10:56:36Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Extended scripts/check-rules.sh from 18 checks to 33 checks (83% increase)
- Added FORM STRUCTURE section (5 new checks): reversed button order, bare label tags, inline form style, FormActions inside FormFieldSet, raw input tag detection
- Added NAMING CONVENTIONS section (4 new checks): direct composed file imports, UI/Base prefix anti-patterns, CSS var definitions in TSX, var(--) in className
- Added PAGE TEMPLATE STRUCTURE section (6 new checks): TabGroup forbidden, ChartSection cols=1, ChartSection without cols, KpiCardGroup, span flex container, console.log
- Script exits with violation count for CI integration — 0 = clean, N = N violations
- All 5 section headers present: FORBIDDEN PATTERNS, FORM STRUCTURE, NAMING CONVENTIONS, PAGE TEMPLATE STRUCTURE, REQUIRED PATTERNS

## Task Commits

Each task was committed atomically:

1. **Task 1: Add form, naming, and page template checks to check-rules.sh** - `aa6d3d0` (feat)

**Plan metadata:** (included in final docs commit)

## Files Created/Modified
- `scripts/check-rules.sh` - Extended from 18 to 33 checks, added 3 new sections

## Decisions Made
- Used `check()` for all new checks (detect forbidden patterns) — only existing `check_absent` for barrel import presence check. All Phase 2/3 rules produce violations by presence, not absence.
- KpiCardGroup check flags it on any page — conservative but adequate for current single sample (list page). Detail/dashboard samples added in 04-02 will test whether this check needs scoping.
- console.log check catches production quality violations — the existing campaign-list.tsx sample has 3 violations (expected; to be fixed in 04-02 sample regeneration).

## Deviations from Plan

None — plan executed exactly as written. The plan's check() patterns were used as specified. The KpiCardGroup check comment in the plan ("No KpiCardGroup without DataTable on same page") was simplified to just "No KpiCardGroup" since single-file scanning cannot correlate DataTable presence — documented in decisions.

## Issues Encountered

- Only 1 of 4 expected test samples exists (campaign-list.tsx only). The plan referenced "4 existing samples pass" but the tests/samples/ directory contains only campaign-list.tsx. Script ran cleanly against this single file with 32 PASS and 1 FAIL (console.log violation). The plan explicitly allows non-zero exit as acceptable: "OR exits non-zero and lists specific violations for fixing in later plans." The console.log violations will be addressed in 04-02 when samples are regenerated.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness
- check-rules.sh is now production-ready for CI integration with 33 checks
- console.log violations in campaign-list.tsx sample will be resolved in 04-02 (sample regeneration)
- 04-02 can safely rely on this script to validate all 4 new sample pages against the full rule set

---
*Phase: 04-verification*
*Completed: 2026-03-26*
