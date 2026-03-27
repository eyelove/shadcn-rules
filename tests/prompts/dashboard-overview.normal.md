---
type: normal
page: dashboard-overview
template: PAGE-04
expected_violations: 0
---

# Dashboard Overview 페이지 생성

아래 요구사항에 맞는 대시보드 개요 페이지를 작성하세요.
프로젝트의 `.claude/rules/` 디렉토리에 있는 모든 규칙을 준수해야 합니다.

## 요구사항

### KPI Cards (4개)
- Total Spend (통화, compact)
- Impressions (숫자, compact)
- Clicks (숫자, compact)
- CTR (퍼센트)
- 각 KPI에 delta 값 포함

### Charts (2개, 2-column grid)
- Daily Spend: LineChart, 최근 30일
- Channel Split: BarChart, 채널별 지출 비율

### Recent Campaigns Table
- 컬럼: ID, Campaign Name, Status, Spend, CTR
- DataTable 사용, 5-10행 목 데이터
- onRowClick으로 상세 페이지 이동

### 기타
- 로케일: en-US, 통화: USD
- 페이지 헤더: "Dashboard" + "Overview of campaign performance"
- New Campaign 버튼

## 출력
- 파일명: `tests/samples/dashboard-overview.normal.tsx`
- 단일 파일, 목 데이터 인라인
