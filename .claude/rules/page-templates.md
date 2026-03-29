---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "pages/**/*.tsx"
  - "resources/js/**/*.tsx"
---

# Page Skeleton Templates

Every page type has a canonical structure. Follow it exactly -- do not invent structure.

## Page Structure Rules

**절대 규칙:**
| Rule | Description |
|------|------------|
| Root wrapper | `div.flex.flex-col.gap-4.p-4` -- all pages |
| Page header | NOT a Card -- `div` with `h1` + `p` + action Button |

**기본값** (특별한 지시 없으면 이대로 생성, 사용자 지시 시 변경 가능):
| Rule | Default | Override example |
|------|---------|-----------------|
| Section order (dashboard) | KPI -> Chart -> Table | "차트를 먼저 배치해줘" |
| Section order (detail) | KPI -> Chart -> Related Table | "테이블만 보여줘" |
| Form page | Back button + single Card | 모달 폼, 위저드 폼 |
| Chart grid (dashboard) | `lg:grid-cols-2` | 단일 차트 full-width, 비대칭 `lg:grid-cols-[2fr_1fr]` |
| List page | Table only, no KPI/Chart | "상단에 요약 KPI 추가해줘" |

## PAGE-01 -- List Page

루트 > 헤더(div) > Table Card(CARD-03b with inline filter). KPI/Chart 없음.

- FORBIDDEN: 헤더를 Card로 감싸기, 필터를 Card 밖에 배치, DataTable을 Card 없이 사용, CardHeader 생략
- DEFAULT: 테이블만 포함 (사용자 요청 시 KPI/Chart 추가 가능)

## PAGE-02 -- Detail Page

루트 > 헤더(Back button + Badge) > KPI Cards(CARD-01) > Chart Cards(CARD-02) > Related Table(CARD-03). 순서 고정.

- FORBIDDEN: 헤더를 Card로 감싸기, 차트에 하드코딩 색상, raw Recharts Tooltip/contentStyle, CartesianGrid/XAxis/YAxis에 stroke 전달
- DEFAULT: 순서 KPI -> Chart -> Table, Back button, Badge in header

## PAGE-03 -- Form / Settings Page

루트 > 헤더(Back button) > 단일 Form Card(CardHeader + CardContent + CardFooter). 위저드/멀티스텝만 복수 Card 허용. 복수 섹션은 FieldSet으로 분리.

- FORBIDDEN: Card 없이 폼 렌더링, Field 밖에 bare Input, submit 버튼의 `form="form-id"` 누락, submit/cancel을 CardContent 안에 배치
- DEFAULT: Back button, 단일 Card, 버튼 순서 보조(outline) -> 주요(default)

## PAGE-04 -- Dashboard Overview Page

루트 > 헤더 > KPI Cards(CARD-01) > Chart Cards(CARD-02, lg:grid-cols-2) > Recent Table(CARD-03).

- FORBIDDEN: 헤더를 Card로 감싸기, 차트에 하드코딩 색상, raw Recharts Tooltip/contentStyle, CartesianGrid/XAxis/YAxis에 stroke 전달, ChartContainer를 Card 없이 사용, ChartContainer에 min-h 누락
- DEFAULT: Chart grid lg:grid-cols-2, 순서 KPI -> Chart -> Table

## Column Layout Reference

| Pattern | Grid Classes | Use |
|---------|-------------|-----|
| KPI 4-col | `grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4` | KPI card grid |
| Chart 2-col | `grid grid-cols-1 gap-4 lg:grid-cols-2` | Chart grid (default) |
| Chart asymmetric | `grid grid-cols-1 gap-4 lg:grid-cols-[2fr_1fr]` | Main + secondary chart |
| Form 2-col fields | `grid grid-cols-1 gap-4 sm:grid-cols-2` | Side-by-side fields in FieldSet |
| Form 1-col | Single Card, full width | Standard form page |
