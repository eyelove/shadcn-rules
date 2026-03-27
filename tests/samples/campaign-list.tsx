// Sample: List Page — PAGE-01
// Rewritten for the 2-tier rule system.
// Rules applied:
//   page-templates.md   PAGE-01 (div root, div page header, Card-wrapped DataTable)
//   cards.md            CARD-03b (DataTable + inline filter inside Card)
//   data-table.md       TABLE-02 column order, TABLE-05 full column example
//   formatting.md       formatNumber, formatCurrency, formatPercent from @/lib/format
//   components.md       2-tier: shadcn direct + Composed (DataTable only)
//   tokens.md           token-based classes only, no hardcoded colors

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
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
} from "@/components/ui/dropdown-menu"
import { MoreHorizontalIcon } from "lucide-react"
import { DataTable } from "@/components/composed"
import type { DataTableColumn } from "@/components/composed"
import { formatNumber, formatCurrency, formatPercent } from "@/lib/format"

// ── Locale / currency constants ──────────────────────────────────────────────
const LOCALE = "en-US" as const
const CURRENCY = "USD" as const

// ── Types ────────────────────────────────────────────────────────────────────
type Campaign = {
  id: string
  name: string
  status: "active" | "paused" | "ended" | "draft"
  channel: string
  impressions: number
  clicks: number
  ctr: number
  spend: number
  cpa: number
}

// ── Mock data (numeric values for metrics) ───────────────────────────────────
const mockCampaigns: Campaign[] = [
  { id: "CAM-001", name: "Summer Promo 2026", status: "active", channel: "Display", impressions: 120000, clicks: 3400, ctr: 0.0283, spend: 4320, cpa: 1.27 },
  { id: "CAM-002", name: "Brand Awareness Q2", status: "active", channel: "Search", impressions: 98000, clicks: 1800, ctr: 0.0184, spend: 2100, cpa: 1.17 },
  { id: "CAM-003", name: "Retargeting - Spring", status: "paused", channel: "Social", impressions: 75000, clicks: 2200, ctr: 0.0293, spend: 3800, cpa: 1.73 },
  { id: "CAM-004", name: "Product Launch - Model X", status: "ended", channel: "Display", impressions: 310000, clicks: 9100, ctr: 0.0294, spend: 15000, cpa: 1.65 },
  { id: "CAM-005", name: "Holiday Campaign 2025", status: "ended", channel: "Search", impressions: 280000, clicks: 7800, ctr: 0.0279, spend: 11450, cpa: 1.47 },
  { id: "CAM-006", name: "Influencer Collab - Spring", status: "draft", channel: "Social", impressions: 0, clicks: 0, ctr: 0, spend: 0, cpa: 0 },
  { id: "CAM-007", name: "Search - Brand Terms", status: "active", channel: "Search", impressions: 45000, clicks: 4500, ctr: 0.1, spend: 1200, cpa: 0.27 },
]

const statusOptions = [
  { label: "All", value: "" },
  { label: "Active", value: "active" },
  { label: "Paused", value: "paused" },
  { label: "Ended", value: "ended" },
  { label: "Draft", value: "draft" },
]

// ── Action handlers ──────────────────────────────────────────────────────────
function handleEdit(id: string) {
  console.log("Edit campaign:", id)
}

function handleDuplicate(id: string) {
  console.log("Duplicate campaign:", id)
}

function handleDelete(id: string) {
  console.log("Delete campaign:", id)
}

// ── Column definitions (TABLE-02 order) ──────────────────────────────────────
// Checkbox → ID → Name → Status → Channel → Impressions → Clicks → CTR → Spend → CPA → Actions
const columns: DataTableColumn<Campaign>[] = [
  // 1. Checkbox selection — pinned left, no sorting
  {
    id: "select",
    pinned: "left",
    enableSorting: false,
    header: ({ table }) => (
      <Checkbox
        checked={table.getIsAllPageRowsSelected()}
        onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
        aria-label="Select all"
      />
    ),
    cell: (row) => (
      <Checkbox
        checked={row.getIsSelected()}
        onCheckedChange={(value) => row.toggleSelected(!!value)}
        aria-label="Select row"
      />
    ),
  },

  // 2. ID — pinned left, sortable, muted text
  {
    accessorKey: "id",
    header: "ID",
    pinned: "left",
    sortable: true,
    cell: (row) => (
      <span className="font-medium text-muted-foreground">{row.id}</span>
    ),
  },

  // 3. Name — pinned left, sortable, foreground text
  {
    accessorKey: "name",
    header: "Campaign Name",
    pinned: "left",
    sortable: true,
    cell: (row) => (
      <span className="font-medium text-foreground">{row.name}</span>
    ),
  },

  // 4. Status — attribute, sortable, Badge variant="outline"
  {
    accessorKey: "status",
    header: "Status",
    sortable: true,
    cell: (row) => <Badge variant="outline">{row.status}</Badge>,
  },

  // 5. Channel — attribute, sortable, plain text
  {
    accessorKey: "channel",
    header: "Channel",
    sortable: true,
  },

  // 6. Impressions — metric, right-aligned, tabular-nums
  {
    accessorKey: "impressions",
    header: "Impressions",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatNumber(row.impressions, { locale: LOCALE })}</span>
    ),
  },

  // 7. Clicks — metric, right-aligned, tabular-nums
  {
    accessorKey: "clicks",
    header: "Clicks",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatNumber(row.clicks, { locale: LOCALE })}</span>
    ),
  },

  // 8. CTR — metric, right-aligned, tabular-nums, percentage
  {
    accessorKey: "ctr",
    header: "CTR",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatPercent(row.ctr, { locale: LOCALE })}</span>
    ),
  },

  // 9. Spend — metric, right-aligned, tabular-nums, currency, medium weight
  {
    accessorKey: "spend",
    header: "Spend",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums font-medium">{formatCurrency(row.spend, { locale: LOCALE, currency: CURRENCY })}</span>
    ),
  },

  // 10. CPA — metric, right-aligned, tabular-nums, currency
  {
    accessorKey: "cpa",
    header: "CPA",
    sortable: true,
    align: "right",
    cell: (row) => (
      <span className="tabular-nums">{formatCurrency(row.cpa, { locale: LOCALE, currency: CURRENCY })}</span>
    ),
  },

  // 11. Actions — last column, no sorting, dropdown menu
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
          <DropdownMenuItem onClick={() => handleEdit(row.id)}>Edit</DropdownMenuItem>
          <DropdownMenuItem onClick={() => handleDuplicate(row.id)}>Duplicate</DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem
            className="text-destructive"
            onClick={() => handleDelete(row.id)}
          >
            Delete
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  },
]

// ── Page Component ───────────────────────────────────────────────────────────
export default function CampaignListPage() {
  const handleCreate = () => {
    console.log("Create new campaign")
  }

  const handleExport = () => {
    console.log("Export campaigns")
  }

  const handleRowClick = (row: Campaign) => {
    console.log("Navigate to campaign:", row.id)
  }

  return (
    <div className="flex flex-col gap-6 p-6">
      {/* Page Header — div, not Card (PAGE-01) */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Campaigns</h1>
          <p className="text-sm text-muted-foreground">Manage your campaigns</p>
        </div>
        <Button onClick={handleCreate}>New Campaign</Button>
      </div>

      {/* Table Card — CARD-03b: DataTable + inline filter */}
      <Card>
        <CardHeader>
          <CardTitle>All Campaigns</CardTitle>
          <CardDescription>{mockCampaigns.length} campaigns</CardDescription>
          <CardAction>
            <Button variant="outline" size="sm" onClick={handleExport}>Export</Button>
          </CardAction>
        </CardHeader>
        <CardContent>
          {/* Inline filter toolbar (CARD-03b) */}
          <div className="flex items-center gap-2 pb-4">
            <Input placeholder="Filter by name..." className="max-w-sm" />
            <Select>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                {statusOptions.map((opt) => (
                  <SelectItem key={opt.value || "all"} value={opt.value || "all"}>
                    {opt.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <DataTable
            columns={columns}
            data={mockCampaigns}
            onRowClick={handleRowClick}
            pageSize={20}
            emptyMessage="No campaigns found."
          />
        </CardContent>
      </Card>
    </div>
  )
}
