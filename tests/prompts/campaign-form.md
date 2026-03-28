---
page: campaign-form
template: PAGE-03
expected_ui:
  - card
  - button
  - input
  - textarea
  - select
  - field
  - popover
  - calendar
expected_composed: []
expected_lib:
  - formatDate
---

# Campaign Form 페이지 생성

아래 요구사항에 맞는 캠페인 생성/편집 폼 페이지를 작성하세요.

## 요구사항

### 페이지 헤더
- Back 버튼 (campaigns 목록으로)
- 제목: "Create Campaign"

### 폼 구조 (단일 Card)
#### Section 1 — Basic Info (FieldSet)
- Campaign Name (Input, required)
- Status (Select: Active, Draft, Paused)
- Description (Textarea, optional)

#### Section 2 — Budget & Targeting (FieldSet)
- Daily Budget (Input number)
- Region (Select: US, EU, APAC)
- Start Date / End Date (Date Picker: Popover + Calendar, 2-column grid)
  - 날짜 표시는 formatDate 사용 (date-fns 직접 사용 금지)

### CardFooter
- Cancel (outline) + Save (submit)
- form id 연결

### 기타
- react-hook-form + Controller 패턴 사용
- FieldError 표시
- 로케일: ko-KR

## 출력
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
