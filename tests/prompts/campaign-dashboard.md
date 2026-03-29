---
page: campaign-dashboard
template: PAGE-04
expected_ui:
  - card
  - button
  - badge
  - select
  - chart
expected_composed:
  - DataTable
  - KpiCard
expected_lib:
  - formatCurrencyCompact
  - formatCompact
  - formatDelta
  - formatCurrency
  - formatNumber
  - formatPercent
---

# 캠페인 대시보드 페이지 생성

광고 운영팀이 매일 아침 전체 캠페인 성과를 한눈에 확인하는 대시보드가 필요합니다.
팀장이 주간 회의에서 이 화면을 프로젝터로 띄워 현황을 공유하므로, KPI 수치가 크고 명확하게 보여야 합니다.

## 요구사항

### 페이지 헤더
- 제목: "캠페인 대시보드"
- 설명: "전체 캠페인 성과 현황"
- 우측에 "캠페인 생성" 버튼

### KPI 카드 (4개, 4-column grid)
아래 지표를 KpiCard 컴포넌트로 표시합니다. 값은 compact 포맷(만/억 단위)으로 표시하세요.

| 지표 | 값 (원본) | delta |
|------|----------|-------|
| 총 지출 | 245,800,000원 | +12.5% |
| 노출수 | 18,420,000 | +8.3% |
| 클릭수 | 892,000 | -2.1% |
| 평균 CTR | 4.84% | +0.5% |

- 총 지출과 클릭수는 통화/수량 compact(formatCurrencyCompact, formatCompact)
- CTR은 formatPercent
- delta는 formatDelta

### 차트 (2개, 2-column grid)

#### 일일 지출 추이 (LineChart)
- 최근 30일 데이터 (목 데이터 30건)
- X축: 날짜, Y축: 지출(원)
- CardAction에 기간 Select: "최근 7일", "최근 30일", "최근 90일"
- chartConfig에서 색상 정의, `var(--color-KEY)` 참조
- ChartTooltip + ChartTooltipContent 사용

#### 채널별 지출 비율 (BarChart)
- 채널: Google Ads, Meta Ads, Naver SA, Kakao Moment, X Ads
- 각 채널별 지출 금액
- chartConfig에서 chart-1~5 토큰 색상 사용

### 최근 캠페인 테이블
- CardHeader: "최근 캠페인" + CardDescription "최근 활동이 있는 캠페인"
- DataTable 컬럼:
  - ID (pinned left, sortable)
  - 캠페인명 (pinned left, sortable)
  - 상태 (Badge variant="outline")
  - 채널
  - 노출수 (right-aligned, formatNumber)
  - 클릭수 (right-aligned, formatNumber)
  - CTR (right-aligned, formatPercent)
  - 지출 (right-aligned, formatCurrency)
- 10행 목 데이터
- onRowClick으로 `/campaigns/${row.id}` 이동

### 기타
- 로케일: ko-KR, 통화: KRW
- 모든 숫자는 format 유틸리티 사용 (inline 포맷팅 금지)

## 출력
- Composed 컴포넌트(DataTable, KpiCard)가 없으면 `preview/src/components/composed/`에 생성하세요
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
