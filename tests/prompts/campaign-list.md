---
page: campaign-list
template: PAGE-01
expected_ui:
  - card
  - button
  - badge
  - input
  - select
  - dropdown-menu
  - checkbox
expected_composed:
  - DataTable
expected_lib:
  - formatNumber
  - formatCurrency
  - formatPercent
---

# Campaign List 페이지 생성

아래 요구사항에 맞는 캠페인 목록 페이지를 작성하세요.

## 요구사항

### 페이지 헤더
- 제목: "Campaigns"
- 설명: "Manage your campaigns"
- New Campaign 버튼

### Table Card
- CardHeader: "All Campaigns" + CardDescription "142 campaigns" + Export 버튼 (CardAction)
- 인라인 필터: 이름 검색 Input + Status Select (Active, Paused, Draft)

### DataTable 컬럼
- Checkbox selection (pinned left)
- ID (pinned left, sortable)
- Campaign Name (pinned left, sortable)
- Status (sortable, Badge variant="outline")
- Channel (sortable)
- Impressions (sortable, right-aligned, formatNumber)
- Clicks (sortable, right-aligned, formatNumber)
- CTR (sortable, right-aligned, formatPercent)
- Spend (sortable, right-aligned, formatCurrency)
- Actions (DropdownMenu: Edit, Duplicate, Delete)

### 기타
- 로케일: en-US, 통화: USD
- 10-15행 목 데이터
- onRowClick으로 상세 페이지 이동 (`/campaigns/${row.id}`)
- pageSize: 20

## 출력
- Composed 컴포넌트(DataTable)가 없으면 `preview/src/components/composed/`에 생성하세요
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
