# Rules Compaction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 규칙 파일 2,601줄 → ~720줄로 압축. 동작 유지, 컨텍스트 72% 감소.

**Architecture:** 각 규칙을 "규칙 문장 + CORRECT/FORBIDDEN 한 쌍 + // WHY"로 압축. `@` 참조 유지. Props interface, 함수 시그니처, 의사결정 트리 등 AI가 추론 불가한 항목은 보존.

**Tech Stack:** Claude Code rules, bash (check-rules.sh), eval system

---

## 롤백 전략

```bash
# 이미 태그됨: rules-v1-before-compaction
# 롤백 시:
git checkout rules-v1-before-compaction -- .claude/ CLAUDE.md
```

---

## Task 1: CLAUDE.md 압축

**Files:** Modify: `CLAUDE.md`

현재 107줄 → ~50줄. 설명 텍스트 압축, `@` 참조 9개 유지.

- [ ] Step 1: CLAUDE.md 재작성 — 프로젝트 설명/eval 섹션 압축, Always Apply 유지, `@` 참조 유지
- [ ] Step 2: `wc -l CLAUDE.md` 확인 (목표 ~50줄)
- [ ] Step 3: Commit

## Task 2: forbidden.md 압축

**Files:** Modify: `.claude/rules/forbidden.md`

현재 216줄 → ~70줄. 6가지 FORB 항목을 규칙+한쌍+WHY로.

- [ ] Step 1: 재작성 — frontmatter 유지, 각 FORB를 규칙문장+한쌍+WHY로 압축
- [ ] Step 2: `wc -l` 확인 (목표 ~70줄)
- [ ] Step 3: Commit

## Task 3: tokens.md 압축

**Files:** Modify: `.claude/rules/tokens.md`

현재 166줄 → ~70줄. Color/Radius/Typography/Spacing 테이블 유지, 예제 코드 삭제.

- [ ] Step 1: 재작성 — 테이블 유지, FORBIDDEN/CORRECT 예제 코드 블록 삭제, spacing 고정값 테이블 유지
- [ ] Step 2: `wc -l` 확인 (목표 ~70줄)
- [ ] Step 3: Commit

## Task 4: cards.md 압축

**Files:** Modify: `.claude/rules/cards.md`

현재 441줄 → ~100줄. CARD-01~05 각각 구조 규칙+한쌍+WHY로.

삭제: Date Range Picker 전체 코드, CARD-03a~d 전체 코드, Column Layout(page-templates.md에 있음), Forbidden(forbidden.md에 있음)
유지: chartConfig 정의, CardAction 배치 규칙, ChartContainer min-h 필수, axis stroke 금지

- [ ] Step 1: 재작성
- [ ] Step 2: `wc -l` 확인 (목표 ~100줄)
- [ ] Step 3: Commit

## Task 5: fields.md 압축

**Files:** Modify: `.claude/rules/fields.md`

현재 488줄 → ~90줄.

삭제: FIELD-01~03/05~09 전체 코드, Forbidden(forbidden.md), Exception(cards.md CARD-03b)
유지: Field 계층도, Common Imports, FIELD-04 Controller 최소 예제(10줄), CardFooter 버튼 규칙

- [ ] Step 1: 재작성
- [ ] Step 2: `wc -l` 확인 (목표 ~90줄)
- [ ] Step 3: Commit

## Task 6: data-table.md 압축

**Files:** Modify: `.claude/rules/data-table.md`

현재 356줄 → ~80줄.

삭제: TABLE-05 전체 컬럼 예제(~100줄), TABLE-04(cards.md 참조), TABLE-06 Forbidden
유지: TABLE-00 플로우차트, TABLE-01 Props Interface, TABLE-02 컬럼 순서 테이블, TABLE-03 기능 테이블

- [ ] Step 1: 재작성
- [ ] Step 2: `wc -l` 확인 (목표 ~80줄)
- [ ] Step 3: Commit

## Task 7: components.md 압축

**Files:** Modify: `.claude/rules/components.md`

현재 266줄 → ~80줄.

삭제: Composed Qualification 코드 예제, Chart Library Usage(cards.md), Cell Functions(data-table.md)
유지: 2-tier 테이블, Import 목록, Composed Qualification 기준 3가지(문장만), SELECT-01/DATE-01/RADIO-01 의사결정 트리, SearchBar Props Interface

- [ ] Step 1: 재작성
- [ ] Step 2: `wc -l` 확인 (목표 ~80줄)
- [ ] Step 3: Commit

## Task 8: page-templates.md 압축

**Files:** Modify: `.claude/rules/page-templates.md`

현재 259줄 → ~60줄.

삭제: PAGE-01~04 전체 코드 블록, Cross-References
유지: Page Structure Rules 테이블, 각 PAGE 구조 규칙(2~3줄), Column Layout Reference, FORBIDDEN/DEFAULT 주석

- [ ] Step 1: 재작성
- [ ] Step 2: `wc -l` 확인 (목표 ~60줄)
- [ ] Step 3: Commit

## Task 9: formatting.md 압축

**Files:** Modify: `.claude/rules/formatting.md`

현재 210줄 → ~70줄.

삭제: 각 함수 상세 예시 출력값, FMT-01~04 코드 예제(규칙 문장으로), ko-KR 변환표
유지: ko-KR/en-US Rules 테이블, Function Signatures, Context Application 테이블

- [ ] Step 1: 재작성
- [ ] Step 2: `wc -l` 확인 (목표 ~70줄)
- [ ] Step 3: Commit

## Task 10: naming.md 압축

**Files:** Modify: `.claude/rules/naming.md`

현재 92줄 → ~50줄.

삭제: NAME-03 CSS Variable(tokens.md에 있음), Escape Hatch 장문
유지: NAME-01 파일 네이밍 테이블, NAME-02 컴포넌트 네이밍 + barrel export, Directory Structure

- [ ] Step 1: 재작성
- [ ] Step 2: `wc -l` 확인 (목표 ~50줄)
- [ ] Step 3: Commit

## Task 11: Eval 검증

- [ ] Step 1: 전체 줄 수 집계 `wc -l CLAUDE.md .claude/rules/*.md`
- [ ] Step 2: `/eval` 실행
- [ ] Step 3: run9 대비 arm_a 점수 비교
- [ ] Step 4: 퇴보 시 롤백 `git checkout rules-v1-before-compaction -- .claude/ CLAUDE.md`
