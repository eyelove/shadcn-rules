---
page: ad-group-form
template: PAGE-03
expected_ui:
  - card
  - button
  - input
  - select
  - field
  - popover
  - calendar
expected_composed: []
expected_lib:
  - formatDate
---

# Ad Group Form 페이지 생성

아래 요구사항에 맞는 광고그룹 생성 폼 페이지를 작성하세요.

## 요구사항

### 페이지 헤더
- Back 버튼 (ad-groups 목록으로)
- 제목: "광고그룹 생성"

### 폼 구조 (단일 Card)
#### Section 1 — 기본 정보 (FieldSet)
- 광고그룹명 (Input, required)
- 캠페인 선택 (Combobox, 캠페인 목록에서 검색 선택)
  - 30개 이상의 캠페인 목록을 목 데이터로 생성
  - 타이핑 즉시 필터링
- 상태 (Select: 활성, 일시중지, 초안)

#### Section 2 — 일정 & 예산 (FieldSet)
- 시작일 (Date Picker: Popover + Calendar mode="single")
- 종료일 (Date Picker: Popover + Calendar mode="single")
  - 시작일/종료일은 2-column grid
  - 날짜 표시는 formatDate 사용 (date-fns 직접 사용 금지)
- 일일 예산 (Input number)
- 자동 최적화 (Switch)

### CardFooter
- 취소 (outline) + 저장 (submit)
- form id 연결

### 기타
- react-hook-form + Controller 패턴 사용
- FieldError 표시
- 로케일: ko-KR
- 날짜 포맷: YYYY-MM-DD (기본값)

## 출력
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
