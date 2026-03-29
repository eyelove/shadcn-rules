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
  - switch
  - radio-group
  - combobox
expected_composed: []
expected_lib:
  - formatDate
---

# 캠페인 생성 폼 페이지

마케팅팀에서 새 캠페인을 등록할 때 사용하는 폼 페이지입니다.
캠페인 기본 정보부터 예산, 타겟팅, 일정까지 한 화면에서 입력해야 합니다.
입력 필드가 많으므로 FieldSet으로 섹션을 나누어 구조화하세요.

## 요구사항

### 페이지 헤더
- Back 버튼 (캠페인 목록 `/campaigns`으로 이동)
- 제목: "캠페인 생성"

### 폼 구조 (단일 Card, react-hook-form + Controller)

#### Section 1 — 기본 정보 (FieldSet, FieldLegend: "기본 정보")
| 필드 | 타입 | 설명 |
|------|------|------|
| 캠페인명 | Input (required) | placeholder: "캠페인명을 입력하세요" |
| 광고주 | Combobox | 광고주 목록에서 검색 선택 (30개 이상 목 데이터, 타이핑 즉시 필터링) |
| 설명 | Textarea (optional) | placeholder: "캠페인 설명 (선택사항)" |

#### Section 2 — 캠페인 설정 (FieldSet, FieldLegend: "캠페인 설정")
| 필드 | 타입 | 설명 |
|------|------|------|
| 캠페인 목표 | RadioGroup | 브랜드 인지도, 전환, 트래픽 (3개 옵션) |
| 캠페인 유형 | Choice Card (RadioGroup + Field) | 검색 광고 / 디스플레이 광고 / 동영상 광고 (각각 제목+설명 포함) |
| 채널 | Select | Google Ads, Meta Ads, Naver SA, Kakao Moment |
| 자동 최적화 | Switch | "성과에 따라 입찰가를 자동으로 조정합니다" |

#### Section 3 — 예산 & 일정 (FieldSet, FieldLegend: "예산 & 일정")
| 필드 | 타입 | 설명 |
|------|------|------|
| 일일 예산 | Input (number, required) | FieldDescription: "일일 최대 지출 금액 (원)" |
| 시작일 | DatePicker (Popover + Calendar) | 2-column grid의 왼쪽 |
| 종료일 | DatePicker (Popover + Calendar) | 2-column grid의 오른쪽 |

- 시작일/종료일은 `grid grid-cols-1 gap-4 sm:grid-cols-2`로 배치
- 날짜 표시는 formatDate 사용 (date-fns 직접 사용 금지)

### CardFooter
- 취소 (variant="outline", type="button") + 저장 (type="submit")
- form id 연결 (`form="campaign-form"`)
- CardFooter에 `className="gap-2"`

### Validation (react-hook-form)
- 캠페인명: required ("캠페인명은 필수입니다")
- 일일 예산: required ("예산은 필수입니다"), min 1000 ("최소 1,000원 이상")
- Controller로 각 필드 연결, FieldError로 에러 표시
- data-invalid on Field, aria-invalid on Input

### 기타
- 로케일: ko-KR
- 날짜 포맷: YYYY-MM-DD (기본값)

## 출력
- `@/lib/format` 유틸리티가 없으면 `preview/src/lib/format.ts`에 생성하세요
- App.tsx에 라우팅을 연결하세요
- 단일 페이지 컴포넌트, 목 데이터 인라인
