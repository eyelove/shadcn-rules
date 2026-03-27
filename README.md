# shadcn-rules

AI 코드 생성 에이전트가 **shadcn/ui 기반 대시보드 페이지**를 일관되게 작성하도록 강제하는 규칙 시스템입니다.

## 왜 필요한가?

LLM에게 "대시보드 페이지를 만들어줘"라고 하면 매번 다른 구조, 다른 스타일, 다른 패턴의 코드가 나옵니다. 이 프로젝트는 `.claude/rules/` 디렉토리에 정의된 규칙 파일들을 통해 AI가 생성하는 코드의 **구조적 일관성**을 보장합니다.

## 핵심 개념

### 2-Tier 컴포넌트 모델

| Tier | Import Path | 역할 |
|------|------------|------|
| **shadcn** | `@/components/ui/*` | shadcn/ui 프리미티브 직접 사용 |
| **Composed** | `@/components/composed/` | 도메인 로직이 있는 래퍼 (DataTable, SearchBar, KpiCard만 허용) |

### 규칙 파일 구조

```
.claude/rules/
├── components.md    # 컴포넌트 tier 모델, import 규칙
├── cards.md         # Card 패턴 (KPI, Chart, Table, Form, Mixed)
├── fields.md        # 폼 필드 시스템 (Field, FieldLabel, FieldSet)
├── data-table.md    # DataTable 컬럼 정의, 정렬, 페이지네이션
├── formatting.md    # 숫자/통화/퍼센트 포맷 (ko-KR, en-US)
├── tokens.md        # CSS 커스텀 프로퍼티 토큰 규칙
├── forbidden.md     # 6가지 금지 패턴 (인라인 스타일, 하드코딩 색상 등)
├── naming.md        # 파일/컴포넌트/변수 네이밍 컨벤션
└── page-templates.md # 4가지 페이지 스켈레톤 (List, Detail, Form, Dashboard)
```

### 페이지 타입

| 타입 | 설명 | 섹션 순서 |
|------|------|----------|
| PAGE-01 List | 필터 + 테이블 | Header → Table Card |
| PAGE-02 Detail | 단일 엔티티 상세 | Header → KPI → Chart → Table |
| PAGE-03 Form | 생성/수정 폼 | Header → Form Card |
| PAGE-04 Dashboard | 전체 요약 | Header → KPI → Chart → Table |

## 검증 시스템

### 자동 검증 (check-rules.sh)

```bash
bash scripts/check-rules.sh tests/samples/
```

grep 기반으로 30개 이상의 규칙 위반을 자동 탐지합니다:
- 인라인 스타일 사용
- 하드코딩된 색상값
- Card 없는 대시보드 섹션
- Field 없는 bare Input
- 잘못된 import 경로 등

### 평가 시나리오 (eval)

규칙 파일만 읽은 fresh-context 에이전트가 샘플 페이지를 생성하고, 해당 결과물을 규칙 기준으로 점수를 매기는 시스템입니다.

```bash
# eval 프롬프트 기반 평가 실행
bash scripts/run-eval.sh

# 결과 리포트 생성
bash scripts/score-report.sh tests/reports/*.jsonl
```

### Refinement Loop

```
규칙 작성 → 샘플 생성 → 자동 검증 → 수동 평가 → 규칙 개선 → 재생성
```

자세한 내용은 [docs/refinement-loop.md](docs/refinement-loop.md) 참조.

## 프로젝트 구조

```
shadcn-rules/
├── CLAUDE.md                  # 규칙 허브 (모든 규칙 파일 import)
├── .claude/rules/             # 도메인별 규칙 파일 (9개)
├── .claude/commands/          # 슬래시 커맨드 (/eval)
├── scripts/
│   ├── check-rules.sh         # 자동 규칙 위반 검사
│   ├── run-eval.sh            # eval 오케스트레이터
│   ├── score-report.sh        # JSONL 리포트 집계
│   └── evaluate.md            # 수동 평가 체크리스트
├── tests/
│   ├── samples/               # 생성된 샘플 페이지 (.tsx)
│   ├── prompts/               # eval 프롬프트 쌍
│   └── reports/               # 평가 리포트
├── tokens/
│   └── globals.css            # CSS 커스텀 프로퍼티 토큰 정의
├── docs/                      # 설계 문서, 개선 루프 가이드
├── .planning/                 # 프로젝트 계획 및 요구사항
└── preview/                   # 샘플 미리보기용 Vite 앱
```

## 사용 방법

### Claude Code에서 사용

이 저장소를 작업 디렉토리로 열면 `CLAUDE.md`가 자동으로 로드되어 모든 규칙이 적용됩니다.

```bash
# 이 프로젝트를 clone한 후
cd shadcn-rules

# Claude Code에서 대시보드 페이지 생성 요청
# → 규칙에 따라 일관된 코드가 생성됨
```

### 다른 프로젝트에 적용

`.claude/rules/` 디렉토리와 `CLAUDE.md`를 복사하여 다른 shadcn/ui 프로젝트에 적용할 수 있습니다.

## 라이선스

MIT
