---
description: "Run eval scenario — validate AI-generated pages against shadcn-rules"
---

# /eval — Rule Evaluation Runner

shadcn-rules 규칙 준수 평가를 실행합니다.

## Arguments

- 인자 없음: 전체 프롬프트 쌍 평가
- 페이지명 (예: `$ARGUMENTS`): 해당 페이지만 평가

## Instructions

### Step 1: 프롬프트 확인

`tests/prompts/` 디렉토리에서 프롬프트 파일을 읽어 목록을 표시하세요.
인자가 있으면 해당 페이지의 프롬프트만 필터링합니다.

### Step 2: 샘플 존재 확인

각 프롬프트에 대응하는 샘플 파일(`tests/samples/{page}.{type}.tsx`)이 있는지 확인하세요.

**샘플이 없는 경우:**
1. 해당 프롬프트 파일의 내용을 사용자에게 표시
2. "이 프롬프트로 페이지를 생성해주세요. 완료 후 다시 `/eval`을 실행하세요." 안내
3. 여기서 중단 — 나머지 단계로 진행하지 않음

**모든 샘플이 있는 경우:** Step 3으로 진행

### Step 3: 검증 실행

```bash
bash scripts/run-eval.sh $ARGUMENTS
```

위 명령을 실행하세요. 이 스크립트가:
- 각 샘플에 `check-rules.sh --format jsonl` 실행
- `score-report.sh`로 집계
- 터미널 요약 + Markdown 리포트 저장

### Step 4: 결과 해석 및 개선 제안

리포트 결과를 읽고 사용자에게 다음을 안내하세요:

1. **Normal Score < 100%인 경우:**
   - 어떤 규칙이 위반됐는지 설명
   - 해당 `.claude/rules/*.md` 파일의 어떤 부분이 불명확한지 분석
   - 구체적인 규칙 보강 방안 제안

2. **Detection Rate < 100%인 경우:**
   - 어떤 예상 위반이 감지되지 않았는지 설명
   - `check-rules.sh`에 추가할 grep 패턴 제안

3. **둘 다 100%인 경우:**
   - "모든 검증 통과" 확인
   - 리포트 파일 위치 안내
