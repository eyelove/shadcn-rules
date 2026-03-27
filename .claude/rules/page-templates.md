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

| Rule | Description |
|------|------------|
| Root wrapper | `div.flex.flex-col.gap-4.p-4` -- all pages (spacing defaults: @tokens.md) |
| Page header | NOT a Card -- `div` with `h1` + `p` + action Button |
| Section order (dashboard) | KPI -> Chart -> Table (fixed) |
| Section order (detail) | KPI -> Chart -> Related Table (fixed) |
| Form page | Back button required, one Card per form |
| Chart grid | Dashboard MUST use `lg:grid-cols-2` |

// WHY: Fixed section ordering creates a predictable scan pattern across all page types. Users always
// know where to find KPIs (top), charts (middle), and tables (bottom).

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

// FORBIDDEN:
// - Adding KpiCard or ChartSection to a list page -- KPIs and charts belong on Dashboard/Detail pages
// - Wrapping the page header in a Card -- page headers are plain divs
// - Placing filter inputs outside the Card -- filters are part of the table's context
// - Using DataTable without a Card wrapper -- see @.claude/rules/cards.md CARD-03b
// - Omitting CardHeader on the table Card -- every Card needs at least a CardTitle

---

## PAGE-02 -- Detail Page

Detail pages show a single entity with KPI summary, charts, and a related data table.
Section order is fixed: KPI -> Chart -> Table.

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardAction } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { ChartContainer } from "@/components/ui/chart"
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
          <Select>...</Select>
        </CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={spendChartConfig}>
          <LineChart data={spendData}>
            <CartesianGrid stroke="var(--border)" />
            <XAxis stroke="var(--muted-foreground)" />
            <YAxis stroke="var(--muted-foreground)" />
            <Tooltip contentStyle={{ backgroundColor: "var(--card)", borderColor: "var(--border)", color: "var(--card-foreground)" }} />
            <Line stroke="var(--chart-1)" />
          </LineChart>
        </ChartContainer>
      </CardContent>
    </Card>
    <Card>
      <CardHeader>
        <CardTitle>Channel Split</CardTitle>
        <CardAction>
          <Select>...</Select>
        </CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={channelChartConfig}>
          <PieChart>
            <Pie data={channelData} fill="var(--chart-2)" />
            <Tooltip contentStyle={{ backgroundColor: "var(--card)", borderColor: "var(--border)", color: "var(--card-foreground)" }} />
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

// FORBIDDEN:
// - Placing DataTable before ChartSection or KPI cards -- section order is KPI -> Chart -> Table
// - Omitting the back button on detail pages -- users must be able to navigate back
// - Wrapping the page header in a Card -- page headers are plain divs
// - Placing Badge outside the page header area -- status belongs in the header
// - Using hardcoded hex/rgb in chart props -- use `var(--chart-N)` tokens
// - Using TabGroup to wrap sections -- flat KPI -> Chart -> Table sequence only

---

## PAGE-03 -- Form / Settings Page

Form pages use a single Card to wrap the entire form. Back button is required.
One form = one Card. Multiple sections = multiple FieldSets inside one Card, NOT multiple Cards.

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

// FORBIDDEN:
// - Omitting the back button on form pages -- users must be able to navigate back
// - Using multiple Cards for form sections -- one form = one Card; use FieldSet + FieldSeparator
// - Placing submit/cancel buttons inside CardContent -- buttons belong in CardFooter
// - Placing Save before Cancel -- Cancel (outline) always precedes Save (submit)
// - Rendering a form without a Card wrapper -- Card provides visual boundary and footer placement
// - Using bare Input outside Field in form context -- Field provides label, description, and error
// - Omitting `form="campaign-form"` on the submit button -- links CardFooter button to form in CardContent

---

## PAGE-04 -- Dashboard Overview Page

Dashboard pages show a high-level summary. Section order is fixed: KPI -> Chart -> Recent Table.
Chart grid MUST use `lg:grid-cols-2` on dashboards.

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardAction } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ChartContainer } from "@/components/ui/chart"
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
          <Select>...</Select>
        </CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={spendChartConfig}>
          <LineChart data={spendData}>
            <CartesianGrid stroke="var(--border)" />
            <XAxis stroke="var(--muted-foreground)" />
            <YAxis stroke="var(--muted-foreground)" />
            <Tooltip contentStyle={{ backgroundColor: "var(--card)", borderColor: "var(--border)", color: "var(--card-foreground)" }} />
            <Line stroke="var(--chart-1)" />
          </LineChart>
        </ChartContainer>
      </CardContent>
    </Card>
    <Card>
      <CardHeader>
        <CardTitle>Channel Split</CardTitle>
        <CardDescription>Spend distribution by channel</CardDescription>
        <CardAction>
          <Select>...</Select>
        </CardAction>
      </CardHeader>
      <CardContent>
        <ChartContainer config={channelChartConfig}>
          <BarChart data={channelData}>
            <CartesianGrid stroke="var(--border)" />
            <XAxis stroke="var(--muted-foreground)" />
            <YAxis stroke="var(--muted-foreground)" />
            <Tooltip contentStyle={{ backgroundColor: "var(--card)", borderColor: "var(--border)", color: "var(--card-foreground)" }} />
            <Bar fill="var(--chart-2)" />
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

// FORBIDDEN:
// - Using `lg:grid-cols-1` for charts on a dashboard -- dashboard charts MUST be 2-column
// - Omitting KpiCard section -- dashboards always show KPI summary first
// - Placing DataTable before chart section -- section order is KPI -> Chart -> Table
// - Wrapping page header in a Card -- page headers are plain divs
// - Using hardcoded hex/rgb in chart props -- use `var(--chart-N)` tokens
// - Using ChartContainer without Card wrapper -- charts live inside Card > CardContent

---

## Column Layout Reference

| Pattern | Grid Classes | Use |
|---------|-------------|-----|
| KPI 4-col | `grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4` | KPI card grid on dashboard and detail pages |
| Chart 2-col | `grid grid-cols-1 gap-4 lg:grid-cols-2` | Chart grid on dashboard (required) and detail pages |
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
