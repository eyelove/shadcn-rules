---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
  - "resources/js/**/*.tsx"
---

# Card Usage Strategy

Every independent dashboard section MUST be wrapped in a Card. Cards provide visual containment, consistent spacing, and theming support across all page types.

## Principles

1. **Card = section container.** Every independent dashboard section — KPI group, chart, table, form — lives inside a Card. No floating content with ad-hoc borders or backgrounds.
// WHY: Cards are the only visual container that respects token-based surfaces (bg-card, border-border, rounded-[--radius]). Raw divs with border classes fragment theming.

2. **No double wrapping.** NEVER nest Card inside Card. One Card per section, one level deep.
// WHY: Double wrapping creates redundant padding, doubled borders, and broken visual hierarchy. If content needs sub-grouping, use Separator or gap utilities inside the single Card.

3. **Unified internal structure.** Every Card MUST have a CardHeader containing at least a CardTitle. CardContent follows when the card has body content. CardFooter is optional.
// WHY: Consistent header → content → footer structure makes every card scannable and predictable. Skipping CardHeader removes the section label — users lose context.

---

## Card Patterns

### CARD-01 — KPI Card

KPI cards display a single metric with optional delta badge. They are laid out in a responsive grid.

**Grid wrapper:**
```tsx
<div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
  {kpiItems.map((item) => (
    <Card key={item.label}>
      <CardHeader>
        <CardDescription>{item.label}</CardDescription>
        <CardTitle className="text-2xl font-semibold tabular-nums">
          {item.value}
        </CardTitle>
        <CardAction>
          <Badge variant="outline">{item.delta}</Badge>
        </CardAction>
      </CardHeader>
      <CardFooter className="text-muted-foreground text-sm">
        {item.footerText}
      </CardFooter>
    </Card>
  ))}
</div>
```

**Rules:**
- No CardContent — KPI cards use CardHeader + CardFooter only
- Delta badge inside CardAction, styled with token-based colors (`text-[--kpi-positive]` / `text-[--kpi-negative]`)
- `tabular-nums` on the value prevents layout shift when numbers change
// WHY: KPI cards are dense — CardContent adds unnecessary padding between the number and footer.

---

### CARD-02 — Chart Card

Chart cards wrap a single visualization with an optional period selector in the header.

```tsx
<Card>
  <CardHeader>
    <CardTitle>Daily Spend</CardTitle>
    <CardDescription>Last 30 days of ad spend</CardDescription>
    <CardAction>
      <Select>
        <SelectTrigger className="w-[140px]">
          <SelectValue placeholder="Period" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="7d">Last 7 days</SelectItem>
          <SelectItem value="30d">Last 30 days</SelectItem>
        </SelectContent>
      </Select>
    </CardAction>
  </CardHeader>
  <CardContent>
    <ChartContainer config={chartConfig} className="min-h-[200px] w-full">
      <LineChart accessibilityLayer data={data}>
        <CartesianGrid vertical={false} />
        <XAxis dataKey="month" tickLine={false} tickMargin={10} axisLine={false} />
        <YAxis tickLine={false} axisLine={false} />
        <ChartTooltip content={<ChartTooltipContent />} />
        <Line dataKey="desktop" stroke="var(--color-desktop)" />
        <Line dataKey="mobile" stroke="var(--color-mobile)" />
      </LineChart>
    </ChartContainer>
  </CardContent>
</Card>
```

**Period selector in CardAction — Select vs Date Range Picker:**

기본값은 Select (고정 기간: 7d/30d/90d). 사용자가 직접 날짜 범위를 지정해야 하면 Date Range Picker를 사용한다.

```tsx
// 기본값 — 위 CARD-02 예제의 Select 패턴을 따른다

// 커스텀 범위 — Date Range Picker with Presets
<CardAction>
  <Popover>
    <PopoverTrigger asChild>
      <Button variant="outline" className="w-[260px] justify-start text-left font-normal">
        <CalendarIcon className="mr-2 h-4 w-4" />
        {dateRange?.from ? (
          dateRange.to ? (
            <>{formatDate(dateRange.from, { locale: "ko-KR" })} - {formatDate(dateRange.to, { locale: "ko-KR" })}</>
          ) : formatDate(dateRange.from, { locale: "ko-KR" })
        ) : <span className="text-muted-foreground">기간 선택</span>}
      </Button>
    </PopoverTrigger>
    <PopoverContent className="w-auto p-0" align="start">
      <div className="flex flex-col space-y-2 p-2">
        <Select onValueChange={(value) => handlePreset(value)}>
          <SelectTrigger><SelectValue placeholder="Select preset" /></SelectTrigger>
          <SelectContent position="popper">
            <SelectItem value="7d">Last 7 days</SelectItem>
            <SelectItem value="30d">Last 30 days</SelectItem>
            <SelectItem value="90d">Last 90 days</SelectItem>
          </SelectContent>
        </Select>
        <div className="rounded-md border">
          <Calendar mode="range" selected={dateRange} onSelect={setDateRange} numberOfMonths={2} initialFocus />
        </div>
      </div>
    </PopoverContent>
  </Popover>
</CardAction>
```

// WHY: 고정 기간(7d/30d)만 필요하면 Select가 간결하다. 자유 범위 지정이 필요하면 Date Range Picker.
// 프리셋 Select와 Calendar이 같은 state를 공유하므로 프리셋 선택 시 달력도 업데이트된다.

**Rules:**
- Chart colors are defined in `chartConfig` and referenced as `var(--color-KEY)` on chart elements
- `ChartContainer` MUST have `min-h-[VALUE]` or `aspect-*` for responsive sizing
- `accessibilityLayer` on the chart root for keyboard/screen reader support
- Period selector (Select, ToggleGroup, or Date Range Picker) goes in CardAction, not above the chart
- Use `<ChartTooltip content={<ChartTooltipContent />} />` — NEVER raw Recharts `<Tooltip>` or `contentStyle`
- Use `<ChartLegend content={<ChartLegendContent />} />` when a legend is needed
- Axis/Grid styling is handled by `ChartContainer` internally — do NOT pass `stroke` props to `CartesianGrid`, `XAxis`, `YAxis`
// WHY: shadcn's ChartContainer handles axis/grid theming. Manual stroke props bypass this and create maintenance burden.

---

### CARD-03 — Table Card

Four sub-patterns depending on complexity.

#### CARD-03a — Simple Table (static data)

```tsx
<Card>
  <CardHeader>
    <CardTitle>Recent Transactions</CardTitle>
    <CardDescription>Last 5 entries</CardDescription>
  </CardHeader>
  <CardContent>
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Date</TableHead>
          <TableHead>Amount</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {rows.map((row) => (
          <TableRow key={row.id}>
            <TableCell>{row.date}</TableCell>
            <TableCell>{row.amount}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  </CardContent>
</Card>
```

#### CARD-03b — DataTable + Inline Filter

```tsx
<Card>
  <CardHeader>
    <CardTitle>Campaigns</CardTitle>
    <CardDescription>All active campaigns</CardDescription>
  </CardHeader>
  <CardContent>
    <div className="flex items-center gap-2 pb-4">
      <Input placeholder="Filter by name..." />
      <Select>
        <SelectTrigger className="w-[180px]">
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
// WHY: The filter toolbar sits inside CardContent above the DataTable — it is part of the table's context, not a separate section.

#### CARD-03c — DataTable + Tabs

```tsx
<Card>
  <CardHeader>
    <CardTitle>Ad Groups</CardTitle>
    <CardDescription>View by status</CardDescription>
  </CardHeader>
  <CardContent>
    <Tabs defaultValue="active">
      <TabsList>
        <TabsTrigger value="active">Active</TabsTrigger>
        <TabsTrigger value="paused">Paused</TabsTrigger>
      </TabsList>
      <TabsContent value="active">
        <DataTable columns={columns} data={activeRows} />
      </TabsContent>
      <TabsContent value="paused">
        <DataTable columns={columns} data={pausedRows} />
      </TabsContent>
    </Tabs>
  </CardContent>
</Card>
```
// WHY: Tabs switch views within the same data context. They belong inside the Card, not wrapping it.

#### CARD-03d — Full-Width Main Table

```tsx
<Card>
  <CardHeader>
    <CardTitle>All Campaigns</CardTitle>
    <CardDescription>Showing 1-20 of 142</CardDescription>
    <CardAction>
      <Button onClick={onExport} variant="outline" size="sm">Export</Button>
    </CardAction>
  </CardHeader>
  <CardContent>
    <DataTable columns={columns} data={rows} />
  </CardContent>
  <CardFooter className="flex items-center justify-between text-sm text-muted-foreground">
    <span>Page 1 of 8</span>
    <div className="flex gap-2">
      <Button variant="outline" onClick={onPrev} disabled={page === 1}>Previous</Button>
      <Button variant="outline" onClick={onNext}>Next</Button>
    </div>
  </CardFooter>
</Card>
```
// WHY: CardFooter handles pagination controls — it sits outside the scrollable content area and stays visible.

For full DataTable column definitions and render function rules, see: @.claude/rules/data-table.md

---

### CARD-04 — Form Card

Form cards embed a form inside a Card, typically on settings or edit pages.

```tsx
<Card>
  <CardHeader>
    <CardTitle>Campaign Settings</CardTitle>
    <CardDescription>Update campaign configuration</CardDescription>
  </CardHeader>
  <CardContent>
    <form id="campaign-form" onSubmit={handleSubmit}>
      {/* form 내부 패턴: @.claude/rules/fields.md FIELD-01~07 */}
    </form>
  </CardContent>
  <CardFooter className="gap-2">
    <Button variant="outline" type="button" onClick={onCancel}>Cancel</Button>
    <Button type="submit" form="campaign-form">Save</Button>
  </CardFooter>
</Card>
```

**Rules:**
- `<form>`에 `id` 부여, submit 버튼은 `form="form-id"`로 CardFooter에서 연결
- CardFooter에 `className="gap-2"` 필수 (shadcn CardFooter에 기본 gap 없음)
- 보조 액션은 `variant="outline"`, 주요 액션은 default variant
- 3개 이상 버튼 허용 (예: Cancel + Save Draft + Publish)
- form 내부 구조(FieldGroup, FieldSet, Field 등)는 @.claude/rules/fields.md 참조

// WHY: Card가 폼의 시각적 경계를 제공한다. CardFooter가 버튼을 CardContent 밖에 고정한다.
// form id linking으로 버튼이 form 엘리먼트 안에 있지 않아도 submit이 동작한다.

---

### CARD-05 — Mixed Card (Content Grouping)

When multiple related elements share a section, group them in one Card separated by Separator or gap.

```tsx
<Card>
  <CardHeader>
    <CardTitle>Campaign Summary</CardTitle>
  </CardHeader>
  <CardContent className="space-y-4">
    <div className="grid grid-cols-2 gap-4">
      <div>
        <p className="text-sm text-muted-foreground">Status</p>
        <Badge variant="outline">Active</Badge>
      </div>
      <div>
        <p className="text-sm text-muted-foreground">Budget</p>
        <p className="text-lg font-semibold">$12,400</p>
      </div>
    </div>
    <Separator />
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Channel</TableHead>
          <TableHead>Spend</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {channels.map((ch) => (
          <TableRow key={ch.name}>
            <TableCell>{ch.name}</TableCell>
            <TableCell>{ch.spend}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  </CardContent>
</Card>
```

**Rules:**
- Use `space-y-4` or Separator to visually divide sub-sections inside CardContent (spacing defaults: @tokens.md)
- NEVER create a second Card for the table — it shares context with the summary above
// WHY: Mixed cards keep related data together. Splitting into separate cards implies independence.

---

## Column Layout Rules

Column layout grid classes are defined in @.claude/rules/page-templates.md (Column Layout Reference). Do not duplicate here.

---

## Forbidden Patterns

### Card Double Wrapping

NEVER nest Card inside Card. One Card per section, one level deep.
// WHY: Nested cards double padding and borders, creating visual noise and broken elevation hierarchy.

Full rule with examples: @.claude/rules/forbidden.md FORB-06

### Card Without CardHeader

```tsx
// FORBIDDEN — no CardHeader
<Card>
  <CardContent>
    <DataTable columns={columns} data={rows} />
  </CardContent>
</Card>

// CORRECT — always include CardHeader with at least CardTitle
<Card>
  <CardHeader>
    <CardTitle>Campaigns</CardTitle>
  </CardHeader>
  <CardContent>
    <DataTable columns={columns} data={rows} />
  </CardContent>
</Card>
```
// WHY: CardHeader provides the section label. Without it, users cannot scan the page to understand what each card contains.

### Dashboard Section Without Card

```tsx
// FORBIDDEN — raw div with border instead of Card
<div className="border border-border rounded-[--radius] p-4 bg-card">
  <h3 className="font-semibold">Revenue</h3>
  <LineChart data={data} />
</div>

// CORRECT — use Card with proper structure
<Card>
  <CardHeader>
    <CardTitle>Revenue</CardTitle>
  </CardHeader>
  <CardContent>
    <ChartContainer config={chartConfig}>
      <LineChart data={data} />
    </ChartContainer>
  </CardContent>
</Card>
```
// WHY: Raw divs mimicking cards bypass Card's built-in token support (bg-card, shadow, radius) and cannot be audited as proper sections.

---

## Escape Hatch

If a card layout need is not covered by CARD-01 through CARD-05:
1. STOP — do not use a raw div with border/background as a substitute
2. Describe the specific layout need and why no existing pattern covers it
3. Wait for explicit approval before implementing
4. If approved, document the exception inline with a `// EXCEPTION:` comment explaining why
