---
type: normal
page: campaign-form
template: PAGE-03
expected_violations: 0
expected_ui:
  - card
  - button
  - input
  - textarea
  - select
  - field
expected_composed: []
expected_lib: []
---

# Campaign Form 페이지 생성

아래 요구사항에 맞는 캠페인 생성/편집 폼 페이지를 작성하세요.
프로젝트의 `.claude/rules/` 디렉토리에 있는 모든 규칙을 준수해야 합니다.

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
- Start Date / End Date (Input date, 2-column grid)

### CardFooter
- Cancel (outline) + Save (submit)
- form id 연결

### 기타
- react-hook-form + Controller 패턴 사용
- FieldError 표시
- 로케일: en-US

## 출력
- 파일 위치: `preview/src/pages/campaign-form.normal.tsx`
- 필요한 shadcn 컴포넌트를 직접 설치하세요 (`npx shadcn add ...`)
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
