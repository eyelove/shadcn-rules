// Sample: Dashboard Overview Page — PAGE-04
// Rewritten for 2-tier rule system.
// Rules applied: page-templates.md (PAGE-04), cards.md (CARD-01, CARD-02, CARD-03),
//                data-table.md, formatting.md, tokens.md, components.md

import {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardAction,
} from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select"
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart"
import { DataTable, KpiCard } from "@/components/composed"
import {
  formatCurrencyCompact,
  formatCompact,
  formatDelta,
  formatCurrency,
  formatNumber,
  formatPercent,
} from "@/lib/format"
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
} from "recharts"
import type { ChartConfig } from "@/components/ui/chart"

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

const kpiItems = [
  {
    label: "Total Spend",
    value: formatCurrencyCompact(42800, { locale: "en-US", currency: "USD" }),
    delta: formatDelta(0.18),
    deltaPositive: true,
    footerText: "vs. previous 30 days",
  },
  {
    label: "Total Impressions",
    value: formatCompact(1240000, { locale: "en-US" }),
    delta: formatDelta(0.23),
    deltaPositive: true,
    footerText: "vs. previous 30 days",
  },
  {
    label: "Total Clicks",
    value: formatCompact(38400, { locale: "en-US" }),
    delta: formatDelta(0.11),
    deltaPositive: true,
    footerText: "vs. previous 30 days",
  },
  {
    label: "Avg CTR",
    value: formatPercent(0.0309, { locale: "en-US" }),
    delta: formatDelta(-0.002),
    deltaPositive: false,
    footerText: "vs. previous 30 days",
  },
]

const dailySpendData = [
  { date: "Mar 1", spend: 1200 },
  { date: "Mar 8", spend: 1450 },
  { date: "Mar 15", spend: 1600 },
  { date: "Mar 22", spend: 1350 },
  { date: "Mar 29", spend: 1800 },
  { date: "Apr 5", spend: 2100 },
  { date: "Apr 12", spend: 1950 },
]

const channelSplitData = [
  { channel: "Search", spend: 18200 },
  { channel: "Display", spend: 9400 },
  { channel: "Social", spend: 11600 },
  { channel: "Video", spend: 3600 },
]

type RecentCampaign = {
  id: string
  name: string
  status: "active" | "paused" | "ended" | "draft"
  spend: number
  impressions: number
  ctr: number
}

const recentCampaigns: RecentCampaign[] = [
  { id: "1", name: "Summer Promo 2026", status: "active", spend: 4320, impressions: 120000, ctr: 0.0283 },
  { id: "2", name: "Brand Awareness Q2", status: "active", spend: 2100, impressions: 98000, ctr: 0.0184 },
  { id: "3", name: "Retargeting - Spring", status: "paused", spend: 3800, impressions: 75000, ctr: 0.0293 },
  { id: "4", name: "Product Launch - Model X", status: "ended", spend: 15000, impressions: 310000, ctr: 0.0294 },
  { id: "5", name: "Influencer Collab - Spring", status: "draft", spend: 0, impressions: 0, ctr: 0 },
]

// ---------------------------------------------------------------------------
// Chart configs (shadcn chart)
// ---------------------------------------------------------------------------

const spendChartConfig = {
  spend: { label: "Spend", color: "var(--chart-1)" },
} satisfies ChartConfig

const channelChartConfig = {
  spend: { label: "Spend", color: "var(--chart-2)" },
} satisfies ChartConfig

// ---------------------------------------------------------------------------
// Column definitions (data-table.md TABLE-02 order)
// ---------------------------------------------------------------------------

const columns: DataTableColumn<RecentCampaign>[] = [
  {
    accessorKey: "name",
    header: "Campaign",
    sortable: true,
    cell: (row) => (
      <span className="font-medium text-foreground">{row.name}</span>
    ),
  },
  {
    accessorKey: "status",
    header: "Status",
    sortable: true,
    cell: (row) => <Badge variant="outline">{row.status}</Badge>,
  },
  {
    accessorKey: "spend",
    header: "Spend",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums font-medium">
        {formatCurrency(row.spend, { locale: "en-US", currency: "USD" })}
      </span>
    ),
  },
  {
    accessorKey: "impressions",
    header: "Impressions",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">
        {formatNumber(row.impressions, { locale: "en-US" })}
      </span>
    ),
  },
  {
    accessorKey: "ctr",
    header: "CTR",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">
        {formatPercent(row.ctr, { locale: "en-US" })}
      </span>
    ),
  },
]

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------

export default function DashboardOverviewPage() {
  const handleRowClick = (row: RecentCampaign) => {
    console.log("Navigate to campaign:", row.id)
  }

  const handleNewCampaign = () => {
    console.log("Create new campaign")
  }

  return (
    <div className="flex flex-col gap-6 p-6">
      {/* Page Header -- div, not Card */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Dashboard</h1>
          <p className="text-sm text-muted-foreground">
            Overview of campaign performance
          </p>
        </div>
        <Button onClick={handleNewCampaign}>New Campaign</Button>
      </div>

      {/* KPI Cards -- CARD-01, 4-column responsive grid */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
        {kpiItems.map((item) => (
          <KpiCard
            key={item.label}
            label={item.label}
            value={item.value}
            delta={item.delta}
            deltaPositive={item.deltaPositive}
          />
        ))}
      </div>

      {/* Chart Cards -- CARD-02, 2-column grid (MUST be lg:grid-cols-2 on dashboard) */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Daily Spend</CardTitle>
            <CardDescription>Last 30 days of ad spend</CardDescription>
            <CardAction>
              <Select>
                <SelectTrigger className="w-[120px]">
                  <SelectValue placeholder="30 days" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="7d">7 days</SelectItem>
                  <SelectItem value="30d">30 days</SelectItem>
                  <SelectItem value="90d">90 days</SelectItem>
                </SelectContent>
              </Select>
            </CardAction>
          </CardHeader>
          <CardContent>
            <ChartContainer config={spendChartConfig}>
              <LineChart data={dailySpendData}>
                <CartesianGrid stroke="var(--border)" strokeDasharray="3 3" />
                <XAxis
                  dataKey="date"
                  stroke="var(--muted-foreground)"
                  tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                />
                <YAxis
                  stroke="var(--muted-foreground)"
                  tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Line
                  type="monotone"
                  dataKey="spend"
                  stroke="var(--chart-1)"
                  strokeWidth={2}
                  dot={false}
                />
              </LineChart>
            </ChartContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Channel Split</CardTitle>
            <CardDescription>Spend distribution by channel</CardDescription>
            <CardAction>
              <Select>
                <SelectTrigger className="w-[120px]">
                  <SelectValue placeholder="Spend" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="spend">Spend</SelectItem>
                  <SelectItem value="impressions">Impressions</SelectItem>
                </SelectContent>
              </Select>
            </CardAction>
          </CardHeader>
          <CardContent>
            <ChartContainer config={channelChartConfig}>
              <BarChart data={channelSplitData}>
                <CartesianGrid stroke="var(--border)" strokeDasharray="3 3" />
                <XAxis
                  dataKey="channel"
                  stroke="var(--muted-foreground)"
                  tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                />
                <YAxis
                  stroke="var(--muted-foreground)"
                  tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
                />
                <ChartTooltip content={<ChartTooltipContent />} />
                <Bar dataKey="spend" fill="var(--chart-2)" />
              </BarChart>
            </ChartContainer>
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity Table -- CARD-03, Card-wrapped DataTable */}
      <Card>
        <CardHeader>
          <CardTitle>Recent Campaigns</CardTitle>
          <CardDescription>Latest campaign activity</CardDescription>
        </CardHeader>
        <CardContent>
          <DataTable
            columns={columns}
            data={recentCampaigns}
            onRowClick={handleRowClick}
            emptyMessage="No recent campaigns."
          />
        </CardContent>
      </Card>
    </div>
  )
}
