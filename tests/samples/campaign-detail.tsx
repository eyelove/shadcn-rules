"use client"

import {
  PageLayout,
  PageHeader,
  StatusBadge,
  KpiCardGroup,
  ChartSection,
  DataTable,
} from "@/components/composed"
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts"

// --- Mock Data ---

const dailyPerformance = [
  { date: "Mar 01", impressions: 12400, clicks: 310, spend: 420 },
  { date: "Mar 02", impressions: 13100, clicks: 345, spend: 455 },
  { date: "Mar 03", impressions: 11800, clicks: 290, spend: 390 },
  { date: "Mar 04", impressions: 14500, clicks: 402, spend: 510 },
  { date: "Mar 05", impressions: 15200, clicks: 438, spend: 540 },
  { date: "Mar 06", impressions: 13900, clicks: 365, spend: 470 },
  { date: "Mar 07", impressions: 16000, clicks: 480, spend: 600 },
]

interface AdGroup {
  id: string
  name: string
  status: string
  impressions: number
  clicks: number
  ctr: string
  spend: string
}

const adGroups: AdGroup[] = [
  { id: "ag-1", name: "Brand Awareness - Desktop", status: "active", impressions: 45200, clicks: 1230, ctr: "2.72%", spend: "$1,840" },
  { id: "ag-2", name: "Retargeting - Mobile", status: "active", impressions: 32100, clicks: 980, ctr: "3.05%", spend: "$1,420" },
  { id: "ag-3", name: "Lookalike - All Devices", status: "paused", impressions: 18400, clicks: 420, ctr: "2.28%", spend: "$780" },
  { id: "ag-4", name: "Contextual - Video", status: "active", impressions: 11200, clicks: 310, ctr: "2.77%", spend: "$645" },
]

const adGroupColumns = [
  { key: "name" as const, header: "Ad Group", sortable: true },
  {
    key: "status" as const,
    header: "Status",
    render: (value: AdGroup[keyof AdGroup]) => (
      <StatusBadge status={value as string} />
    ),
  },
  { key: "impressions" as const, header: "Impressions", sortable: true },
  { key: "clicks" as const, header: "Clicks", sortable: true },
  { key: "ctr" as const, header: "CTR", sortable: true },
  { key: "spend" as const, header: "Spend", sortable: true },
]

// --- Chart Component ---

function DailyPerformanceChart() {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={dailyPerformance}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="date" />
        <YAxis yAxisId="left" />
        <YAxis yAxisId="right" orientation="right" />
        <Tooltip />
        <Line
          yAxisId="left"
          type="monotone"
          dataKey="impressions"
          stroke="var(--chart-1)"
          strokeWidth={2}
        />
        <Line
          yAxisId="left"
          type="monotone"
          dataKey="clicks"
          stroke="var(--chart-2)"
          strokeWidth={2}
        />
        <Line
          yAxisId="right"
          type="monotone"
          dataKey="spend"
          stroke="var(--chart-3)"
          strokeWidth={2}
        />
      </LineChart>
    </ResponsiveContainer>
  )
}

// --- Page Component ---

export default function CampaignDetailPage() {
  const kpiItems = [
    {
      label: "Impressions",
      value: "106,900",
      delta: "+12.4%",
      deltaPositive: true,
    },
    {
      label: "Clicks",
      value: "2,940",
      delta: "+8.1%",
      deltaPositive: true,
    },
    {
      label: "CTR",
      value: "2.75%",
      delta: "+0.3%",
      deltaPositive: true,
    },
    {
      label: "Spend",
      value: "$4,685",
      delta: "-2.1%",
      deltaPositive: false,
    },
  ]

  return (
    <PageLayout>
      <PageHeader
        title="Campaign Detail"
        backHref="/campaigns"
        action={<StatusBadge status="active" />}
      />

      <KpiCardGroup cols={4} items={kpiItems} />

      <ChartSection
        cols={1}
        charts={[
          {
            title: "Daily Performance",
            chart: <DailyPerformanceChart />,
          },
        ]}
      />

      <DataTable<AdGroup>
        columns={adGroupColumns}
        data={adGroups}
        onRowClick={(row) => console.log("Navigate to ad group:", row.id)}
        emptyMessage="No ad groups found for this campaign."
      />
    </PageLayout>
  )
}
