# shadcn-rules

## What This Is

AI가 shadcn/ui 기반 사내 대시보드를 만들 때 일관된 디자인과 코드 구조를 생성하도록 강제하는 규칙 문서 세트. 규칙 문서(CLAUDE.md, rules 파일)를 산출물로 하며, 샘플 페이지 생성과 자동 체크를 통해 규칙의 실효성을 검증하는 시스템을 포함한다.

## Core Value

AI가 규칙만 보고 대시보드 페이지를 만들면, 누가 언제 만들든 시각적으로 일관되고 코드상 위반이 없는 결과가 나와야 한다.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] shadcn/ui 기반 대시보드에서 AI의 컴포넌트 사용 규칙 정의
- [ ] 3계층 컴포넌트 분리 규칙 (Primitive → Composed → Page)
- [ ] 금지 패턴 명세 (inline style, 하드코딩 컬러, div 직접 레이아웃 등)
- [ ] 허용 패턴 명세 (Composed 컴포넌트만 사용, 디자인 토큰만 사용 등)
- [ ] 폼 일관성 규칙 (FormFieldSet → FormField → Input 구조 강제)
- [ ] 페이지 타입별 골격 템플릿 규칙 (목록/상세/설정/대시보드)
- [ ] 디자인 토큰 사용 규칙 (색상, 타이포그래피, 간격, 반경 등)
- [ ] 규칙 위반 자동 감지 체크리스트/스크립트
- [ ] 샘플 페이지를 통한 규칙 실효성 시각적 검증
- [ ] 반복 개선 루프 (규칙 적용 → 샘플 생성 → 평가 → 규칙 수정)

### Out of Scope

- 실제 프로덕션 대시보드 구현 — 이 프로젝트는 규칙 문서가 목표
- npm 패키지/라이브러리 배포 — 개인 사용 목적
- 범용 웹앱 규칙 — 대시보드 도메인에 특화
- 특정 디자인 방향 고정 (Linear 등) — 디자인 방향은 프로젝트별로 달라질 수 있으므로 규칙은 구조와 패턴에 집중

## Context

- AI 코딩 도구로 React 대시보드를 만들 때 반복되는 문제 경험:
  - 컴포넌트 라이브러리가 있어도 inline style, 직접 HTML 태그 사용
  - 같은 지시를 해도 매번 다른 구조와 디자인
  - 스크린샷/참조를 줘도 느낌이 미묘하게 다름
- 근본 원인: AI는 "시스템"이 아니라 "페이지"를 만든다 — 매 프롬프트마다 디자인 결정을 새로 내림
- 해결 전략: "하지 마" 보다 "이것만 써"로 컴포넌트 수준에서 강제
- shadcn/ui를 Primitive 계층으로 사용하고, 프로젝트 래퍼(Composed)만 AI가 접근하도록 설계
- 아이디어 문서에 상세한 프롬프트 예시와 컴포넌트 목록이 이미 정리되어 있음

## Constraints

- **Tech stack**: shadcn/ui + Tailwind CSS + React + TypeScript 기반
- **산출물 형태**: CLAUDE.md 및 rules 문서 파일 (코드가 아닌 규칙 문서)
- **검증 방식**: 자동 체크(규칙 위반 감지) + 시각적 확인(디자인 스킬로 샘플 페이지 생성)
- **사용 범위**: 개인 사용 — 내 프로젝트에서 AI에게 일관된 대시보드 UI 생성을 강제

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 규칙 문서 중심 산출물 (코드 패키지 X) | 실제 구현은 프로젝트별로 다르므로, 규칙/가이드라인이 더 범용적 | — Pending |
| 대시보드 도메인 특화 | 범용보다 특화가 규칙의 실효성을 높임 | — Pending |
| 디자인 방향 미고정 | 프로젝트마다 디자인 방향이 다를 수 있으므로 구조/패턴 규칙에 집중 | — Pending |
| 3계층 컴포넌트 분리 | AI가 Composed만 사용하게 하면 구조적 일관성 확보 가능 | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-26 after initialization*
