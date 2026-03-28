---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "pages/**/*.tsx"
  - "resources/js/**/*.tsx"
---

# Page Skeleton Templates

Every page type has a canonical structure. Follow it exactly -- do not invent structure.
Use shadcn components directly (`@/components/ui/*`) plus Composed components (`@/components/composed`) for DataTable and KpiCard.

## Page Structure Rules

**절대 규칙:**
| Rule | Description |
|------|------------|
| Root wrapper | `div.flex.flex-col.gap-4.p-4` -- all pages (spacing defaults: @tokens.md) |
| Page header | NOT a Card -- `div` with `h1` + `p` + action Button |

**기본값** (특별한 지시 없으면 이대로 생성, 사용자 지시 시 변경 가능):
| Rule | Default | Override example |
|------|---------|-----------------|
| Section order (dashboard) | KPI -> Chart -> Table | "차트를 먼저 배치해줘" |
| Section order (detail) | KPI -> Chart -> Related Table | "테이블만 보여줘" |
| Form page | Back button + single Card | 모달 폼, 위저드 폼 |
| Chart grid (dashboard) | `lg:grid-cols-2` | 단일 차트 full-width, 비대칭 `lg:grid-cols-[2fr_1fr]` |
| List page | Table only, no KPI/Chart | "상단에 요약 KPI 추가해줘" |

// WHY: 기본 섹션 순서는 예측 가능한 스캔 패턴을 만든다. 하지만 각 프로젝트/페이지의 요구에 따라 변경할 수 있다.

---

## PAGE-01 -- List Page

List pages show filtered tabular data. No KPI cards or charts.

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardAction } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"
import { DataTable } from "@/components/composed"

<div className="flex flex-col gap-4 p-4">
  {/* Page Header -- div, not Card */}
  <div className="flex items-center justify-between">
    <div>
      <h1 className="text-xl font-semibold">Campaigns</h1>
      <p className="text-sm text-muted-foreground">Manage your campaigns</p>
    </div>
    <Button onClick={handleCreate}>New Campaign</Button>
  </div>

  {/* Table Card */}
  <Card>
    <CardHeader>
      <CardTitle>All Campaigns</CardTitle>
      <CardDescription>142 campaigns</CardDescription>
      <CardAction>
        <Button variant="outline" size="sm" onClick={handleExport}>Export</Button>
      </CardAction>
    </CardHeader>
    <CardContent>
      <div className="flex items-center gap-2 pb-4">
        <Input placeholder="Filter by name..." className="max-w-sm" />
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
      <DataTable columns={columns} data={rows} onRowClick={(row) => navigate(`/campaigns/${row.id}`)} emptyMessage="No campaigns found." />
    </CardContent>
  </Card>
</div>
```

// FORBIDDEN (절대 규칙):
// - Wrapping the page header in a Card -- page headers are plain divs
// - Placing filter inputs outside the Card -- filters are part of the table's context
// - Using DataTable without a Card wrapper -- see @.claude/rules/cards.md CARD-03b
// - Omitting CardHeader on the table Card -- every Card needs at least a CardTitle
//
// DEFAULT (기본값 -- 사용자 지시 시 변경 가능):
// - List page는 테이블만 포함 (사용자 요청 시 KPI/Chart 추가 가능)

---

## PAGE-02 -- Detail Page

Detail pages show a single entity with KPI summary, charts, and a related data table.
Section order is fixed: KPI -> Chart -> Table.

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardAction } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"
import { ArrowLeftIcon } from "lucide-react"
import { DataTable, KpiCard } from "@/components/composed"
import { formatCurrencyCompact, formatCompact, formatDelta } from "@/lib/format"

<div className="flex flex-col gap-4 p-4">
  {/* Page Header -- div, not Card. Back button + status badge. */}
  <div className="flex items-center justify-between">
    <div className="flex items-center gap-4">
      <Button variant="ghost" size="icon" onClick={() => navigate("/campaigns")}>
        <ArrowLeftIcon className="h-4 w-4" />
      </Button>
      <div>
        <h1 className="text-xl font-semibold">{campaign.name}</h1>
        <p className="text-sm text-muted-foreground">Campaign details and performance</p>
      </div>
    </div>
    <Badge variant="outline">{campaign.status}</Badge>
  </div>

  {/* KPI Cards -- 4-column responsive grid */}
  <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
    {kpiItems.map((item) => (
      <KpiCard key={item.label} label={item.label} value={item.value} delta={item.delta} deltaPositive={item.deltaPositive} />
    ))}
  </div>

  {/* Chart Cards -- 2-column grid */}
  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
    <Card>
      <CardHeader>
        <CardTitle>Daily Spend</CardTitle>
        <CardAction>
          {/* Period Select — see cards.md CARD-02 for full pattern */}
        </CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={spendChartConfig} className="min-h-[200px] w-full">
          <LineChart accessibilityLayer data={spendData}>
            <CartesianGrid vertical={false} />
            <XAxis dataKey="month" tickLine={false} tickMargin={10} axisLine={false} />
            <YAxis tickLine={false} axisLine={false} />
            <ChartTooltip content={<ChartTooltipContent />} />
            <Line dataKey="spend" stroke="var(--color-spend)" />
          </LineChart>
        </ChartContainer>
      </CardContent>
    </Card>
    <Card>
      <CardHeader>
        <CardTitle>Channel Split</CardTitle>
        <CardAction>
          {/* Period Select — see cards.md CARD-02 for full pattern */}
        </CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={channelChartConfig} className="min-h-[200px] w-full">
          <PieChart accessibilityLayer>
            <Pie data={channelData} dataKey="value" nameKey="channel" fill="var(--color-channel)" />
            <ChartTooltip content={<ChartTooltipContent />} />
          </PieChart>
        </ChartContainer>
      </CardContent>
    </Card>
  </div>

  {/* Related Table Card */}
  <Card>
    <CardHeader>
      <CardTitle>Ad Groups</CardTitle>
      <CardDescription>Linked ad groups for this campaign</CardDescription>
    </CardHeader>
    <CardContent>
      <DataTable columns={adGroupColumns} data={adGroups} onRowClick={(row) => navigate(`/ad-groups/${row.id}`)} emptyMessage="No ad groups found." />
    </CardContent>
  </Card>
</div>
```

// FORBIDDEN (절대 규칙):
// - Wrapping the page header in a Card -- page headers are plain divs
// - Using hardcoded hex/rgb in chart props -- define colors in chartConfig, reference as var(--color-KEY)
// - Using raw Recharts `<Tooltip>` or `contentStyle` -- use `<ChartTooltip content={<ChartTooltipContent />} />`
// - Passing stroke to CartesianGrid/XAxis/YAxis -- ChartContainer handles axis styling
//
// DEFAULT (기본값 -- 사용자 지시 시 변경 가능):
// - Section order: KPI -> Chart -> Table
// - Back button on detail pages
// - Badge placement in page header area

---

## PAGE-03 -- Form / Settings Page

Form pages wrap the form inside a Card. Default: back button + single Card.
Multiple sections = FieldSets inside one Card. 위저드/멀티스텝 또는 복수 독립 폼에서는 복수 Card 허용.

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"
import { Field, FieldLabel, FieldGroup, FieldSet, FieldLegend, FieldSeparator, FieldDescription } from "@/components/ui/field"
import { ArrowLeftIcon } from "lucide-react"

<div className="flex flex-col gap-4 p-4">
  {/* Page Header -- div, not Card. Back button required. */}
  <div className="flex items-center gap-4">
    <Button variant="ghost" size="icon" onClick={() => navigate("/campaigns")}>
      <ArrowLeftIcon className="h-4 w-4" />
    </Button>
    <h1 className="text-xl font-semibold">Create Campaign</h1>
  </div>

  {/* Single Card for entire form */}
  <Card>
    <CardHeader>
      <CardTitle>Campaign Details</CardTitle>
      <CardDescription>Fill in the details for your new campaign.</CardDescription>
    </CardHeader>
    <CardContent>
      <form id="campaign-form" onSubmit={handleSubmit}>
        <FieldGroup>
          <FieldSet>
            <FieldLegend>Basic Info</FieldLegend>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field>
                <FieldLabel>Campaign Name</FieldLabel>
                <Input name="name" placeholder="Enter campaign name" />
              </Field>
              <Field>
                <FieldLabel>Status</FieldLabel>
                <Select name="status">
                  <SelectTrigger>
                    <SelectValue placeholder="Select status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="active">Active</SelectItem>
                    <SelectItem value="draft">Draft</SelectItem>
                  </SelectContent>
                </Select>
              </Field>
            </div>
            <Field>
              <FieldLabel>Description</FieldLabel>
              <Textarea name="description" placeholder="Optional description" />
              <FieldDescription>This will be displayed in the campaign list.</FieldDescription>
            </Field>
          </FieldSet>

          <FieldSeparator />

          <FieldSet>
            <FieldLegend>Budget & Targeting</FieldLegend>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Field>
                <FieldLabel>Daily Budget</FieldLabel>
                <Input name="budget" type="number" placeholder="0" />
                <FieldDescription>Daily budget in USD.</FieldDescription>
              </Field>
              <Field>
                <FieldLabel>Region</FieldLabel>
                <Select name="region">
                  <SelectTrigger>
                    <SelectValue placeholder="Select region" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="us">United States</SelectItem>
                    <SelectItem value="eu">Europe</SelectItem>
                  </SelectContent>
                </Select>
              </Field>
            </div>
          </FieldSet>
        </FieldGroup>
      </form>
    </CardContent>
    <CardFooter className="border-t">
      <Button variant="outline" type="button" onClick={handleCancel}>Cancel</Button>
      <Button type="submit" form="campaign-form">Save</Button>
    </CardFooter>
  </Card>
</div>
```

// FORBIDDEN (절대 규칙):
// - Rendering a form without a Card wrapper -- Card provides visual boundary and footer placement
// - Using bare Input outside Field in form context -- Field provides label, description, and error
// - Omitting `form="form-id"` on the submit button -- links CardFooter button to form in CardContent
// - Placing submit/cancel buttons inside CardContent -- buttons belong in CardFooter
//
// DEFAULT (기본값 -- 사용자 지시 시 변경 가능):
// - Back button on form pages
// - Single Card per form (위저드/멀티스텝은 복수 Card 허용)
// - Button order: 보조(outline) → 주요(default)

---

## PAGE-04 -- Dashboard Overview Page

Dashboard pages show a high-level summary.
Default section order: KPI -> Chart -> Recent Table. Default chart grid: `lg:grid-cols-2`.

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardAction } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"
import { DataTable, KpiCard } from "@/components/composed"
import { formatCurrencyCompact, formatCompact, formatDelta } from "@/lib/format"

<div className="flex flex-col gap-4 p-4">
  {/* Page Header -- div, not Card */}
  <div className="flex items-center justify-between">
    <div>
      <h1 className="text-xl font-semibold">Dashboard</h1>
      <p className="text-sm text-muted-foreground">Overview of campaign performance</p>
    </div>
    <Button onClick={handleCreate}>New Campaign</Button>
  </div>

  {/* KPI Cards -- 4-column responsive grid */}
  <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
    {kpiItems.map((item) => (
      <KpiCard key={item.label} label={item.label} value={item.value} delta={item.delta} deltaPositive={item.deltaPositive} />
    ))}
  </div>

  {/* Chart Cards -- 2-column grid (MUST be lg:grid-cols-2 on dashboard) */}
  <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
    <Card>
      <CardHeader>
        <CardTitle>Daily Spend</CardTitle>
        <CardDescription>Last 30 days of ad spend</CardDescription>
        <CardAction>
          {/* Period Select — see cards.md CARD-02 for full pattern */}
        </CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={spendChartConfig} className="min-h-[200px] w-full">
          <LineChart accessibilityLayer data={spendData}>
            <CartesianGrid vertical={false} />
            <XAxis dataKey="month" tickLine={false} tickMargin={10} axisLine={false} />
            <YAxis tickLine={false} axisLine={false} />
            <ChartTooltip content={<ChartTooltipContent />} />
            <Line dataKey="spend" stroke="var(--color-spend)" />
          </LineChart>
        </ChartContainer>
      </CardContent>
    </Card>
    <Card>
      <CardHeader>
        <CardTitle>Channel Split</CardTitle>
        <CardDescription>Spend distribution by channel</CardDescription>
        <CardAction>
          {/* Period Select — see cards.md CARD-02 for full pattern */}
        </CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={channelChartConfig} className="min-h-[200px] w-full">
          <BarChart accessibilityLayer data={channelData}>
            <CartesianGrid vertical={false} />
            <XAxis dataKey="channel" tickLine={false} tickMargin={10} axisLine={false} />
            <YAxis tickLine={false} axisLine={false} />
            <ChartTooltip content={<ChartTooltipContent />} />
            <Bar dataKey="spend" fill="var(--color-spend)" radius={4} />
          </BarChart>
        </ChartContainer>
      </CardContent>
    </Card>
  </div>

  {/* Recent Activity Table Card */}
  <Card>
    <CardHeader>
      <CardTitle>Recent Campaigns</CardTitle>
      <CardDescription>Latest campaign activity</CardDescription>
    </CardHeader>
    <CardContent>
      <DataTable columns={columns} data={recentRows} onRowClick={(row) => navigate(`/campaigns/${row.id}`)} emptyMessage="No recent campaigns." />
    </CardContent>
  </Card>
</div>
```

// FORBIDDEN (절대 규칙):
// - Wrapping page header in a Card -- page headers are plain divs
// - Using hardcoded hex/rgb in chart props -- define colors in chartConfig, reference as var(--color-KEY)
// - Using raw Recharts `<Tooltip>` or `contentStyle` -- use `<ChartTooltip content={<ChartTooltipContent />} />`
// - Passing stroke to CartesianGrid/XAxis/YAxis -- ChartContainer handles axis styling
// - Using ChartContainer without Card wrapper -- charts live inside Card > CardContent
// - Omitting min-h-[VALUE] on ChartContainer -- required for responsive sizing
//
// DEFAULT (기본값 -- 사용자 지시 시 변경 가능):
// - Chart grid: lg:grid-cols-2 (단일 차트 full-width, 비대칭 레이아웃 허용)
// - KPI section first
// - Section order: KPI -> Chart -> Table

---

## Column Layout Reference

| Pattern | Grid Classes | Use |
|---------|-------------|-----|
| KPI 4-col | `grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4` | KPI card grid on dashboard and detail pages |
| Chart 2-col | `grid grid-cols-1 gap-4 lg:grid-cols-2` | Chart grid on dashboard (default) and detail pages |
| Chart asymmetric | `grid grid-cols-1 gap-4 lg:grid-cols-[2fr_1fr]` | Main chart + secondary chart |
| Form 2-col fields | `grid grid-cols-1 gap-4 sm:grid-cols-2` | Side-by-side fields inside FieldSet |
| Form 1-col | Single Card, full width | Standard form page |

// WHY: Consistent grid breakpoints (md for 2-col, lg for 4-col) create predictable responsive behavior across all page types.

---

## Cross-References

- Card patterns (KPI, Chart, Table, Form, Mixed): @.claude/rules/cards.md
- Field hierarchy and form structure: @.claude/rules/fields.md
- DataTable columns, props, and render functions: @.claude/rules/data-table.md
- Number/currency/percent formatting: @.claude/rules/formatting.md
- Token rules for colors, spacing, radius: @.claude/rules/tokens.md
