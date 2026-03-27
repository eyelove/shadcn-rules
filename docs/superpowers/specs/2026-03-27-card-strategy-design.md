# Card Strategy & Rule System Redesign

## Overview

shadcn/ui 프리미티브를 직접 사용하는 것을 기본으로 하고, 복합 로직이 있는 도메인 특화 컴포넌트만 Composed로 분리하는 새로운 규칙 체계. Card, Field, DataTable 사용 전략을 중심으로 대시보드 UI 규칙을 재설계한다.

## Goals

1. shadcn Card를 섹션 컨테이너로 사용하여 UI 통일성 유지
2. shadcn Field 시스템으로 폼 구조 표준화
3. DataTable의 컬럼/기능 규칙을 실무 패턴에 맞게 정의
4. 3-tier → 2-tier 모델로 단순화 (shadcn 직접 사용 + 최소 Composed)

## Non-Goals

- shadcn 컴포넌트 자체의 커스터마이징/확장
- 모바일 전용 레이아웃
- 인증/권한 관련 UI 패턴

---

## Section 0: Number & Currency Format Rules

### 원칙

| 원칙 | 설명 |
|------|------|
| 로케일 기반 포맷 | 통화 설정에 따라 표기 방식이 달라진다 |
| KPI는 축약, 테이블은 정확한 수치 | 컨텍스트에 따라 같은 숫자도 다르게 표시 |
| 포맷 함수로 통일 | 인라인 포맷 로직이 아닌 유틸 함수 사용 |

### 로케일별 포맷 규칙

**ko-KR (한국어)**

| 항목 | 규칙 | 예시 |
|------|------|------|
| 통화 표기 | 숫자 + "원" 후치 (₩ 기호 사용 안 함) | `12,500원` |
| 소수점 | 원 단위 절사, 소수점 없음 | `12,500원` (O) / `12,500.00원` (X) |
| KPI 축약 (1만 이상) | 만/억 단위 | `1.2만원`, `125만원`, `1.2억원` |
| KPI 축약 (수량) | 만/억 단위 | `1.2만`, `125만`, `1.2억` |
| 테이블 셀 (금액) | 축약 없음, 정확한 수치 | `12,500원` |
| 테이블 셀 (수량) | 축약 없음, 콤마 구분 | `125,000` |
| 퍼센트 | 소수점 2자리 | `2.74%` |
| delta | 부호 + 값 | `+12.5%`, `-0.3%`, `+4건` |

축약 기준:
```
10,000 → "1만"
12,400 → "1.2만"
125,000 → "12.5만"
1,250,000 → "125만"
45,000,000 → "4,500만"
120,000,000 → "1.2억"
```

**en-US (영어)**

| 항목 | 규칙 | 예시 |
|------|------|------|
| 통화 표기 | "$" 전치 + 숫자 | `$12,500` |
| 소수점 | 센트 단위 표시 가능 | `$1,250.00` |
| KPI 축약 (1K 이상) | K/M/B 단위 | `1.2K`, `45.2K`, `1.2M`, `1.2B` |
| 테이블 셀 (금액) | 축약 없음 | `$12,500.00` |
| 테이블 셀 (수량) | 축약 없음, 콤마 구분 | `125,000` |
| 퍼센트 | 소수점 2자리 | `2.74%` |
| delta | 부호 + 값 | `+12.5%`, `-0.3%` |

### 포맷 유틸 함수 (권장 인터페이스)

```tsx
interface FormatOptions {
  locale: "ko-KR" | "en-US"    // 확장 가능
  currency?: "KRW" | "USD"     // 통화 종류
}

// KPI 값 (축약)
formatCompact(125000, { locale: "ko-KR" })              // "12.5만"
formatCompact(125000, { locale: "en-US" })               // "125K"

// KPI 통화 값 (축약)
formatCurrencyCompact(1250000, { locale: "ko-KR", currency: "KRW" })  // "125만원"
formatCurrencyCompact(1250000, { locale: "en-US", currency: "USD" })  // "$1.2M"

// 테이블 셀 (정확한 수치)
formatNumber(125000, { locale: "ko-KR" })                // "125,000"
formatNumber(125000, { locale: "en-US" })                // "125,000"

// 테이블 통화 셀 (정확한 수치)
formatCurrency(12500, { locale: "ko-KR", currency: "KRW" })  // "12,500원"
formatCurrency(12500, { locale: "en-US", currency: "USD" })  // "$12,500.00"

// 퍼센트
formatPercent(0.0274, { locale: "ko-KR" })               // "2.74%"

// delta
formatDelta(0.125)                                        // "+12.5%"
formatDelta(-0.003)                                       // "-0.3%"
```

### 적용 위치별 정리

| 컨텍스트 | 포맷 함수 | ko-KR 예시 | en-US 예시 |
|----------|----------|-----------|-----------|
| KPI Card 값 (금액) | `formatCurrencyCompact` | `1.2만원` | `$12.5K` |
| KPI Card 값 (수량) | `formatCompact` | `12.5만` | `125K` |
| KPI Card delta | `formatDelta` | `+12.5%` | `+12.5%` |
| 테이블 셀 (금액) | `formatCurrency` | `12,500원` | `$12,500.00` |
| 테이블 셀 (수량) | `formatNumber` | `125,000` | `125,000` |
| 테이블 셀 (비율) | `formatPercent` | `2.74%` | `2.74%` |

---

## Section 1: Tier Model Redesign

### 기존 → 변경

| | 기존 | 변경 |
|---|---|---|
| 원칙 | shadcn 직접 import 금지, Composed만 사용 | shadcn 직접 사용 기본, 복합 로직만 Composed |
| Primitive | 존재하되 import 금지 | 폐지 — shadcn을 직접 사용 |
| Composed | 12개 전부 Composed | 복합 로직이 있는 것만 |
| Page | 스켈레톤 템플릿 | 유지 — 패턴 규칙으로 구조 정의 |

### 새로운 2-tier 모델

| 티어 | 설명 | import 경로 | 예시 |
|------|------|------------|------|
| shadcn | shadcn/ui 컴포넌트 직접 사용 | `@/components/ui/*` | Card, Field, Button, Badge, Table, Dialog, Tabs, Select, Input, Textarea, Checkbox... |
| Composed | 도메인 로직이 캡슐화된 복합 컴포넌트 | `@/components/composed/*` | DataTable, SearchBar, KpiCard |

### Composed 자격 기준

컴포넌트를 Composed로 만들려면 아래 중 하나 이상 충족해야 한다:

| 기준 | 설명 | 예시 |
|------|------|------|
| 내부 상태 로직 | 정렬, 페이지네이션, 필터 등 상태 관리 | DataTable (TanStack Table 통합) |
| 도메인 특화 조합 | 여러 shadcn 컴포넌트를 도메인 규칙에 맞게 결합 | KpiCard (CardHeader + Badge + delta 계산) |
| 반복 패턴 추상화 | 동일 구조가 3회 이상 반복되면 추출 | SearchBar (Input + Select + DatePicker 필터 조합) |

단순 래핑은 Composed가 아니다:

```tsx
// NOT Composed — 단순 래핑
function FormCard({ title, children }) {
  return <Card><CardHeader><CardTitle>{title}</CardTitle></CardHeader>{children}</Card>
}

// Composed — 내부 로직이 있음
function DataTable({ columns, data, pageSize, searchable, onSelectionChange }) {
  // TanStack Table 인스턴스, 정렬 상태, 페이지네이션 로직...
}
```

### Composed 목록

| 컴포넌트 | 역할 | 내부 로직 |
|----------|------|----------|
| DataTable | 정렬/페이지네이션/선택/열고정 테이블 | TanStack Table, 상태 관리 |
| SearchBar | 복합 필터 조합 | 필터 config → Input/Select/DatePicker 동적 렌더링 |
| KpiCard | KPI 메트릭 카드 | delta 부호 판별, Badge variant 자동 결정 |

### 폐지되는 기존 Composed

| 기존 컴포넌트 | 대체 방법 |
|--------------|----------|
| PageLayout | 페이지 템플릿 패턴 규칙으로 대체 |
| PageHeader | shadcn 조합으로 직접 구성 (패턴 규칙) |
| ChartSection | Card + ChartContainer 직접 조합 (CARD-02 패턴) |
| KpiCardGroup | grid div + KpiCard 조합 |
| FormFieldSet | shadcn FieldSet + FieldLegend |
| FormField | shadcn Field + FieldLabel |
| FormRow | div + grid 클래스 |
| FormActions | CardFooter + Button |
| ActionButton | shadcn Button |
| StatusBadge | shadcn Badge |
| ConfirmDialog | shadcn AlertDialog |

### Import 규칙

```tsx
// shadcn 직접 import — 허용
import { Card, CardHeader, CardTitle, CardContent, CardFooter, CardAction } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Field, FieldLabel, FieldSet, FieldLegend, FieldGroup } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table"

// Composed import — barrel export
import { DataTable, SearchBar, KpiCard } from "@/components/composed"

// FORBIDDEN — 존재하지 않는 래퍼 만들어 쓰기
import { FormCard } from "@/components/composed"  // 단순 래핑은 Composed 아님
```

---

## Section 2: Card Strategy

### 원칙

| 원칙 | 설명 |
|------|------|
| Card = 섹션 컨테이너 | 대시보드의 모든 독립 섹션은 Card로 감싼다 |
| 이중 래핑 금지 | Card 안에 Card를 넣지 않는다. 컴포넌트가 내부적으로 Card를 사용하면 바깥에 Card를 씌우지 않는다 |
| Card 내부 구조 통일 | 모든 Card는 CardHeader (CardTitle + CardDescription?) + CardContent 기본 구조를 따른다 |

### CARD-01: KPI Card

```tsx
<div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
  <Card>
    <CardHeader>
      <CardDescription>Total Revenue</CardDescription>
      <CardTitle className="text-2xl font-semibold tabular-nums">
        {formatCurrencyCompact(12500000, { locale, currency })}
      </CardTitle>
      <CardAction>
        <Badge variant="outline">+12.5%</Badge>
      </CardAction>
    </CardHeader>
    <CardFooter className="flex-col items-start gap-1.5 text-sm">
      <div className="text-muted-foreground">vs last month</div>
    </CardFooter>
  </Card>
</div>
```

- CardContent 없이 CardHeader + CardFooter만 사용
- 그리드 래핑: 부모 div에 grid 클래스, 개별 Card는 그리드 아이템
- delta/trend는 CardAction 안에 Badge로

### CARD-02: Chart Card

```tsx
<Card>
  <CardHeader>
    <CardTitle>Daily Spend</CardTitle>
    <CardDescription>Last 30 days</CardDescription>
    <CardAction>
      <Select>{/* period selector */}</Select>
    </CardAction>
  </CardHeader>
  <CardContent>
    <ChartContainer config={chartConfig} className="aspect-auto h-[250px] w-full">
      <AreaChart data={data}>{/* ... */}</AreaChart>
    </ChartContainer>
  </CardContent>
</Card>
```

- Chart는 항상 CardContent 안에
- 기간 선택 등 컨트롤은 CardAction에

### CARD-03: Table Card

5가지 서브 패턴으로 구분:

**CARD-03a: 단순 Table (정적 데이터)**

```tsx
<Card>
  <CardHeader>
    <CardTitle>Login History</CardTitle>
    <CardDescription>Recent login activities</CardDescription>
  </CardHeader>
  <CardContent>
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Date</TableHead>
          <TableHead>IP Address</TableHead>
          <TableHead>Location</TableHead>
          <TableHead>Status</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        <TableRow>
          <TableCell>2026-03-27</TableCell>
          <TableCell>192.168.1.1</TableCell>
          <TableCell>Seoul, KR</TableCell>
          <TableCell><Badge variant="outline">Success</Badge></TableCell>
        </TableRow>
      </TableBody>
    </Table>
  </CardContent>
</Card>
```

**CARD-03b: DataTable + 인라인 필터**

```tsx
<Card>
  <CardHeader>
    <CardTitle>Campaigns</CardTitle>
    <CardDescription>142 total campaigns</CardDescription>
    <CardAction>
      <Button variant="outline" size="sm">Export</Button>
    </CardAction>
  </CardHeader>
  <CardContent>
    <div className="flex items-center gap-2 pb-4">
      <Input placeholder="Filter by name..." className="max-w-sm" />
      <Select>
        <SelectTrigger className="w-[150px]">
          <SelectValue placeholder="Status" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="active">Active</SelectItem>
          <SelectItem value="paused">Paused</SelectItem>
        </SelectContent>
      </Select>
    </div>
    <DataTable columns={columns} data={filteredRows} />
  </CardContent>
</Card>
```

**CARD-03c: DataTable + Tabs (뷰 전환)**

```tsx
<Card>
  <CardHeader>
    <CardTitle>Ad Groups</CardTitle>
    <CardDescription>Manage ad groups by status</CardDescription>
  </CardHeader>
  <CardContent>
    <Tabs defaultValue="active">
      <TabsList>
        <TabsTrigger value="active">Active (24)</TabsTrigger>
        <TabsTrigger value="paused">Paused (8)</TabsTrigger>
        <TabsTrigger value="ended">Ended (12)</TabsTrigger>
      </TabsList>
      <TabsContent value="active">
        <DataTable columns={columns} data={activeRows} />
      </TabsContent>
      <TabsContent value="paused">
        <DataTable columns={columns} data={pausedRows} />
      </TabsContent>
      <TabsContent value="ended">
        <DataTable columns={columns} data={endedRows} />
      </TabsContent>
    </Tabs>
  </CardContent>
</Card>
```

**CARD-03d: 페이지 메인 테이블 (풀 너비)**

```tsx
<Card>
  <CardHeader>
    <CardTitle>All Campaigns</CardTitle>
    <CardAction>
      <Button>New Campaign</Button>
    </CardAction>
  </CardHeader>
  <CardContent>
    <DataTable columns={columns} data={rows} />
  </CardContent>
  <CardFooter>
    <div className="text-sm text-muted-foreground">Showing 1-10 of 142</div>
  </CardFooter>
</Card>
```

### CARD-04: Form Card

```tsx
<Card>
  <CardHeader>
    <CardTitle>Basic Info</CardTitle>
    <CardDescription>Campaign details</CardDescription>
  </CardHeader>
  <CardContent>
    <form id="basic-info">
      <FieldGroup>
        <Field>
          <FieldLabel>Name</FieldLabel>
          <Input placeholder="Campaign name" />
        </Field>
      </FieldGroup>
    </form>
  </CardContent>
  <CardFooter className="border-t">
    <Button variant="outline" type="button">Cancel</Button>
    <Button type="submit" form="basic-info">Save</Button>
  </CardFooter>
</Card>
```

- form은 CardContent 안에, 버튼은 CardFooter에
- form id + Button form 속성으로 연결
- 하나의 form = 하나의 Card

### CARD-05: 혼합 Card (콘텐츠 그룹핑)

```tsx
<Card>
  <CardHeader>
    <CardTitle>Campaign Summary</CardTitle>
  </CardHeader>
  <CardContent className="flex flex-col gap-6">
    <KpiCard items={kpiItems} />
    <Separator />
    <ChartContainer>{/* mini chart */}</ChartContainer>
  </CardContent>
</Card>
```

- 관련 있는 요소들을 하나의 Card로 묶을 때
- 내부 구분은 Separator 또는 gap으로

### 컬럼 레이아웃 규칙

| 패턴 | 그리드 클래스 | 용도 |
|------|-------------|------|
| KPI 4열 | `grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4` | KPI 카드 그리드 |
| Chart 2열 | `grid grid-cols-1 gap-4 lg:grid-cols-2` | 차트 2개 나란히 |
| Chart 비대칭 | `grid grid-cols-1 gap-4 lg:grid-cols-[2fr_1fr]` | 메인 차트 + 보조 차트 |
| Form 1열 | Card 하나, 풀 너비 | 일반 폼 |
| Form 2열 | `grid grid-cols-1 gap-4 lg:grid-cols-2` | 설정 페이지 등 병렬 폼 카드 |

### Card 금지 패턴

```tsx
// FORBIDDEN — Card 이중 래핑
<Card>
  <CardContent>
    <Card>{/* ... */}</Card>
  </CardContent>
</Card>

// FORBIDDEN — CardHeader 없는 Card
<Card>
  <CardContent>{/* ... */}</CardContent>
</Card>

// FORBIDDEN — Card 없는 대시보드 섹션
<div className="rounded-lg border p-4">
  <h3>Revenue</h3>
  <AreaChart />
</div>
```

---

## Section 3: Field Strategy

### 원칙

| 원칙 | 설명 |
|------|------|
| shadcn Field 시스템 직접 사용 | 기존 FormField, FormFieldSet 등 커스텀 Composed 대신 shadcn의 Field, FieldSet, FieldGroup 사용 |
| Card + Field 조합 | Form의 시각적 경계는 Card가 담당, 필드 그룹핑은 FieldSet이 담당 |
| react-hook-form은 Controller로 직접 통합 | 별도 Form 래퍼 컴포넌트 없음 |

### Field 컴포넌트 계층

```
Card
  -- CardHeader (CardTitle + CardDescription)
  -- CardContent
  |    -- <form id="form-id">
  |         -- FieldGroup                    (전체 필드 레이아웃 래퍼)
  |              -- FieldSet                 (논리적 그룹: 기본정보, 부가정보)
  |                   -- FieldLegend         (그룹 제목)
  |                   -- Field               (개별 필드)
  |                        -- FieldLabel
  |                        -- Input | Select | Textarea | Checkbox
  |                        -- FieldDescription
  |                        -- FieldError
  -- CardFooter (Cancel + Submit)
```

### FIELD-01: 기본 Form (단일 섹션)

```tsx
<Card>
  <CardHeader>
    <CardTitle>Profile Settings</CardTitle>
    <CardDescription>Update your profile information.</CardDescription>
  </CardHeader>
  <CardContent>
    <form id="form-profile">
      <FieldGroup>
        <Field>
          <FieldLabel htmlFor="name">Name</FieldLabel>
          <Input id="name" placeholder="Full name" />
          <FieldDescription>Your public display name.</FieldDescription>
        </Field>
        <Field>
          <FieldLabel htmlFor="email">Email</FieldLabel>
          <Input id="email" type="email" placeholder="you@example.com" />
        </Field>
      </FieldGroup>
    </form>
  </CardContent>
  <CardFooter className="border-t">
    <Button variant="outline" type="button">Cancel</Button>
    <Button type="submit" form="form-profile">Save</Button>
  </CardFooter>
</Card>
```

### FIELD-02: 다중 섹션 Form (FieldSet으로 그룹핑)

```tsx
<Card>
  <CardHeader>
    <CardTitle>Create Account</CardTitle>
    <CardDescription>Fill in your information to get started.</CardDescription>
  </CardHeader>
  <CardContent>
    <form id="form-signup">
      <FieldGroup>
        <FieldSet>
          <FieldLegend>Basic Info</FieldLegend>
          <Field>
            <FieldLabel htmlFor="username">Username</FieldLabel>
            <Input id="username" />
          </Field>
          <Field>
            <FieldLabel htmlFor="email">Email</FieldLabel>
            <Input id="email" type="email" />
          </Field>
        </FieldSet>

        <FieldSeparator />

        <FieldSet>
          <FieldLegend>Additional Info</FieldLegend>
          <Field>
            <FieldLabel htmlFor="company">Company</FieldLabel>
            <Input id="company" />
          </Field>
          <Field>
            <FieldLabel htmlFor="role">Role</FieldLabel>
            <Select>
              <SelectTrigger id="role"><SelectValue placeholder="Select role" /></SelectTrigger>
              <SelectContent>
                <SelectItem value="dev">Developer</SelectItem>
                <SelectItem value="pm">PM</SelectItem>
              </SelectContent>
            </Select>
          </Field>
        </FieldSet>
      </FieldGroup>
    </form>
  </CardContent>
  <CardFooter className="border-t">
    <Button variant="outline" type="button">Cancel</Button>
    <Button type="submit" form="form-signup">Save</Button>
  </CardFooter>
</Card>
```

- 섹션 구분: FieldSet + FieldLegend (Card를 나누지 않음)
- 섹션 사이 시각적 구분: FieldSeparator
- 하나의 form = 하나의 Card 원칙 유지

### FIELD-03: 2열 필드 레이아웃

```tsx
<FieldSet>
  <FieldLegend>Campaign Details</FieldLegend>
  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
    <Field>
      <FieldLabel htmlFor="name">Campaign Name</FieldLabel>
      <Input id="name" />
    </Field>
    <Field>
      <FieldLabel htmlFor="status">Status</FieldLabel>
      <Select>
        <SelectTrigger id="status"><SelectValue /></SelectTrigger>
        <SelectContent>{/* ... */}</SelectContent>
      </Select>
    </Field>
  </div>
  <Field>
    <FieldLabel htmlFor="description">Description</FieldLabel>
    <Textarea id="description" />
    <FieldDescription>Optional campaign description.</FieldDescription>
  </Field>
</FieldSet>
```

- 2열이 필요한 곳만 div + grid 클래스 사용
- 풀 너비 필드와 혼합 가능

### FIELD-04: react-hook-form + Controller 통합

```tsx
<form id="form-campaign" onSubmit={form.handleSubmit(onSubmit)}>
  <FieldGroup>
    <Controller
      name="name"
      control={form.control}
      render={({ field, fieldState }) => (
        <Field data-invalid={fieldState.invalid}>
          <FieldLabel htmlFor={field.name}>Campaign Name</FieldLabel>
          <Input {...field} id={field.name} aria-invalid={fieldState.invalid} />
          <FieldDescription>Unique name for this campaign.</FieldDescription>
          {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
        </Field>
      )}
    />
  </FieldGroup>
</form>
```

- data-invalid로 Field 에러 상태 표시
- FieldError에 react-hook-form 에러 객체 직접 전달

### FIELD-05: Checkbox / Switch (가로 배치)

```tsx
<Field orientation="horizontal">
  <Checkbox id="terms" />
  <FieldContent>
    <FieldLabel htmlFor="terms">Accept terms and conditions</FieldLabel>
    <FieldDescription>You agree to our Terms of Service and Privacy Policy.</FieldDescription>
  </FieldContent>
</Field>
```

- orientation="horizontal" — 체크박스/스위치 + 라벨이 나란히
- FieldContent로 라벨+설명을 묶어서 배치

### CardFooter 버튼 규칙

```tsx
// CORRECT — Cancel(outline) 먼저, Submit 뒤에
<CardFooter className="border-t">
  <Button variant="outline" type="button">Cancel</Button>
  <Button type="submit" form="form-id">Save</Button>
</CardFooter>

// FORBIDDEN — 순서 반대
<CardFooter className="border-t">
  <Button type="submit">Save</Button>
  <Button variant="outline">Cancel</Button>
</CardFooter>

// FORBIDDEN — CardContent 안에 submit 버튼
<CardContent>
  <form>
    {/* fields */}
    <Button type="submit">Save</Button>
  </form>
</CardContent>
```

### Field 금지 패턴

```tsx
// FORBIDDEN — Card 없이 form 단독 사용 (대시보드 페이지에서)
<form>
  <FieldGroup>{/* ... */}</FieldGroup>
  <Button type="submit">Save</Button>
</form>

// FORBIDDEN — FieldLabel 없는 Input
<Field>
  <Input placeholder="Name" />
</Field>

// FORBIDDEN — Field 밖의 단독 Input
<CardContent>
  <Input placeholder="Search..." />
</CardContent>

// FORBIDDEN — FieldSet 대신 Card를 나눠서 섹션 구분
<Card><CardContent>{/* 기본정보 */}</CardContent></Card>
<Card><CardContent>{/* 부가정보 */}</CardContent></Card>
```

예외: 검색/필터용 Input — DataTable 상단 인라인 필터는 Field 래핑 불필요 (CARD-03b 패턴 참고)

---

## Section 4: DataTable Strategy

### 원칙

| 원칙 | 설명 |
|------|------|
| DataTable = Composed 컴포넌트 | TanStack Table 기반, 정렬/필터/페이지네이션 로직을 캡슐화 |
| Table = shadcn 직접 사용 | 소규모 정적 데이터는 shadcn Table 그대로 |
| 항상 Card 안에 | 대시보드에서 테이블은 반드시 Card로 래핑 |

### Table vs DataTable 선택 기준

```
데이터가 20행 이하? --yes--> 정렬/필터 필요? --no--> Table (shadcn)
       |                         |
       no                       yes
       |                         |
       v                         v
   DataTable (Composed)     DataTable (Composed)
```

### DataTable Props 인터페이스

```tsx
interface DataTableColumn<T> {
  accessorKey?: keyof T
  id?: string                            // 체크박스, 액션 등 데이터 키 없는 컬럼
  header: string | (({ table }) => ReactNode)  // 문자열 또는 커스텀 (체크박스 헤더)
  sortable?: boolean                     // default: false
  pinned?: "left" | "right"             // 열고정
  align?: "left" | "center" | "right"   // default: "left"
  cell?: (row: T) => React.ReactNode
  enableSorting?: boolean               // false면 정렬 비활성화 (체크박스, 액션)
}

interface DataTableProps<T> {
  columns: DataTableColumn<T>[]
  data: T[]
  onRowClick?: (row: T) => void
  onSelectionChange?: (rows: T[]) => void  // 체크박스 선택 콜백
  pageSize?: number                        // default: 10
  searchable?: boolean
  searchPlaceholder?: string
  emptyMessage?: string
}
```

### 표준 컬럼 순서 규칙

| 순서 | 역할 | 고정 | 정렬 | 예시 |
|------|------|------|------|------|
| 1 | 체크박스 선택 | sticky | - | 전체선택/개별선택 |
| 2 | ID | sticky | O | 캠페인 번호, 광고그룹 ID |
| 3 | 타이틀(네임) | sticky | O | 캠페인명, 광고그룹명 |
| 4+ | 속성 컬럼 | - | O | 상태, 채널, 기간 |
| 뒤쪽 | 지표 컬럼 (숫자) | - | O | 노출수, 클릭수, CTR, CPA |
| 마지막 | 액션 | - | - | 더보기 메뉴 |

- 1~3번(체크박스, ID, 타이틀)은 열고정(sticky) — 가로 스크롤 시에도 고정
- 지표 컬럼은 tabular-nums text-right — 숫자 우측 정렬

### 기본 제공 기능

| 기능 | 구현 위치 | 설명 |
|------|----------|------|
| 정렬 | 헤더 클릭 | sortable: true인 컬럼, 헤더에 정렬 아이콘, asc -> desc -> none 순환 |
| 열고정 | pinned: "left" | 체크박스 + ID + 타이틀까지 고정, 가로 스크롤 시 sticky |
| 페이지네이션 | DataTable 하단 | pageSize 기준, 이전/다음 + 페이지 번호 |
| 행 선택 | 체크박스 컬럼 | 전체선택/개별선택, onSelectionChange로 콜백 |

### TABLE-05: 전체 컬럼 예시

```tsx
const columns: DataTableColumn<Campaign>[] = [
  // 1. 체크박스 — 열고정
  {
    id: "select",
    header: ({ table }) => (
      <Checkbox
        checked={table.getIsAllPageRowsSelected()}
        onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
        aria-label="Select all"
      />
    ),
    cell: ({ row }) => (
      <Checkbox
        checked={row.getIsSelected()}
        onCheckedChange={(value) => row.toggleSelected(!!value)}
        aria-label="Select row"
      />
    ),
    enableSorting: false,
    pinned: "left",
  },

  // 2. ID — 열고정, 정렬 가능
  {
    accessorKey: "id",
    header: "ID",
    sortable: true,
    pinned: "left",
    cell: (row) => (
      <span className="font-medium text-muted-foreground">{row.id}</span>
    ),
  },

  // 3. 타이틀 — 열고정, 정렬 가능
  {
    accessorKey: "name",
    header: "Campaign Name",
    sortable: true,
    pinned: "left",
    cell: (row) => (
      <span className="font-medium text-foreground">{row.name}</span>
    ),
  },

  // 4+. 속성 컬럼
  {
    accessorKey: "status",
    header: "Status",
    sortable: true,
    cell: (row) => <Badge variant="outline">{row.status}</Badge>,
  },
  {
    accessorKey: "channel",
    header: "Channel",
    sortable: true,
  },
  {
    accessorKey: "period",
    header: "Period",
    cell: (row) => (
      <span className="text-sm text-muted-foreground">
        {row.startDate} ~ {row.endDate}
      </span>
    ),
  },

  // 지표 컬럼 — 숫자, 우측정렬
  {
    accessorKey: "impressions",
    header: "Impressions",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatNumber(row.impressions, { locale })}</span>
    ),
  },
  {
    accessorKey: "clicks",
    header: "Clicks",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatNumber(row.clicks, { locale })}</span>
    ),
  },
  {
    accessorKey: "ctr",
    header: "CTR",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatPercent(row.ctr, { locale })}</span>
    ),
  },
  {
    accessorKey: "spend",
    header: "Spend",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="font-medium tabular-nums">
        {formatCurrency(row.spend, { locale, currency })}
      </span>
    ),
  },
  {
    accessorKey: "cpa",
    header: "CPA",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatCurrency(row.cpa, { locale, currency })}</span>
    ),
  },

  // 마지막. 액션
  {
    id: "actions",
    header: "",
    enableSorting: false,
    cell: (row) => (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon">
            <MoreHorizontalIcon className="size-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem>Edit</DropdownMenuItem>
          <DropdownMenuItem>Duplicate</DropdownMenuItem>
          <DropdownMenuItem className="text-destructive">Delete</DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  },
]
```

### DataTable 금지 패턴

```tsx
// FORBIDDEN — Card 없이 DataTable 단독 사용
<DataTable columns={columns} data={rows} />

// FORBIDDEN — DataTable 내부에서 Card를 사용하는 구현
// DataTable Composed 컴포넌트는 Card-free여야 함

// FORBIDDEN — 대규모 데이터에 Table 직접 사용
<Table>
  {bigData.map(/* 100+ rows */)}
</Table>

// FORBIDDEN — 셀 렌더링에 하드코딩 색상
cell: (row) => <span className="text-red-500">{row.value}</span>
// CORRECT:
cell: (row) => <span className="text-destructive">{row.value}</span>
```

---

## Section 5: Page Templates

### 페이지 구조 규칙

| 규칙 | 설명 |
|------|------|
| 최상위 래퍼 | `div.flex.flex-col.gap-6.p-6` — 모든 페이지 동일 |
| Page Header | Card 아님 — div + h1 + p + 액션 버튼 직접 구성 |
| 섹션 순서 (대시보드) | KPI -> Chart -> Table (고정) |
| 섹션 순서 (디테일) | KPI -> Chart -> 관련 Table (고정) |
| 폼 페이지 | back 버튼 필수, 하나의 Card에 form 전체 |
| Chart 그리드 | 대시보드는 lg:grid-cols-2 필수 |

### PAGE-01: 리스트 페이지

```tsx
<div className="flex flex-col gap-6 p-6">
  {/* Page Header */}
  <div className="flex items-center justify-between">
    <div>
      <h1 className="text-2xl font-semibold">Campaigns</h1>
      <p className="text-sm text-muted-foreground">Manage your campaigns</p>
    </div>
    <Button>New Campaign</Button>
  </div>

  {/* Table Card */}
  <Card>
    <CardHeader>
      <CardTitle>All Campaigns</CardTitle>
      <CardDescription>142 campaigns</CardDescription>
      <CardAction>
        <Button variant="outline" size="sm">Export</Button>
      </CardAction>
    </CardHeader>
    <CardContent>
      <div className="flex items-center gap-2 pb-4">
        <Input placeholder="Filter by name..." className="max-w-sm" />
        <Select>{/* status filter */}</Select>
      </div>
      <DataTable columns={columns} data={rows} onRowClick={handleRowClick} />
    </CardContent>
  </Card>
</div>
```

### PAGE-02: 디테일 페이지

```tsx
<div className="flex flex-col gap-6 p-6">
  {/* Page Header with back navigation */}
  <div className="flex items-center justify-between">
    <div className="flex items-center gap-4">
      <Button variant="ghost" size="icon" asChild>
        <a href="/campaigns"><ArrowLeftIcon /></a>
      </Button>
      <div>
        <h1 className="text-2xl font-semibold">Campaign Detail</h1>
        <p className="text-sm text-muted-foreground">Campaign #1234</p>
      </div>
    </div>
    <Badge variant="outline">Active</Badge>
  </div>

  {/* KPI Cards */}
  <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
    <KpiCard label="Impressions" value={125000} delta="+12.5%" deltaPositive />
    <KpiCard label="Clicks" value={3420} delta="+8.2%" deltaPositive />
    <KpiCard label="CTR" value="2.74%" delta="-0.3%" />
    <KpiCard label="CPA" value={formatCurrencyCompact(12500, { locale, currency })} delta="-5.1%" deltaPositive />
  </div>

  {/* Charts */}
  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
    <Card>
      <CardHeader>
        <CardTitle>Daily Spend</CardTitle>
        <CardAction><Select>{/* period */}</Select></CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={spendConfig} className="aspect-auto h-[250px] w-full">
          <AreaChart data={spendData}>{/* ... */}</AreaChart>
        </ChartContainer>
      </CardContent>
    </Card>
    <Card>
      <CardHeader>
        <CardTitle>Channel Distribution</CardTitle>
      </CardHeader>
      <CardContent>
        <ChartContainer config={channelConfig} className="aspect-auto h-[250px] w-full">
          <PieChart data={channelData}>{/* ... */}</PieChart>
        </ChartContainer>
      </CardContent>
    </Card>
  </div>

  {/* Related Table */}
  <Card>
    <CardHeader>
      <CardTitle>Ad Groups</CardTitle>
      <CardDescription>8 ad groups</CardDescription>
    </CardHeader>
    <CardContent>
      <DataTable columns={adGroupColumns} data={adGroups} onRowClick={handleAdGroupClick} />
    </CardContent>
  </Card>
</div>
```

### PAGE-03: 폼 페이지

```tsx
<div className="flex flex-col gap-6 p-6">
  {/* Page Header with back */}
  <div className="flex items-center gap-4">
    <Button variant="ghost" size="icon" asChild>
      <a href="/campaigns"><ArrowLeftIcon /></a>
    </Button>
    <h1 className="text-2xl font-semibold">Create Campaign</h1>
  </div>

  {/* Form Card */}
  <Card>
    <CardHeader>
      <CardTitle>Campaign Info</CardTitle>
      <CardDescription>Fill in the details for your new campaign.</CardDescription>
    </CardHeader>
    <CardContent>
      <form id="form-campaign">
        <FieldGroup>
          <FieldSet>
            <FieldLegend>Basic Info</FieldLegend>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field>
                <FieldLabel htmlFor="name">Campaign Name</FieldLabel>
                <Input id="name" />
              </Field>
              <Field>
                <FieldLabel htmlFor="channel">Channel</FieldLabel>
                <Select>
                  <SelectTrigger id="channel"><SelectValue /></SelectTrigger>
                  <SelectContent>{/* ... */}</SelectContent>
                </Select>
              </Field>
            </div>
            <Field>
              <FieldLabel htmlFor="description">Description</FieldLabel>
              <Textarea id="description" />
              <FieldDescription>Optional campaign description.</FieldDescription>
            </Field>
          </FieldSet>

          <FieldSeparator />

          <FieldSet>
            <FieldLegend>Budget & Schedule</FieldLegend>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field>
                <FieldLabel htmlFor="budget">Daily Budget</FieldLabel>
                <Input id="budget" type="number" placeholder="0" />
              </Field>
              <Field>
                <FieldLabel htmlFor="period">Period</FieldLabel>
                <DatePickerWithRange id="period" />
              </Field>
            </div>
          </FieldSet>
        </FieldGroup>
      </form>
    </CardContent>
    <CardFooter className="border-t">
      <Button variant="outline" type="button" asChild>
        <a href="/campaigns">Cancel</a>
      </Button>
      <Button type="submit" form="form-campaign">Save</Button>
    </CardFooter>
  </Card>
</div>
```

### PAGE-04: 대시보드 오버뷰

```tsx
<div className="flex flex-col gap-6 p-6">
  {/* Page Header */}
  <div className="flex items-center justify-between">
    <div>
      <h1 className="text-2xl font-semibold">Dashboard</h1>
      <p className="text-sm text-muted-foreground">Overview of performance</p>
    </div>
    <Button>New Campaign</Button>
  </div>

  {/* KPI Cards — 4 columns */}
  <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
    <KpiCard label="Total Revenue" value={formatCurrencyCompact(45231000, { locale, currency })} delta="+20.1%" deltaPositive />
    <KpiCard label="Active Campaigns" value={142} delta="+4" deltaPositive />
    <KpiCard label="Avg CTR" value="2.4%" delta="-0.2%" />
    <KpiCard label="Total Spend" value={formatCurrencyCompact(12500000, { locale, currency })} delta="+8.5%" deltaPositive />
  </div>

  {/* Charts — 2 columns */}
  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
    <Card>
      <CardHeader>
        <CardTitle>Daily Spend</CardTitle>
        <CardAction><Select>{/* period */}</Select></CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={spendConfig} className="aspect-auto h-[250px] w-full">
          <AreaChart data={spendData}>{/* ... */}</AreaChart>
        </ChartContainer>
      </CardContent>
    </Card>
    <Card>
      <CardHeader>
        <CardTitle>Channel Split</CardTitle>
      </CardHeader>
      <CardContent>
        <ChartContainer config={channelConfig} className="aspect-auto h-[250px] w-full">
          <PieChart>{/* ... */}</PieChart>
        </ChartContainer>
      </CardContent>
    </Card>
  </div>

  {/* Recent Activity Table */}
  <Card>
    <CardHeader>
      <CardTitle>Recent Campaigns</CardTitle>
      <CardDescription>Latest activity</CardDescription>
    </CardHeader>
    <CardContent>
      <DataTable columns={columns} data={recentRows} pageSize={5} />
    </CardContent>
  </Card>
</div>
```
