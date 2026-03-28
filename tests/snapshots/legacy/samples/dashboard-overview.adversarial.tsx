// Adversarial sample: Dashboard Overview with intentional rule violations
// Expected violations: FORB-01, FORB-02, FORB-03, FMT-01, FMT-02, TOKEN-01

import { DataTable, KpiCard } from "@/components/composed"
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from "recharts"

// Mock data

const kpiItems = [
  { label: "Total Spend", value: "$42,800", delta: "+18%" },
  { label: "Impressions", value: "1,240,000", delta: "+23%" },
  { label: "Clicks", value: "38,400", delta: "+11%" },
  { label: "CTR", value: "3.09%", delta: "-0.2%" },
]

const dailySpendData = [
  { date: "Mar 1", spend: 1200 },
  { date: "Mar 8", spend: 1450 },
  { date: "Mar 15", spend: 1600 },
  { date: "Mar 22", spend: 1350 },
  { date: "Mar 29", spend: 1800 },
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
  status: string
  spend: number
  ctr: number
}

const recentCampaigns: RecentCampaign[] = [
  { id: "1", name: "Summer Promo", status: "active", spend: 4320, ctr: 0.0283 },
  { id: "2", name: "Brand Q2", status: "active", spend: 2100, ctr: 0.0184 },
  { id: "3", name: "Retargeting", status: "paused", spend: 3800, ctr: 0.0293 },
  { id: "4", name: "Product Launch", status: "ended", spend: 15000, ctr: 0.0294 },
  { id: "5", name: "Influencer", status: "draft", spend: 0, ctr: 0 },
]

const columns = [
  { accessorKey: "name", header: "Campaign", sortable: true },
  { accessorKey: "status", header: "Status", sortable: true },
  {
    accessorKey: "spend",
    header: "Spend",
    sortable: true,
    align: "right" as const,
    // VIOLATION FMT-02: hardcoded currency symbol
    cell: (row: RecentCampaign) => (
      <span className="tabular-nums">${row.spend.toLocaleString()}</span>
    ),
  },
  {
    accessorKey: "ctr",
    header: "CTR",
    sortable: true,
    align: "right" as const,
    // VIOLATION FMT-01: inline toLocaleString formatting
    cell: (row: RecentCampaign) => (
      <span className="tabular-nums">
        {(row.ctr * 100).toLocaleString("en-US", { maximumFractionDigits: 2 })}%
      </span>
    ),
  },
]

export default function DashboardOverviewPage() {
  return (
    // VIOLATION FORB-01: inline style
    <div style={{ padding: "24px", display: "flex", flexDirection: "column" as const, gap: "24px" }}>
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Dashboard</h1>
          <p className="text-sm text-muted-foreground">Overview of campaign performance</p>
        </div>
        <button className="bg-blue-600 text-white px-4 py-2 rounded-lg">New Campaign</button>
      </div>

      {/* KPI Cards — VIOLATION FORB-03: raw div as card substitute */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
        {kpiItems.map((item) => (
          // VIOLATION FORB-02: hardcoded hex color, FORB-03: div as card, TOKEN-01: rounded-lg
          <div
            key={item.label}
            className="rounded-lg border p-4"
            style={{ backgroundColor: "#f8f9fa", borderColor: "#e9ecef" }}
          >
            <p className="text-sm text-gray-500">{item.label}</p>
            <p className="text-2xl font-semibold">{item.value}</p>
            <p className="text-sm text-gray-400">{item.delta}</p>
          </div>
        ))}
      </div>

      {/* Charts — VIOLATION FORB-02: hardcoded hex in chart props, FORB-03: div as card */}
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="rounded-lg border bg-white p-4">
          <h3 className="font-semibold mb-4">Daily Spend</h3>
          <LineChart width={500} height={300} data={dailySpendData}>
            <CartesianGrid stroke="#e5e7eb" strokeDasharray="3 3" />
            <XAxis dataKey="date" stroke="#6b7280" />
            <YAxis stroke="#6b7280" />
            <Tooltip contentStyle={{ backgroundColor: "#fff", borderColor: "#e5e7eb" }} />
            <Line type="monotone" dataKey="spend" stroke="#8884d8" strokeWidth={2} />
          </LineChart>
        </div>

        <div className="rounded-lg border bg-white p-4">
          <h3 className="font-semibold mb-4">Channel Split</h3>
          <BarChart width={500} height={300} data={channelSplitData}>
            <CartesianGrid stroke="#e5e7eb" strokeDasharray="3 3" />
            <XAxis dataKey="channel" stroke="#6b7280" />
            <YAxis stroke="#6b7280" />
            <Tooltip contentStyle={{ backgroundColor: "#fff", borderColor: "#e5e7eb" }} />
            <Bar dataKey="spend" fill="#82ca9d" />
          </BarChart>
        </div>
      </div>

      {/* Recent Table — VIOLATION FORB-03: div as card */}
      <div className="rounded-lg border bg-white p-4">
        <h3 className="font-semibold mb-4">Recent Campaigns</h3>
        <DataTable columns={columns} data={recentCampaigns} emptyMessage="No campaigns." />
      </div>
    </div>
  )
}
