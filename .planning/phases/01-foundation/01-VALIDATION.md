---
phase: 1
slug: foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-26
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | grep/diff-based file validation (no runtime tests — output is rule documents) |
| **Config file** | none — rule documents are validated by content checks |
| **Quick run command** | `grep -c "WHY:" .claude/rules/*.md` |
| **Full suite command** | `bash scripts/check-rules.sh` (created in Phase 4) |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Verify file exists and is non-empty
- **After every plan wave:** Check rule file lengths (<120 lines each), WHY annotations present
- **Before `/gsd:verify-work`:** Full content review against REQUIREMENTS.md
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | TOKN-01~05 | content | `grep -c "color\|spacing\|radius" .claude/rules/tokens.md` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | COMP-01~04 | content | `grep -c "Composed\|Primitive\|Page" .claude/rules/components.md` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 1 | RFMT-01~04 | content | `wc -l CLAUDE.md \| awk '{print $1}'` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.claude/rules/` directory created
- [ ] `CLAUDE.md` root file initialized

*Existing infrastructure covers remaining phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Token names match shadcn/ui convention | TOKN-01~05 | Requires human judgment on naming consistency | Compare variable names against shadcn/ui docs |
| Component interfaces are clear to AI | COMP-04 | Subjective clarity assessment | Read interface and assess if AI could implement from it alone |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
