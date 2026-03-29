import * as React from "react"
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  getPaginationRowModel,
  flexRender,
  type ColumnDef,
  type SortingState,
} from "@tanstack/react-table"
import {
  Table,
  TableHeader,
  TableRow,
  TableHead,
  TableBody,
  TableCell,
} from "@/components/ui/table"
import { Button } from "@/components/ui/button"

interface DataTableColumn<T> {
  accessorKey?: keyof T & string
  id?: string
  header: string | (({ table }: { table: any }) => React.ReactNode)
  sortable?: boolean
  pinned?: "left" | "right"
  align?: "left" | "center" | "right"
  cell?: (row: T) => React.ReactNode
  enableSorting?: boolean
}

interface DataTableProps<T> {
  columns: DataTableColumn<T>[]
  data: T[]
  onRowClick?: (row: T) => void
  onSelectionChange?: (rows: T[]) => void
  pageSize?: number
  searchable?: boolean
  searchPlaceholder?: string
  emptyMessage?: string
}

export function DataTable<T extends Record<string, any>>({
  columns,
  data,
  onRowClick,
  pageSize = 10,
  emptyMessage = "No data found.",
}: DataTableProps<T>) {
  const [sorting, setSorting] = React.useState<SortingState>([])

  const tanstackColumns: ColumnDef<T, any>[] = React.useMemo(
    () =>
      columns.map((col) => ({
        id: col.id ?? col.accessorKey ?? "",
        accessorKey: col.accessorKey,
        header: typeof col.header === "string" ? col.header : ({ table }: any) => (col.header as Function)({ table }),
        cell: col.cell
          ? ({ row }: any) => col.cell!(row.original)
          : undefined,
        enableSorting: col.enableSorting !== false && col.sortable !== false,
        meta: { align: col.align },
      })),
    [columns]
  )

  const table = useReactTable({
    data,
    columns: tanstackColumns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    initialState: { pagination: { pageSize } },
  })

  return (
    <div className="space-y-4">
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((headerGroup) => (
            <TableRow key={headerGroup.id}>
              {headerGroup.headers.map((header) => (
                <TableHead
                  key={header.id}
                  className={
                    (header.column.columnDef.meta as any)?.align === "right"
                      ? "text-right"
                      : undefined
                  }
                  onClick={header.column.getCanSort() ? header.column.getToggleSortingHandler() : undefined}
                >
                  {header.isPlaceholder
                    ? null
                    : flexRender(header.column.columnDef.header, header.getContext())}
                  {header.column.getIsSorted() === "asc" && " \u2191"}
                  {header.column.getIsSorted() === "desc" && " \u2193"}
                </TableHead>
              ))}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows.length === 0 ? (
            <TableRow>
              <TableCell colSpan={columns.length} className="text-center text-muted-foreground">
                {emptyMessage}
              </TableCell>
            </TableRow>
          ) : (
            table.getRowModel().rows.map((row) => (
              <TableRow
                key={row.id}
                onClick={onRowClick ? () => onRowClick(row.original) : undefined}
                className={onRowClick ? "cursor-pointer" : undefined}
              >
                {row.getVisibleCells().map((cell) => (
                  <TableCell
                    key={cell.id}
                    className={
                      (cell.column.columnDef.meta as any)?.align === "right"
                        ? "text-right"
                        : undefined
                    }
                  >
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </TableCell>
                ))}
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>

      {table.getPageCount() > 1 && (
        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <span>
            Page {table.getState().pagination.pageIndex + 1} of {table.getPageCount()}
          </span>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => table.previousPage()}
              disabled={!table.getCanPreviousPage()}
            >
              Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => table.nextPage()}
              disabled={!table.getCanNextPage()}
            >
              Next
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}
