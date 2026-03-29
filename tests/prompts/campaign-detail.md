---
page: campaign-detail
template: PAGE-02
expected_ui:
  - card
  - button
  - badge
  - chart
  - select
  - separator
  - tabs
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
  - formatDate
---

# 캠페인 상세 페이지 생성

캠페인 운영자가 개별 캠페인의 성과를 분석하는 상세 페이지입니다.
상단에서 핵심 KPI를 빠르게 확인하고, 차트로 추이를 분석한 뒤, 하단에서 소속 광고그룹의 세부 성과를 Tabs로 전환하며 볼 수 있어야 합니다.

## 요구사항

### 페이지 헤더
- Back 버튼 (캠페인 목록 `/campaigns`으로 이동)
- 제목: "2026 봄 프로모션" (캠페인명, 목 데이터)
- 설명: "캠페인 상세 성과 분석"
- 우측에 상태 Badge (variant="outline", "활성")

### KPI 카드 (4개, 4-column grid)
아래 지표를 KpiCard로 표시합니다.

| 지표 | 값 (원본) | delta | footerText |
|------|----------|-------|------------|
| 총 지출 | 42,500,000원 | +15.2% | 전월 대비 |
| 노출수 | 3,280,000 | +22.1% | 전월 대비 |
| 클릭수 | 156,000 | -3.4% | 전월 대비 |
| 전환율 | 3.82% | +0.8% | 전월 대비 |

- 통화는 formatCurrencyCompact (만/억원)
- 수량은 formatCompact (만/억)
- delta는 formatDelta

### 캠페인 요약 (Mixed Card — CARD-05)
Card 하나에 캠페인 메타 정보를 요약합니다.

- CardHeader: "캠페인 정보"
- CardContent (space-y-4):
  - 상단 grid (grid-cols-2 gap-4): 상태(Badge), 채널(text), 시작일(formatDate), 종료일(formatDate)
  - Separator
  - 하단: 일일 예산(formatCurrency), 총 예산(formatCurrency), 광고주명(text)

### 차트 (2개, 2-column grid)

#### 일일 성과 추이 (LineChart)
- 최근 30일 데이터 (목 데이터 30건)
- 2개 시리즈: 지출, 전환수
- CardAction에 기간 Select: "최근 7일", "최근 30일", "최근 90일"
- chartConfig에서 색상 정의
- ChartTooltip + ChartTooltipContent, ChartLegend + ChartLegendContent 사용

#### 매체별 성과 비교 (BarChart)
- 채널별 지출/클릭/전환을 Grouped Bar로 표시
- 채널: Google Ads, Meta Ads, Naver SA
- chartConfig에서 chart-1~3 토큰 색상 사용

### 광고그룹 테이블 (Tabs로 상태별 전환)
Card 안에 Tabs를 배치하여 상태별 광고그룹을 전환합니다.

- CardHeader: "광고그룹" + CardDescription "이 캠페인에 속한 광고그룹"
- Tabs: "활성" (기본), "일시정지", "종료"
- 각 Tab의 DataTable 컬럼:
  - ID (pinned left, sortable)
  - 광고그룹명 (pinned left, sortable)
  - 상태 (Badge)
  - 노출수 (right-aligned, formatNumber)
  - 클릭수 (right-aligned, formatNumber)
  - CTR (right-aligned, formatPercent)
  - 지출 (right-aligned, formatCurrency)
  - CPA (right-aligned, formatCurrency)
- 각 탭에 5~8행 목 데이터
- onRowClick으로 `/ad-groups/${row.id}` 이동

### 기타
- 로케일: ko-KR, 통화: KRW
- KPI에는 compact 포맷, 테이블에는 exact 포맷
- 날짜는 formatDate (기본 형식)

## 출력
- Composed 컴포넌트(DataTable, KpiCard)가 없으면 `preview/src/components/composed/`에 생성하세요
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
