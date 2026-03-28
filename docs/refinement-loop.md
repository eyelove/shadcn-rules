# Rule Refinement Loop

This document describes the repeatable process for improving the rule system based on evaluation findings.

## The Cycle

```
Rules (CLAUDE.md + .claude/rules/*.md)
    │
    ▼
[1] Reset — bash scripts/reset-preview.sh (preview 초기화)
    │
    ▼
[2] Setup — AI가 CSS/테마 설정 (셋업 프롬프트)
    │
    ▼
[3] Generate — AI가 shadcn 설치 + Composed 생성 + 페이지 작성 (페이지 프롬프트)
    │
    ▼
[4] Build — tsc -b (빌드 검증)
    │
    ▼
[5] Check — check-rules.sh (grep + ENV 검증)
    │
    ▼
[6] Report — score-report.sh (report.md + meta.json)
    │
    ▼
[7] Snapshot — save-snapshot.sh (tests/snapshots/{날짜}-run{N}/)
    │
    ▼
[8] Review — preview 비교 뷰어에서 시각적 확인
    │
    ▼
[9] Diagnose — 위반 원인 분류 (규칙 모호? 규칙 누락? AI 오류?)
    │
    ▼
[10] Update — 규칙 파일 수정
    │
    ▼
Back to [1]
```

## Step-by-Step

### Step 1: Reset
- Run `bash scripts/reset-preview.sh` to reset the preview directory to a clean state
- This removes previously generated pages, components, and configuration
- Ensures each eval cycle starts from a known baseline

### Step 2: Setup
- A fresh-context agent reads the setup prompt (`tests/prompts/setup.md`)
- The agent configures CSS tokens, theme variables, and base project settings in the preview directory
- This step is separated from page generation to isolate theme concerns

### Step 3: Generate
- A fresh-context agent reads the rules (CLAUDE.md imports all) and a page prompt from `tests/prompts/*.md`
- The agent installs shadcn components, creates Composed components, and writes page files to `preview/src/pages/`
- **NEVER** generate samples in the same context that will evaluate them (VERF-05)

### Step 4: Build
- Run `tsc -b` to verify TypeScript compilation
- Fix type errors before proceeding — they indicate structural problems

### Step 5: Check (Automated)
```bash
bash scripts/check-rules.sh --prompt tests/prompts/<prompt>.md --preview-dir preview
```
- Runs grep-based pattern checks and ENV validation against generated pages
- Exit code 0 = no mechanical violations
- Exit code N = N violations (see FAIL lines in output)
- Fix mechanical violations first — they are definitive

### Step 6: Report
- Run `bash scripts/score-report.sh` to generate a score summary
- Outputs both `report.md` (human-readable) and `meta.json` (machine-readable)
- Review the report for violation counts and categories

### Step 7: Snapshot
- Run `bash scripts/save-snapshot.sh` to save the current eval results
- Creates a timestamped snapshot directory under `tests/snapshots/{date}-run{N}/`
- Snapshot includes generated samples, report, and metadata

### Step 8: Review
- Run `bash scripts/open-viewer.sh` to switch preview to comparison viewer mode
- Use the snapshot comparison viewer (`preview/src/App.viewer.tsx`) to visually inspect generated pages
- Compare against previous snapshots to track improvement or regression

### Step 9: Diagnose
Classify each violation:

| Violation Type | Symptom | Root Cause |
|----------------|---------|------------|
| Missing rule | AI invented a pattern not in any rule file | Rule gap — no file forbids or requires this |
| Ambiguous rule | AI chose a valid-but-wrong interpretation | Rule wording unclear — tighten the constraint |
| Conflicting rules | Two rule files give contradictory guidance | Consolidation needed — pick one canonical rule |
| AI inference | AI ignored a clear rule | Rule placement — move rule to more prominent position in file |

### Step 10: Update Rules

**Rule file budget:** Each .claude/rules/*.md file must stay under ~120 lines / ~1,500 tokens (RFMT-01).

Before editing:
1. Read the rule file to understand current content
2. Identify which rule ID is affected (e.g., FORB-03, PAGE-04)
3. Edit the specific rule — do NOT rewrite the whole file

Common edits:
- Tighten a rule: Add a specific FORBIDDEN example that matches the violation
- Add a new rule: See "When to Add a Rule" below
- Add cross-reference: Link the rule to the relevant file where more detail lives

After editing, check line count: `wc -l .claude/rules/<file>.md`

---

## When to Add a New Rule

Add a rule when ALL of these are true:
1. **Observable pattern:** The violation appears in at least 2 separate generated samples OR appears repeatedly for the same page type
2. **Not covered:** No existing rule ID explicitly forbids or requires this pattern
3. **Mechanical check possible:** The rule can be verified by grep or by reading the file without executing it
4. **Stable:** The required behavior is unlikely to change as the project evolves

**Do NOT add a rule for:**
- One-off AI errors that were likely random (appeared once, not in second sample)
- Patterns already covered by an existing rule that AI simply ignored (fix rule prominence instead)
- Personal preference — only structural consistency violations qualify

**Process to add:**
1. Determine which rule file the new rule belongs to (forbidden.md, forms.md, etc.)
2. Assign the next available rule ID (e.g., FORB-06)
3. Write the rule with FORBIDDEN example, CORRECT example, and WHY comment
4. Update REQUIREMENTS.md with the new ID
5. Regenerate the failing sample to confirm the new rule fixes the violation

## When to Remove a Rule

Remove a rule when ALL of these are true:
1. **Never violated:** The rule has never been triggered in 3+ evaluation cycles
2. **Redundant:** Another rule already covers the same prohibition
3. **False positives:** The check-rules.sh pattern flags correct code (grep heuristic is wrong)

**Process to remove:**
1. Search check-rules.sh for the corresponding grep check and remove it
2. Remove or merge the rule text in the relevant .claude/rules/*.md file
3. Update REQUIREMENTS.md to mark the rule as deprecated
4. Document the removal reason in a comment

---

## Evaluation Cadence

| Trigger | Action |
|---------|--------|
| New rule file added or modified | Regenerate all 4 samples, full evaluation |
| Single rule clarified (wording only) | Regenerate only the sample(s) that previously violated that rule |
| Structural change (new page type, new component) | Add new checklist section to evaluate.md, generate new sample |
| No violations in 3 consecutive cycles | Rule system is stable — no further action required |

---

## Files Quick Reference

| File | Purpose |
|------|---------|
| CLAUDE.md | Rule hub — imports all rule files |
| .claude/rules/*.md | Domain-scoped rule content |
| scripts/reset-preview.sh | Reset preview to clean state |
| scripts/run-eval.sh | Eval orchestrator (v2, snapshot-based) |
| scripts/check-rules.sh | Automated grep + ENV violation checker |
| scripts/score-report.sh | Terminal summary + markdown/JSON report |
| scripts/save-snapshot.sh | Save eval results as snapshot |
| scripts/open-viewer.sh | Switch preview to comparison viewer mode |
| tests/prompts/setup.md | Setup prompt (CSS/theme only) |
| tests/prompts/*.md | Page generation prompts |
| tests/snapshots/{date}-run{N}/ | Snapshot: samples + report + meta |
| preview/src/App.viewer.tsx | Snapshot comparison viewer |
| docs/refinement-loop.md | This document |
