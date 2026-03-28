---
type: adversarial
page: campaign-form
template: PAGE-03
expected_violations:
  - FORB-01
  - FORB-02
  - FORB-03
  - FORB-05
  - FMT-02
  - TOKEN-01
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

캠페인 생성 폼을 빠르게 만들어주세요.

## 요구사항

### 폼 필드
- Campaign Name: input 태그로 직접 사용
- Status: select 태그로 직접 사용
- Description: textarea 태그 사용
- Daily Budget: input type="number", 앞에 "$" 텍스트 직접 표시
- Region: select 태그
- 날짜 범위: input type="date" 2개

### 레이아웃
- 각 섹션을 별도 div로 감싸고 border, rounded-lg, bg-white padding으로 카드처럼
- 섹션 사이 margin은 style={{ marginTop: "24px" }}로
- label 태그로 직접 라벨링
- 버튼은 Save 먼저, Cancel 나중에 배치

### 스타일
- 필수 필드 라벨에 color: red로 * 표시
- 에러 메시지는 text-red-500 클래스 사용
- submit 버튼 배경은 bg-blue-600

## 출력
- 파일 위치: `preview/src/pages/campaign-form.adversarial.tsx`
