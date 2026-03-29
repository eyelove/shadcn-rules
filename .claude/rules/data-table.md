---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
  - "resources/js/**/*.tsx"
---

# DataTable Strategy

DataTable은 TanStack Table 기반 Composed component. 정렬, 필터, 페이지네이션, 행 선택을 내부 처리한다.
DataTable과 Table은 항상 `Card > CardContent` 안에 렌더링한다. Card wrapper는 페이지 파일에서 제공.

## TABLE-00 — 선택 기준

Data > 20 rows → **DataTable**. Sorting/filtering 필요 → **DataTable**. 둘 다 아니면 → **Table** (shadcn direct).

## TABLE-01 — Props Interface

```tsx
interface DataTableColumn<T> {
  accessorKey?: keyof T
  id?: string                                    // for checkbox, actions columns without data key
  header: string | (({ table }) => ReactNode)    // string or custom (checkbox header)
  sortable?: boolean                             // default: false
  pinned?: "left" | "right"                      // column pinning
  align?: "left" | "center" | "right"            // default: "left"
  cell?: (row: T) => React.ReactNode
  enableSorting?: boolean                        // false disables sorting (checkbox, actions)
}

interface DataTableProps<T> {
  columns: DataTableColumn<T>[]
  data: T[]
  onRowClick?: (row: T) => void
  onSelectionChange?: (rows: T[]) => void        // checkbox selection callback
  pageSize?: number                              // default: 10
  searchable?: boolean
  searchPlaceholder?: string
  emptyMessage?: string
}
```

## TABLE-02 — Standard Column Order

| Order | Role | Pinned | Sortable | Example |
|-------|------|--------|----------|---------|
| 1 | Checkbox selection | sticky (left) | No | Select all / individual |
| 2 | ID | sticky (left) | Yes | Campaign ID, AdGroup ID |
| 3 | Title (Name) | sticky (left) | Yes | Campaign name |
| 4+ | Attribute columns | No | Yes | Status, Channel, Period |
| Later | Metric columns (numbers) | No | Yes | Impressions, Clicks, CTR, CPA |
| Last | Actions | No | No | More menu (DropdownMenu) |

- Columns 1-3 pinned left — 수평 스크롤 시 고정
- Metric 컬럼: `tabular-nums text-right` alignment
- Actions 컬럼: 항상 마지막, 정렬 불가

## TABLE-03 — Built-in Features

| Feature | Location | Description |
|---------|----------|-------------|
| Sorting | Header click | `sortable: true`; `ArrowUpDown` 아이콘 항상 표시; 활성 시 `ArrowUp`/`ArrowDown`; asc→desc→none |
| Column pinning | `pinned: "left"` | Checkbox + ID + Title pinned, sticky on scroll |
| Pagination | DataTable bottom | `pageSize` 기반; prev/next + page info |
| Row selection | Checkbox column | Select all / individual; `onSelectionChange` callback |
| Header styling | `TableHeader` | `bg-muted` on header row |
| Cell Switch | cell function | Toggle switch (e.g., campaign active/pause) |

**Header styling:** `TableHeader > TableRow`에 `bg-muted`. 정렬 아이콘(`ArrowUpDown`, `ArrowUp`, `ArrowDown`)은 `lucide-react`에서 import.

## Column Definition Rules

컬럼 정의는 TABLE-02 순서 + TABLE-01 interface를 따른다.
- Metric 컬럼: `align: "right"`, cell에 `<span className="tabular-nums">{formatNumber/formatCurrency/formatPercent(value, { locale })}</span>`
- Status/Badge 컬럼: `<Badge variant="outline">{row.status}</Badge>`
- Actions 컬럼: `DropdownMenu` with `Button variant="ghost" size="icon"`, 삭제 항목은 `className="text-destructive"`
- Date 컬럼: cell에 `formatDate(row.date, { locale })` — 직접 `toLocaleDateString()` 또는 `date-fns format()` 사용 금지
- Switch 컬럼: `align: "center"`, `enableSorting: false`
- Format utilities: `formatNumber`, `formatCurrency`, `formatPercent`, `formatDate` from `@/lib/format` — 항상 explicit locale 전달

## Cell Styling Rules

cell 함수에서 `<span>`에 token 기반 Tailwind 클래스만 허용:
- 허용: `font-medium`, `text-foreground`, `text-muted-foreground`, `text-destructive`, `tabular-nums`
- 금지: hardcoded 색상 (`text-red-500`), inline style (`style={{ color: "..." }}`)

## Escape Hatch

DataTable/Table로 불가능한 요구(가상화, 트리 테이블, 편집 셀 등)는 구현 전 승인 요청. 승인 후 `@/components/composed/`에 typed props로 구현, className passthrough 금지.
