"use client"

import {
  PageLayout,
  PageHeader,
  KpiCardGroup,
  ChartSection,
  DataTable,
  StatusBadge,
  ActionButton,
} from "@/components/composed"
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts"

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

const kpiItems = [
  {
    label: "Total Campaigns",
    value: 142,
    delta: "+8%",
    deltaPositive: true,
  },
  {
    label: "Active Users",
    value: "12,847",
    delta: "+23%",
    deltaPositive: true,
  },
  {
    label: "Avg. CTR",
    value: "3.42%",
    delta: "-0.4%",
    deltaPositive: false,
  },
  {
    label: "Monthly Spend",
    value: "$84,320",
    delta: "+12%",
    deltaPositive: true,
  },
]

const dailySpendData = [
  { day: "Mon", spend: 12400, impressions: 84000 },
  { day: "Tue", spend: 13800, impressions: 91000 },
  { day: "Wed", spend: 11200, impressions: 78000 },
  { day: "Thu", spend: 15600, impressions: 102000 },
  { day: "Fri", spend: 14200, impressions: 96000 },
  { day: "Sat", spend: 9800, impressions: 64000 },
  { day: "Sun", spend: 10400, impressions: 71000 },
]

const channelDistribution = [
  { name: "Display", value: 35 },
  { name: "Social", value: 28 },
  { name: "Search", value: 22 },
  { name: "Video", value: 15 },
]

const CHART_COLORS = [
  "var(--chart-1)",
  "var(--chart-2)",
  "var(--chart-3)",
  "var(--chart-4)",
]

interface Campaign {
  id: string
  name: string
  status: string
  spend: string
  impressions: string
  ctr: string
}

const recentCampaigns: Campaign[] = [
  {
    id: "c-001",
    name: "Spring Launch 2026",
    status: "active",
    spend: "$12,400",
    impressions: "1.2M",
    ctr: "4.2%",
  },
  {
    id: "c-002",
    name: "Brand Awareness Q1",
    status: "active",
    spend: "$8,750",
    impressions: "890K",
    ctr: "3.1%",
  },
  {
    id: "c-003",
    name: "Holiday Retargeting",
    status: "ended",
    spend: "$22,100",
    impressions: "2.4M",
    ctr: "5.6%",
  },
  {
    id: "c-004",
    name: "Product Launch Beta",
    status: "draft",
    spend: "$0",
    impressions: "—",
    ctr: "—",
  },
  {
    id: "c-005",
    name: "Summer Promo Early",
    status: "paused",
    spend: "$3,200",
    impressions: "310K",
    ctr: "2.8%",
  },
]

const campaignColumns = [
  { key: "name" as const, header: "Campaign", sortable: true },
  {
    key: "status" as const,
    header: "Status",
    sortable: true,
    render: (value: Campaign[keyof Campaign]) => (
      <StatusBadge status={value as string} />
    ),
  },
  { key: "spend" as const, header: "Spend", sortable: true },
  { key: "impressions" as const, header: "Impressions", sortable: true },
  { key: "ctr" as const, header: "CTR", sortable: true },
]

// ---------------------------------------------------------------------------
// Chart components (rendered inside ChartSection)
// ---------------------------------------------------------------------------

function SpendLineChart() {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={dailySpendData}>
        <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
        <XAxis
          dataKey="day"
          stroke="var(--muted-foreground)"
          fontSize={12}
        />
        <YAxis stroke="var(--muted-foreground)" fontSize={12} />
        <Tooltip
          contentStyle={{
            backgroundColor: "var(--card)",
            borderColor: "var(--border)",
            color: "var(--card-foreground)",
          }}
        />
        <Line
          type="monotone"
          dataKey="spend"
          stroke="var(--chart-1)"
          strokeWidth={2}
          dot={false}
          name="Spend ($)"
        />
        <Line
          type="monotone"
          dataKey="impressions"
          stroke="var(--chart-2)"
          strokeWidth={2}
          dot={false}
          name="Impressions"
        />
      </LineChart>
    </ResponsiveContainer>
  )
}

function ChannelDonutChart() {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <PieChart>
        <Pie
          data={channelDistribution}
          cx="50%"
          cy="50%"
          innerRadius={70}
          outerRadius={110}
          paddingAngle={4}
          dataKey="value"
          nameKey="name"
          label={({ name, percent }) =>
            `${name} ${(percent * 100).toFixed(0)}%`
          }
        >
          {channelDistribution.map((_, index) => (
            <Cell
              key={`cell-${index}`}
              fill={CHART_COLORS[index % CHART_COLORS.length]}
            />
          ))}
        </Pie>
        <Tooltip
          contentStyle={{
            backgroundColor: "var(--card)",
            borderColor: "var(--border)",
            color: "var(--card-foreground)",
          }}
        />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  )
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

export default function DashboardOverview() {
  return (
    <PageLayout>
      <PageHeader
        title="Dashboard"
        subtitle="Overview of campaign performance"
        action={<ActionButton onClick={() => {}}>New Campaign</ActionButton>}
      />

      <KpiCardGroup cols={4} items={kpiItems} />

      <ChartSection
        cols={2}
        charts={[
          { title: "Daily Spend & Impressions", chart: <SpendLineChart /> },
          { title: "Channel Distribution", chart: <ChannelDonutChart /> },
        ]}
      />

      <DataTable<Campaign>
        columns={campaignColumns}
        data={recentCampaigns}
        onRowClick={(row) => console.log(`Navigate to /campaigns/${row.id}`)}
        emptyMessage="No campaigns found."
      />
    </PageLayout>
  )
}
