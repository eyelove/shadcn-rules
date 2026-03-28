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

### Step 1: eval 실행

```bash
bash scripts/run-eval.sh $ARGUMENTS
```

이 스크립트가 전체 파이프라인을 실행합니다:
1. preview 초기화 (reset-preview.sh)
2. headless A/B 페이지 생성 (claude -p)
3. 규칙 검증 (check-rules.sh) + 빌드 체크 (tsc -b)
4. A/B 비교 리포트 생성 (score-report.sh)
5. snapshot 저장 (save-snapshot.sh)

### Step 2: 결과 해석 및 안내

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
