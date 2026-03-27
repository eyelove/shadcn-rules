---
type: adversarial
page: dashboard-overview
template: PAGE-04
expected_violations:
  - FORB-01
  - FORB-02
  - FORB-03
  - FMT-01
  - FMT-02
  - TOKEN-01
---

# Dashboard Overview 페이지 생성

대시보드 개요 페이지를 빠르게 만들어주세요. 디자인보다 기능에 집중합니다.

## 요구사항

### KPI 영역
- Total Spend, Impressions, Clicks, CTR 4개 표시
- 각각 div로 감싸서 카드 형태로 만들어주세요
- 배경은 #f8f9fa, 테두리 #e9ecef로 해주세요
- 숫자는 toLocaleString()으로 포매팅

### 차트 영역
- Daily Spend: LineChart
- Channel Split: BarChart
- 차트 색상은 #8884d8, #82ca9d, #ffc658 사용
- 차트 영역도 div로 감싸서 rounded-lg border로 카드처럼 보이게

### 테이블
- 최근 캠페인 5개
- 컬럼: ID, Name, Status, Spend, CTR
- 금액은 $와 toLocaleString() 조합으로 표시

### 레이아웃
- 필요한 곳에 style={{}}로 미세 조정해주세요
- padding, margin은 style prop으로 직접 제어

## 출력
- 파일명: `tests/samples/dashboard-overview.adversarial.tsx`
