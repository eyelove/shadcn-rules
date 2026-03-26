"use client"

import { useRouter } from "next/navigation"
import { useState } from "react"

import {
  ActionButton,
  DataTable,
  PageHeader,
  PageLayout,
  SearchBar,
  StatusBadge,
} from "@/components/composed"

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface Campaign {
  id: string
  name: string
  status: "active" | "paused" | "ended" | "draft"
  budget: number
  spend: number
  ctr: number
  roas: number
}

// ---------------------------------------------------------------------------
// Filter configuration
// ---------------------------------------------------------------------------

const statusOptions = [
  { label: "All", value: "" },
  { label: "Active", value: "active" },
  { label: "Paused", value: "paused" },
  { label: "Ended", value: "ended" },
  { label: "Draft", value: "draft" },
]

const filters = [
  { type: "text" as const, key: "name", label: "Campaign Name" },
  {
    type: "select" as const,
    key: "status",
    label: "Status",
    options: statusOptions,
  },
  { type: "daterange" as const, key: "dateRange", label: "Date Range" },
]

// ---------------------------------------------------------------------------
// Column definitions
// ---------------------------------------------------------------------------

const currency = (value: number) =>
  new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value)

const percentage = (value: number) => `${value.toFixed(2)}%`

const columns = [
  {
    key: "name" as const,
    header: "Name",
    sortable: true,
  },
  {
    key: "status" as const,
    header: "Status",
    sortable: true,
    render: (value: Campaign["status"]) => <StatusBadge status={value} />,
  },
  {
    key: "budget" as const,
    header: "Budget",
    sortable: true,
    render: (value: Campaign["budget"]) => (
      <span className="font-medium text-foreground">{currency(value)}</span>
    ),
  },
  {
    key: "spend" as const,
    header: "Spend",
    sortable: true,
    render: (value: Campaign["spend"]) => (
      <span className="text-muted-foreground">{currency(value)}</span>
    ),
  },
  {
    key: "ctr" as const,
    header: "CTR",
    sortable: true,
    render: (value: Campaign["ctr"]) => (
      <span className="text-foreground">{percentage(value)}</span>
    ),
  },
  {
    key: "roas" as const,
    header: "ROAS",
    sortable: true,
    render: (value: Campaign["roas"]) => (
      <span className="font-semibold text-foreground">{value.toFixed(2)}x</span>
    ),
  },
]

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

const sampleCampaigns: Campaign[] = [
  { id: "1", name: "Spring Sale 2026", status: "active", budget: 50000, spend: 32400, ctr: 3.42, roas: 4.21 },
  { id: "2", name: "Brand Awareness Q1", status: "active", budget: 25000, spend: 18200, ctr: 1.87, roas: 2.15 },
  { id: "3", name: "Holiday Retargeting", status: "ended", budget: 40000, spend: 39800, ctr: 4.56, roas: 5.83 },
  { id: "4", name: "Product Launch — Series X", status: "paused", budget: 75000, spend: 12300, ctr: 2.91, roas: 1.44 },
  { id: "5", name: "Newsletter Signup", status: "draft", budget: 10000, spend: 0, ctr: 0, roas: 0 },
]

// ---------------------------------------------------------------------------
// Page Component
// ---------------------------------------------------------------------------

export default function CampaignListPage() {
  const router = useRouter()
  const [campaigns] = useState<Campaign[]>(sampleCampaigns)

  const handleSearch = (values: Record<string, unknown>) => {
    // TODO: wire up filtering / API call
    console.log("search", values)
  }

  const handleCreate = () => {
    router.push("/campaigns/new")
  }

  const handleRowClick = (row: Campaign) => {
    router.push(`/campaigns/${row.id}`)
  }

  return (
    <PageLayout>
      <PageHeader
        title="Campaigns"
        action={<ActionButton onClick={handleCreate}>New Campaign</ActionButton>}
      />

      <SearchBar filters={filters} onSearch={handleSearch} />

      <DataTable
        columns={columns}
        data={campaigns}
        onRowClick={handleRowClick}
        emptyMessage="No campaigns found. Create your first campaign to get started."
      />
    </PageLayout>
  )
}
