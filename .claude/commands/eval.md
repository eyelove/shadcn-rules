---
description: "Run eval scenario — validate AI-generated pages against shadcn-rules (A/B test)"
---

# /eval — Rule Evaluation Runner (A/B Test)

shadcn-rules 규칙의 효과를 A/B 테스트로 평가합니다.
동일한 프롬프트로 **규칙 적용(A)**과 **규칙 미적용(B)**을 비교하여, 규칙이 코드 품질을 개선하는지 측정합니다.

## Arguments

- 인자 없음: 전체 프롬프트 평가
- 페이지명 (예: `$ARGUMENTS`): 해당 페이지만 평가

## Instructions

### Step 1: preview 초기화

```bash
bash scripts/reset-preview.sh
```

이 스크립트가:
- AI 생성물 삭제 (components/composed, lib, hooks, pages)
- `npx shadcn init` 실행 (CSS 토큰 + components.json + utils 자동 생성)
- 프로젝트 커스텀 토큰 주입 (kpi-*, table-row-hover — chart 토큰은 shadcn이 기본 제공)
- eval에 필요한 모든 shadcn 컴포넌트 설치 (card, badge, input, textarea, select, field, chart, separator)
- shadcn 원본 checksum 저장 (ENV-04용)

### Step 2: 페이지 생성 (A/B 서브에이전트)

`tests/prompts/` 디렉토리에서 프롬프트를 수집하세요.
인자가 있으면 해당 페이지의 프롬프트만 필터링합니다.

**각 프롬프트마다 2개의 서브에이전트를 디스패치합니다.**

#### Arm A — with_rules (규칙 적용)

서브에이전트에게 전달할 내용:
1. `.claude/rules/` 디렉토리의 모든 규칙 파일 경로 (CLAUDE.md가 import하는 9개 파일)
2. 해당 프롬프트 파일의 전체 내용
3. 작업 디렉토리: `preview/`
4. 지시: "규칙을 모두 읽고, 프롬프트의 요구사항대로 페이지를 생성하세요. shadcn 컴포넌트는 이미 설치되어 있습니다. Composed 컴포넌트와 유틸리티가 필요하면 생성하세요."
5. 출력 파일: `preview/src/pages/{page}.with_rules.tsx`

#### Arm B — without_rules (규칙 미적용)

서브에이전트에게 전달할 내용:
1. 해당 프롬프트 파일의 전체 내용 (**규칙 파일 없음**)
2. 작업 디렉토리: `preview/`
3. 지시: "프롬프트의 요구사항대로 React 대시보드 페이지를 생성하세요. shadcn/ui와 Tailwind CSS를 사용하세요. shadcn 컴포넌트는 이미 설치되어 있습니다. 필요한 컴포넌트와 유틸리티는 자유롭게 생성하세요."
4. 출력 파일: `preview/src/pages/{page}.without_rules.tsx`

**중요:**
- 두 서브에이전트 모두 fresh context에서 실행
- Arm A는 규칙 파일을 받고, Arm B는 받지 않음 — 이것이 유일한 차이
- 동일 프롬프트의 A/B는 병렬로 디스패치 가능

### Step 3: 검증 + 스냅샷

```bash
bash scripts/run-eval.sh --check-only $ARGUMENTS
```

이 스크립트가:
- `preview/src/pages/{page}.with_rules.tsx`와 `{page}.without_rules.tsx` 모두 검증
- `tsc -b` 빌드 검증
- `check-rules.sh` grep + ENV 검증 (ENV 검사는 with_rules에만 적용)
- `score-report.sh` A/B 비교 리포트 생성
- `save-snapshot.sh` 스냅샷 저장

### Step 4: 결과 해석 및 안내

스냅샷의 report.md를 읽고 사용자에게 다음을 안내하세요:

1. **A/B Comparison 테이블 해석:**
   - `EFFECTIVE` (delta ≥ 20%): 규칙이 명확히 효과적
   - `MARGINAL` (delta 5-19%): 규칙 효과 있으나 미미 — 규칙 보강 검토
   - `NO DIFF` (delta < 5%): 규칙 효과 없음 — 프롬프트가 너무 단순하거나 규칙이 불명확
   - `NEGATIVE` (delta < 0): 규칙이 오히려 해침 — 규칙 재검토 필요

2. **with_rules arm에 failure가 있는 경우:**
   - 어떤 규칙이 위반됐는지 설명
   - 해당 `.claude/rules/*.md` 파일의 어떤 부분이 불명확한지 분석
   - 구체적인 규칙 보강 방안 제안

3. **둘 다 100% && delta ≥ 20%인 경우:**
   - "규칙이 효과적으로 동작" 확인

4. **브라우저 확인 안내:**
   ```
   브라우저에서 결과를 확인하려면:
     ! bash scripts/open-viewer.sh && cd preview && pnpm dev
   ```
