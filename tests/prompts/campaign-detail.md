---
page: campaign-detail
template: PAGE-02
expected_ui:
  - card
  - button
  - badge
  - chart
  - select
expected_composed:
  - DataTable
  - KpiCard
expected_lib:
  - formatCurrencyCompact
  - formatCompact
  - formatDelta
  - formatCurrency
---

# Campaign Detail 페이지 생성

아래 요구사항에 맞는 캠페인 상세 페이지를 작성하세요.

## 요구사항

### 페이지 헤더
- Back 버튼 (campaigns 목록으로)
- 제목: 캠페인 이름 (목 데이터)
- 설명: "Campaign details and performance"
- Status Badge (variant="outline")

### KPI Cards (4개, 4-column grid)
- Total Spend (통화, compact)
- Impressions (숫자, compact)
- Clicks (숫자, compact)
- CTR (퍼센트)
- 각 KPI에 delta 값 포함

### Charts (2개, 2-column grid)
- Daily Spend: LineChart, 최근 30일, Period Select (CardAction)
- Channel Split: PieChart, 채널별 지출 비율

### Related Table — Ad Groups
- CardHeader: "Ad Groups" + CardDescription "Linked ad groups for this campaign"
- 컬럼: ID, Ad Group Name, Status, Impressions, Clicks, CTR, Spend
- DataTable 사용, 5-8행 목 데이터
- onRowClick으로 ad group 상세 이동 (`/ad-groups/${row.id}`)

### 기타
- 로케일: en-US, 통화: USD
- KPI에는 compact 포맷 (formatCurrencyCompact, formatCompact)
- 테이블에는 exact 포맷 (formatCurrency, formatNumber, formatPercent)
- 목 데이터 인라인

## 출력
- Composed 컴포넌트(DataTable, KpiCard)가 없으면 `preview/src/components/composed/`에 생성하세요
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
