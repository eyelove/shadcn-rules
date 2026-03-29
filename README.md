# shadcn-rules

AI 코드 생성 에이전트가 **shadcn/ui 기반 대시보드 페이지**를 일관되게 작성하도록 강제하는 규칙 시스템입니다.

## 왜 필요한가?

LLM에게 "대시보드 페이지를 만들어줘"라고 하면 매번 다른 구조, 다른 스타일, 다른 패턴의 코드가 나옵니다.
이 프로젝트는 `.claude/rules/` 디렉토리에 정의된 규칙 파일들을 통해 AI가 생성하는 코드의 **구조적 일관성**을 보장합니다.

## 핵심 개념

### 규칙의 3계층

| 계층 | 설명 | 예시 |
|------|------|------|
| **절대 규칙** | 위반 불가 | inline style 금지, 하드코딩 색상 금지, Card 구조 |
| **기본값** | 특별한 지시 없으면 이대로 생성 | p-4 spacing, chart-1~5, KPI->Chart->Table 순서 |
| **커스텀 허용** | 사용자 지시 시 토큰 시스템 안에서 변경 가능 | 색상 팔레트 확장, spacing 조정 |

### 2-Tier 컴포넌트 모델

| Tier | Import Path | 역할 | 예시 |
|------|------------|------|------|
| **shadcn** | `@/components/ui/*` | shadcn/ui 프리미티브 직접 사용 | Card, Button, Badge, Select, Combobox |
| **Composed** | `@/components/composed/` | 도메인 로직이 있는 래퍼 (3개만 허용) | DataTable, SearchBar, KpiCard |

### Primitive 소스 (shadcn v5 nova preset)

`shadcn init --preset nova`는 Radix + Base UI 하이브리드 구조입니다.

| 컴포넌트 | Primitive | 비고 |
|----------|-----------|------|
| Select, Dialog, Popover, Checkbox, Switch | `radix-ui` | 미선택 값: `undefined` |
| Combobox | `@base-ui/react` | 미선택 값: `null` |
| Calendar | `react-day-picker` | |

### 규칙 파일 구조

```
.claude/rules/
├── components.md      # 컴포넌트 tier 모델, import 규칙, primitive 소스
├── cards.md           # Card 패턴 (KPI, Chart, Table, Form, Mixed)
├── fields.md          # 폼 필드 시스템 (Field, FieldLabel, FieldSet)
├── data-table.md      # DataTable 컬럼 정의, 정렬, 페이지네이션
├── formatting.md      # 숫자/통화/퍼센트/날짜 포맷 (ko-KR, en-US)
├── tokens.md          # CSS 커스텀 프로퍼티 토큰 규칙
├── forbidden.md       # 6가지 금지 패턴 (인라인 스타일, 하드코딩 색상 등)
├── naming.md          # 파일/컴포넌트 네이밍 컨벤션
└── page-templates.md  # 4가지 페이지 스켈레톤 (List, Detail, Form, Dashboard)
```

### 페이지 타입

| 타입 | 설명 | 섹션 순서 |
|------|------|----------|
| PAGE-01 List | 필터 + 테이블 | Header -> Table Card |
| PAGE-02 Detail | 단일 엔티티 상세 | Header -> KPI -> Chart -> Table |
| PAGE-03 Form | 생성/수정 폼 | Header -> Form Card |
| PAGE-04 Dashboard | 전체 요약 | Header -> KPI -> Chart -> Table |

### 포맷 시스템

모든 숫자/통화/날짜 표시는 `@/lib/format` 유틸리티를 사용합니다.

| 컨텍스트 | 함수 | ko-KR | en-US |
|----------|------|-------|-------|
| KPI 값 (통화) | `formatCurrencyCompact` | `1.2만원` | `$12.5K` |
| KPI 값 (수량) | `formatCompact` | `12.5만` | `125K` |
| KPI 델타 | `formatDelta` | `+12.5%` | `+12.5%` |
| 테이블 셀 (통화) | `formatCurrency` | `12,500원` | `$12,500.00` |
| 테이블 셀 (수량) | `formatNumber` | `125,000` | `125,000` |
| 테이블 셀 (비율) | `formatPercent` | `2.74%` | `2.74%` |
| 테이블 셀 (날짜) | `formatDate` | `2026-03-29` | `Mar 29, 2026` |

## 내 프로젝트에 적용하기

> 상세 가이드: [docs/apply-to-project.md](docs/apply-to-project.md)

### 빠른 시작 (3단계)

**1단계 — 규칙 파일 복사**

```bash
# shadcn-rules 저장소에서 내 프로젝트로 복사
cp -r shadcn-rules/.claude/ my-project/.claude/
cp shadcn-rules/CLAUDE.md my-project/CLAUDE.md
```

**2단계 — 템플릿 파일 복사**

```bash
# Composed 컴포넌트 복사
mkdir -p my-project/src/components/composed
cp shadcn-rules/scripts/templates/composed/* my-project/src/components/composed/

# 포맷 유틸리티 복사
mkdir -p my-project/src/lib
cp shadcn-rules/scripts/templates/format.ts my-project/src/lib/format.ts

# 커스텀 토큰 (index.css에 수동 병합)
cat shadcn-rules/scripts/templates/custom-tokens.css
```

**3단계 — CLAUDE.md에서 eval 섹션 제거**

복사한 `CLAUDE.md`에서 `## Eval Preview 환경 주의사항` 섹션을 삭제합니다. eval은 이 저장소 전용 기능입니다.

이후 Claude Code에서 프로젝트를 열면 규칙이 자동 적용됩니다.

## 검증 시스템

### 자동 검증 (check-rules.sh)

```bash
bash scripts/check-rules.sh path/to/pages/
```

grep 기반으로 30개 이상의 규칙 위반을 자동 탐지합니다:
- 인라인 스타일, 하드코딩 색상
- Card 없는 대시보드 섹션
- Field 없는 bare Input
- 잘못된 import 경로 등

### A/B 평가 (eval)

규칙 유무에 따른 코드 품질 차이를 측정하는 A/B 테스트 시스템입니다.

```bash
# A/B 평가 실행 (with_rules vs without_rules)
bash scripts/run-eval.sh

# 결과 뷰어 열기
bash scripts/open-viewer.sh
```

### Refinement Loop

```
규칙 작성 -> 샘플 생성 -> 자동 검증 -> 수동 평가 -> 규칙 개선 -> 재생성
```

자세한 내용은 [docs/refinement-loop.md](docs/refinement-loop.md) 참조.

## 프로젝트 구조

```
shadcn-rules/
├── CLAUDE.md                    # 규칙 허브 (모든 규칙 파일 참조)
├── .claude/
│   ├── rules/                   # 도메인별 규칙 파일 (9개)
│   └── commands/                # 슬래시 커맨드 (/eval)
├── scripts/
│   ├── templates/               # Composed 컴포넌트, 포맷 유틸리티, 커스텀 토큰
│   │   ├── composed/            #   DataTable, SearchBar, KpiCard
│   │   ├── format.ts            #   숫자/통화/날짜 포맷 유틸리티
│   │   ├── custom-tokens.css    #   대시보드 확장 토큰 (KPI, Table)
│   │   └── utils.ts             #   cn() 유틸리티
│   ├── run-eval.sh              # A/B eval 오케스트레이터
│   ├── check-rules.sh           # 자동 규칙 위반 검사
│   ├── score-report.sh          # JSONL 리포트 집계
│   ├── save-snapshot.sh         # 스냅샷 아카이브
│   ├── reset-preview.sh         # preview 환경 초기화
│   └── open-viewer.sh           # A/B 비교 뷰어 실행
├── tests/
│   ├── prompts/                 # eval 프롬프트 (campaign-list, detail, form, dashboard)
│   └── snapshots/               # eval 결과 아카이브
├── preview/                     # eval용 Vite 앱 (자동 생성)
└── docs/                        # 설계 문서
```

## 라이선스

MIT
