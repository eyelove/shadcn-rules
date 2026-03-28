---
description: "Run eval scenario — validate AI-generated pages against shadcn-rules"
---

# /eval — Rule Evaluation Runner

shadcn-rules 규칙 준수 평가를 실행합니다.
preview 환경을 초기화하고, 프롬프트 기반으로 페이지를 생성한 뒤, 검증 + 스냅샷 저장까지 수행합니다.

## Arguments

- 인자 없음: 전체 프롬프트 쌍 평가
- 페이지명 (예: `$ARGUMENTS`): 해당 페이지만 평가

## Instructions

### Step 1: preview 초기화

```bash
bash scripts/reset-preview.sh
```

### Step 2: 셋업 프롬프트 실행

`tests/prompts/setup.md`를 읽고 지시대로 수행하세요:
- `tokens/globals.css`의 CSS 커스텀 프로퍼티를 `preview/src/index.css`에 추가
- `preview/components.json` 설정 확인
- **컴포넌트 설치 금지** — 컴포넌트는 Step 3에서 페이지별로 설치

### Step 3: 페이지 생성 (서브에이전트)

`tests/prompts/` 디렉토리에서 페이지 프롬프트를 수집하세요 (`setup.md` 제외).
인자가 있으면 해당 페이지의 프롬프트만 필터링합니다.

**각 프롬프트마다 서브에이전트를 디스패치하여 페이지를 생성합니다.**

서브에이전트에게 전달할 내용:
1. `.claude/rules/` 디렉토리의 모든 규칙 파일 경로 (CLAUDE.md가 import하는 9개 파일)
2. 해당 프롬프트 파일의 전체 내용
3. 작업 디렉토리: `preview/`
4. 지시: "규칙을 모두 읽고, 프롬프트의 요구사항대로 페이지를 생성하세요. 필요한 shadcn 컴포넌트를 직접 설치하고, Composed 컴포넌트와 유틸리티도 필요하면 생성하세요."

**중요:**
- 서브에이전트는 fresh context에서 실행 — 규칙 파일만으로 올바르게 생성하는지 검증하는 것이 목적
- normal과 adversarial 프롬프트 모두 실행
- 같은 페이지의 normal/adversarial이 같은 preview 환경을 공유하므로 shadcn 설치는 한 번만 발생

### Step 4: 검증 + 스냅샷

```bash
bash scripts/run-eval.sh --check-only $ARGUMENTS
```

이 스크립트가:
- `preview/src/pages/` 의 생성된 페이지를 찾아 검증
- `tsc -b` 빌드 검증
- `check-rules.sh` grep + ENV 검증
- `score-report.sh` 리포트 생성
- `save-snapshot.sh` 스냅샷 저장

### Step 5: 결과 해석 및 안내

스냅샷의 report.md를 읽고 사용자에게 다음을 안내하세요:

1. **Normal Score < 100%인 경우:**
   - 어떤 규칙이 위반됐는지 설명
   - 해당 `.claude/rules/*.md` 파일의 어떤 부분이 불명확한지 분석
   - 구체적인 규칙 보강 방안 제안

2. **Detection Rate < 100%인 경우:**
   - 어떤 예상 위반이 감지되지 않았는지 설명
   - `check-rules.sh`에 추가할 grep 패턴 제안

3. **둘 다 100%인 경우:**
   - "모든 검증 통과" 확인

4. **브라우저 확인 안내:**
   ```
   브라우저에서 결과를 확인하려면:
     ! bash scripts/open-viewer.sh && cd preview && pnpm dev
   ```
