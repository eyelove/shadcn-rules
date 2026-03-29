import * as React from "react"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select"
import {
  Combobox,
  ComboboxInput,
  ComboboxContent,
  ComboboxList,
  ComboboxItem,
  ComboboxEmpty,
} from "@/components/ui/combobox"
import {
  Popover,
  PopoverTrigger,
  PopoverContent,
} from "@/components/ui/popover"
import { Calendar } from "@/components/ui/calendar"
import { Button } from "@/components/ui/button"
import { CalendarIcon, SearchIcon } from "lucide-react"
import { formatDate } from "@/lib/format"
import type { DateRange } from "react-day-picker"

interface SearchBarFilterBase {
  name: string
  placeholder?: string
}

interface TextFilter extends SearchBarFilterBase {
  type: "text"
}

interface SelectFilter extends SearchBarFilterBase {
  type: "select"
  options: { value: string; label: string }[]
}

interface ComboboxFilter extends SearchBarFilterBase {
  type: "combobox"
  items: { value: string; label: string }[]
}

interface DateRangeFilter extends SearchBarFilterBase {
  type: "dateRange"
}

type SearchBarFilter = TextFilter | SelectFilter | ComboboxFilter | DateRangeFilter

interface SearchBarProps {
  filters: SearchBarFilter[]
  onSearch: (values: Record<string, unknown>) => void
}

export function SearchBar({ filters, onSearch }: SearchBarProps) {
  const [values, setValues] = React.useState<Record<string, unknown>>({})
  const debounceRef = React.useRef<ReturnType<typeof setTimeout>>(null)

  const updateValue = (name: string, value: unknown) => {
    const next = { ...values, [name]: value }
    setValues(next)
    onSearch(next)
  }

  const updateValueDebounced = (name: string, value: unknown) => {
    const next = { ...values, [name]: value }
    setValues(next)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => onSearch(next), 300)
  }

  return (
    <div className="flex items-center gap-2 pb-4">
      {filters.map((filter) => {
        switch (filter.type) {
          case "text":
            return (
              <div key={filter.name} className="relative">
                <SearchIcon className="absolute left-2.5 top-2.5 size-4 text-muted-foreground" />
                <Input
                  placeholder={filter.placeholder}
                  value={(values[filter.name] as string) ?? ""}
                  onChange={(e) =>
                    updateValueDebounced(filter.name, e.target.value)
                  }
                  className="pl-8"
                />
              </div>
            )

          case "select":
            return (
              <Select
                key={filter.name}
                value={(values[filter.name] as string) ?? undefined}
                onValueChange={(v) => updateValue(filter.name, v)}
              >
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder={filter.placeholder} />
                </SelectTrigger>
                <SelectContent>
                  {filter.options.map((opt) => (
                    <SelectItem key={opt.value} value={opt.value}>
                      {opt.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            )

          case "combobox":
            return (
              <Combobox
                key={filter.name}
                value={(values[filter.name] as string) ?? null}
                onValueChange={(v) => updateValue(filter.name, v)}
              >
                <ComboboxInput placeholder={filter.placeholder} />
                <ComboboxContent>
                  <ComboboxList>
                    {filter.items.map((item) => (
                      <ComboboxItem key={item.value} value={item.value}>
                        {item.label}
                      </ComboboxItem>
                    ))}
                  </ComboboxList>
                  <ComboboxEmpty>검색 결과가 없습니다.</ComboboxEmpty>
                </ComboboxContent>
              </Combobox>
            )

          case "dateRange": {
            const dateRange = values[filter.name] as DateRange | undefined
            return (
              <Popover key={filter.name}>
                <PopoverTrigger asChild>
                  <Button
                    variant="outline"
                    className="w-[260px] justify-start text-left font-normal"
                    data-empty={!dateRange?.from || undefined}
                  >
                    <CalendarIcon className="mr-2 h-4 w-4" />
                    {dateRange?.from ? (
                      dateRange.to ? (
                        <>
                          {formatDate(dateRange.from, { locale: "ko-KR" })} -{" "}
                          {formatDate(dateRange.to, { locale: "ko-KR" })}
                        </>
                      ) : (
                        formatDate(dateRange.from, { locale: "ko-KR" })
                      )
                    ) : (
                      <span className="text-muted-foreground">
                        {filter.placeholder ?? "기간 선택"}
                      </span>
                    )}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    mode="range"
                    selected={dateRange}
                    onSelect={(range) => updateValue(filter.name, range)}
                    numberOfMonths={2}
                    initialFocus
                  />
                </PopoverContent>
              </Popover>
            )
          }

          default:
            return null
        }
      })}
    </div>
  )
}
