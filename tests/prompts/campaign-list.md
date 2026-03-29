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
  - switch
  - combobox
  - popover
  - calendar
expected_composed:
  - DataTable
  - SearchBar
expected_lib:
  - formatNumber
  - formatCurrency
  - formatPercent
  - formatDate
---

# 캠페인 관리 페이지 생성

캠페인 운영팀에서 전체 캠페인을 관리하는 페이지가 필요합니다.
운영팀은 하루에 수십 번 이 페이지를 방문하여 캠페인 상태를 확인하고, 성과가 낮은 캠페인을 일시정지하거나 예산을 조정합니다.
필터링과 정렬이 빠르게 되어야 하고, 목록에서 바로 캠페인 활성/비활성 토글이 가능해야 합니다.

## 요구사항

### 페이지 헤더
- 제목: "캠페인 관리"
- 설명: "전체 캠페인 목록을 관리합니다"
- 우측에 "캠페인 생성" 버튼

### 검색/필터 바 (SearchBar)
Card 안, DataTable 위에 SearchBar 컴포넌트를 배치합니다.
다음 필터를 config로 구성하세요:

| 필터 | 타입 | 설명 |
|------|------|------|
| 검색 | text | 캠페인명으로 검색 (placeholder: "캠페인 검색...") |
| 채널 | combobox | Google Ads, Meta Ads, Naver SA, Kakao Moment, X Ads (placeholder: "채널 선택") |
| 기간 | dateRange | 캠페인 운영 기간 필터 (placeholder: "기간 선택") |
| 상태 | select | 전체, 활성, 일시정지, 종료 (placeholder: "상태") |

### DataTable
- CardHeader: "전체 캠페인" + CardDescription "총 142개 캠페인" + Export 버튼 (CardAction, variant="outline", size="sm")

#### 컬럼 구성
| 순서 | 컬럼 | 설정 |
|------|------|------|
| 1 | 선택 (Checkbox) | pinned left, 전체선택/해제 |
| 2 | ID | pinned left, sortable |
| 3 | 캠페인명 | pinned left, sortable |
| 4 | 상태 | sortable, Badge variant="outline" |
| 5 | 채널 | sortable |
| 6 | 활성 | Switch 토글 (on/off로 캠페인 활성화/비활성화) |
| 7 | 시작일 | sortable, formatDate |
| 8 | 종료일 | sortable, formatDate |
| 9 | 노출수 | sortable, right-aligned, tabular-nums, formatNumber |
| 10 | 클릭수 | sortable, right-aligned, tabular-nums, formatNumber |
| 11 | CTR | sortable, right-aligned, tabular-nums, formatPercent |
| 12 | 지출 | sortable, right-aligned, tabular-nums, font-medium, formatCurrency |
| 13 | 액션 | DropdownMenu: 수정, 복제, 삭제(text-destructive) |

- pageSize: 20
- 20행 목 데이터 (다양한 상태와 채널 혼합)
- onRowClick으로 `/campaigns/${row.id}` 이동
- onSelectionChange로 선택된 캠페인 추적

### 기타
- 로케일: ko-KR, 통화: KRW
- 날짜 포맷: formatDate 사용 (date-fns 직접 사용 금지)
- 모든 숫자는 format 유틸리티 사용

## 출력
- Composed 컴포넌트(DataTable, SearchBar)가 없으면 `preview/src/components/composed/`에 생성하세요
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
