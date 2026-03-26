# Requirements: shadcn-rules

**Defined:** 2026-03-26
**Core Value:** AI가 규칙만 보고 대시보드 페이지를 만들면, 누가 언제 만들든 시각적으로 일관되고 코드상 위반이 없는 결과가 나와야 한다.

## v1 Requirements

### Component Rules (COMP)

- [x] **COMP-01**: 3계층 컴포넌트 분리 규칙 정의 — Primitive(shadcn/ui 원본), Composed(프로젝트 래퍼), Page(골격 템플릿)
- [x] **COMP-02**: AI가 사용 가능한 컴포넌트 목록(Composed 계층만) 명시
- [x] **COMP-03**: AI가 직접 import 금지인 컴포넌트 목록(Primitive 계층) 명시
- [x] **COMP-04**: 핵심 Composed 컴포넌트의 인터페이스 계약(props, 사용 예시) 정의

### Forbidden Patterns (FORB)

- [x] **FORB-01**: inline style 사용 금지 규칙 (`style={{}}` 금지)
- [x] **FORB-02**: 하드코딩 컬러 금지 규칙 (hex/rgb 직접 사용 금지, CSS 변수만 허용)
- [x] **FORB-03**: div/span 직접 레이아웃 금지 규칙 (Composed 컴포넌트로 대체)
- [x] **FORB-04**: shadcn 원본 직접 import 금지 규칙 (래퍼 컴포넌트 사용 강제)
- [x] **FORB-05**: FormField 없이 Input 직접 사용 금지 규칙

### Design Tokens (TOKN)

- [x] **TOKN-01**: 색상 체계 토큰 규칙 (Background, Text, Border, Brand, Chart 카테고리)
- [x] **TOKN-02**: 타이포그래피 토큰 규칙 (font-family, size 체계, weight 용도별)
- [x] **TOKN-03**: 간격 토큰 규칙 (컴포넌트 내부 padding, 컴포넌트 간 gap, 섹션 간 gap)
- [x] **TOKN-04**: 기타 토큰 규칙 (border-radius, shadow, transition)
- [x] **TOKN-05**: 토큰은 짧고 명확하게 — 다단계 체인 금지, CSS 변수 직접 참조

### Form Rules (FORM)

- [x] **FORM-01**: 폼 구조 강제 규칙 — Card > FormFieldSet > FormRow/FormField > Input
- [x] **FORM-02**: FormActions 위치 및 구성 규칙 (취소=outline, 저장=primary)
- [x] **FORM-03**: 폼 금지 패턴 예시 (div 직접 레이아웃, Input 직접 사용, inline style 간격)

### Page Templates (PAGE)

- [x] **PAGE-01**: 목록 페이지 골격 — PageHeader → SearchBar → KpiCardGroup → ChartSection → DataTable
- [x] **PAGE-02**: 상세 페이지 골격 — PageHeader(뒤로가기) → TabGroup → (탭별 콘텐츠)
- [x] **PAGE-03**: 설정 페이지 골격 — PageHeader → Card > FormFieldSet 반복 > FormActions
- [x] **PAGE-04**: 대시보드 페이지 골격 — PageHeader → KpiCardGroup → ChartSection(2열) → DataTable

### Naming Conventions (NAME)

- [x] **NAME-01**: 파일명 규칙 (컴포넌트 PascalCase, 페이지 kebab-case 등)
- [x] **NAME-02**: 컴포넌트명 규칙 (Composed는 접두사/접미사 컨벤션)
- [x] **NAME-03**: CSS 클래스명/변수명 규칙

### Rule Format (RFMT)

- [x] **RFMT-01**: 규칙 파일별 토큰 예산 가이드 (~120줄/1,500토큰 이내)
- [x] **RFMT-02**: 모듈화 전략 — CLAUDE.md(루트) + .claude/rules/*.md(경로별 스코프)
- [x] **RFMT-03**: 모든 핵심 규칙에 "WHY" 근거 주석 포함
- [x] **RFMT-04**: 합법적 예외 경로 문서화 (escape hatch)

### Verification (VERF)

- [x] **VERF-01**: grep 기반 자동 위반 감지 스크립트 (check.sh)
- [x] **VERF-02**: 페이지 타입별 샘플 페이지 생성 (목록/상세/설정/대시보드 각 1개)
- [x] **VERF-03**: 구조화된 평가 체크리스트 (규칙 → 기대 결과 → 실제 결과 → 판정)
- [x] **VERF-04**: 반복 개선 루프 프로세스 문서화 (규칙 → 생성 → 평가 → 수정 사이클)
- [x] **VERF-05**: 평가는 반드시 새로운 컨텍스트 윈도우에서 수행 (자기 평가 금지)

## v2 Requirements

### Extended Rules

- **EXT-01**: 접근성 기본 규칙 (ARIA, 키보드 네비게이션)
- **EXT-02**: 스코프별 규칙 활성화 (파일 타입에 따라 다른 규칙 적용)
- **EXT-03**: 다크모드 전환 규칙 (선택적 확장)

### Tooling

- **TOOL-01**: ESLint 커스텀 룰 (AST 기반 구조 위반 감지)
- **TOOL-02**: AGENTS.md 크로스 툴 호환 규칙 (Cursor, Copilot 등)
- **TOOL-03**: Composed 컴포넌트 스텁 코드 생성

## Out of Scope

| Feature | Reason |
|---------|--------|
| 실제 프로덕션 대시보드 구현 | 규칙 문서가 목표, 실제 앱 아님 |
| npm 패키지 배포 | 개인 사용 목적 — 배포 오버헤드 불필요 |
| 범용 웹앱 규칙 | 대시보드 특화가 실효성을 높임 |
| Visual regression 스크린샷 비교 | 브라우저 실행, 베이스라인 관리 등 과도한 인프라 — 체크리스트로 충분 |
| Figma 토큰 동기화 | 코드 온리 워크플로우 — Figma 의존성 불필요 |
| 실시간 AI 생성 중 검증 | 복잡도 과다 — 생성 후 평가가 적절한 수준 |
| 특정 디자인 방향 고정 | 프로젝트별 디자인 방향 상이 — 구조/패턴에 집중 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| COMP-01 | Phase 1 | Complete |
| COMP-02 | Phase 1 | Complete |
| COMP-03 | Phase 1 | Complete |
| COMP-04 | Phase 1 | Complete |
| TOKN-01 | Phase 1 | Complete |
| TOKN-02 | Phase 1 | Complete |
| TOKN-03 | Phase 1 | Complete |
| TOKN-04 | Phase 1 | Complete |
| TOKN-05 | Phase 1 | Complete |
| RFMT-01 | Phase 1 | Complete |
| RFMT-02 | Phase 1 | Complete |
| RFMT-03 | Phase 1 | Complete |
| RFMT-04 | Phase 1 | Complete |
| FORB-01 | Phase 2 | Complete |
| FORB-02 | Phase 2 | Complete |
| FORB-03 | Phase 2 | Complete |
| FORB-04 | Phase 2 | Complete |
| FORB-05 | Phase 2 | Complete |
| FORM-01 | Phase 2 | Complete |
| FORM-02 | Phase 2 | Complete |
| FORM-03 | Phase 2 | Complete |
| NAME-01 | Phase 2 | Complete |
| NAME-02 | Phase 2 | Complete |
| NAME-03 | Phase 2 | Complete |
| PAGE-01 | Phase 3 | Complete |
| PAGE-02 | Phase 3 | Complete |
| PAGE-03 | Phase 3 | Complete |
| PAGE-04 | Phase 3 | Complete |
| VERF-01 | Phase 4 | Complete |
| VERF-02 | Phase 4 | Complete |
| VERF-03 | Phase 4 | Complete |
| VERF-04 | Phase 4 | Complete |
| VERF-05 | Phase 4 | Complete |

**Coverage:**
- v1 requirements: 33 total
- Mapped to phases: 33
- Unmapped: 0

---
*Requirements defined: 2026-03-26*
*Last updated: 2026-03-26 after roadmap creation*
