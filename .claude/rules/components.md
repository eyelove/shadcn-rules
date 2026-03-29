---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
  - "resources/js/**/*.tsx"
---
# Component Rules

## Tier Model
| Tier | Import Path | What Lives Here | Examples |
|------|------------|-----------------|----------|
| **shadcn** | `@/components/ui/*` | Official shadcn/ui primitives | Card, Button, Badge, Input, Select, Dialog, Tabs |
| **Composed** | `@/components/composed/` | Internal state, domain logic, or 3+ repeated patterns | DataTable, SearchBar, KpiCard |

## Import Convention — shadcn direct
```tsx
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Checkbox } from "@/components/ui/checkbox"
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"
import { Table, TableHeader, TableRow, TableHead, TableBody, TableCell } from "@/components/ui/table"
import { Dialog, DialogTrigger, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog"
import { AlertDialog, AlertDialogTrigger, AlertDialogContent, AlertDialogHeader, AlertDialogTitle, AlertDialogDescription, AlertDialogFooter, AlertDialogAction, AlertDialogCancel } from "@/components/ui/alert-dialog"
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs"
import { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuItem } from "@/components/ui/dropdown-menu"
import { Separator } from "@/components/ui/separator"
import { Label } from "@/components/ui/label"
import { Popover, PopoverTrigger, PopoverContent } from "@/components/ui/popover"
import { Calendar } from "@/components/ui/calendar"
import { Combobox, ComboboxInput, ComboboxContent, ComboboxList, ComboboxItem, ComboboxEmpty } from "@/components/ui/combobox"
import { Switch } from "@/components/ui/switch"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
```

Composed — barrel import: `import { DataTable, SearchBar, KpiCard } from "@/components/composed"`
All Composed components MUST be exported from `@/components/composed/index.ts`.

## Composed Qualification

Composed ONLY if at least one: (1) manages own state callers should not handle, (2) combines primitives encoding domain rules, (3) same arrangement repeats 3+ times across pages.

| Component | Role | Internal Logic |
|-----------|------|---------------|
| **DataTable** | Sortable, paginated, clickable data table | Sort state, pagination, column visibility, empty/loading state |
| **SearchBar** | Configurable filter bar | Filter state, debounced search, config-driven field rendering |
| **KpiCard** | Metric card with label, value, delta | Delta formatting, positive/negative color via tokens |

### SearchBar Props Interface
```tsx
interface SearchBarProps {
  filters: SearchBarFilter[]
  onSearch: (values: Record<string, unknown>) => void
}
type SearchBarFilter = TextFilter | SelectFilter | ComboboxFilter | DateRangeFilter
{ type: "text", name: "search", placeholder: "캠페인 검색..." }
{ type: "select", name: "status", placeholder: "상태", options: [{ value: "active", label: "활성" }] }
{ type: "combobox", name: "channel", placeholder: "채널 선택", items: [{ value: "google", label: "Google Ads" }] }
{ type: "dateRange", name: "period", placeholder: "기간 선택" }
```
Usage (Card > CardContent, above DataTable):
```tsx
<SearchBar filters={[
  { type: "text", name: "search", placeholder: "캠페인 검색..." },
  { type: "combobox", name: "channel", placeholder: "채널 선택", items: channels },
  { type: "dateRange", name: "period", placeholder: "기간 선택" },
  { type: "select", name: "status", placeholder: "상태", options: statusOptions },
]} onSearch={handleSearch} />
<DataTable columns={columns} data={filteredRows} />
```

## Primitive Sources — PRIM-01

`shadcn init --preset nova`는 Radix + Base UI 하이브리드. 컴포넌트별 primitive 소스가 다르므로 controlled state API가 다르다.

| Component | Primitive | "미선택" 값 | onValueChange 시그니처 |
|-----------|-----------|-----------|----------------------|
| **Select** | `radix-ui` | `undefined` | `(value: string) => void` |
| **Combobox** | `@base-ui/react` | `null` | `(value: string \| null, eventDetails) => void` |
| **Popover, Dialog, Checkbox, Switch, RadioGroup** | `radix-ui` | — | — |
| **Calendar** | `react-day-picker` | — | — |

```tsx
// Select (Radix) — undefined이 placeholder 트리거
<Select value={selected ?? undefined} onValueChange={setSelected}>

// Combobox (Base UI) — null이 미선택 상태
<Combobox value={selected ?? null} onValueChange={(v) => setSelected(v)}>
```

**금지:** Select에 `value=""` (placeholder 미표시), Combobox에 `value={undefined}` (uncontrolled로 전환)

## Input Component Selection — SELECT-01
| 기준 | Select | Combobox |
|------|--------|----------|
| 옵션 수 | ~10개 이하, 고정 목록 | 10개 이상 또는 동적/Ajax |
| 검색 | 없음 | 타이핑 즉시 필터링 |
| 다중 선택 | 미지원 | `multiple` prop 지원 |
| 대시보드 사용처 | 상태 필터, 차트 기간, 카테고리 | 캠페인 선택, 광고주 검색, 매체 선택 |

Native `<select>` 사용 금지 — 토큰 시스템 적용 불가.

### DATE-01 — Date Picker
대시보드에서 Calendar 인라인 금지. 항상 Popover 안에 넣는다.
| 시나리오 | 구성 | 배치 위치 |
|---------|------|---------|
| 폼 날짜 입력 | `Popover` + `Calendar mode="single"` | Field |
| 차트/리포트 기간 필터 | `Popover` + `Select`(프리셋) + `Calendar mode="range"` | CardAction |

### RADIO-01 — RadioGroup vs Select vs Choice Card
| 기준 | RadioGroup | Choice Card | Select |
|------|-----------|-------------|--------|
| 옵션 수 | 2~5개 | 2~5개 | ~10개 이하 |
| 옵션 설명 | 불필요 | 제목+설명 필요 | 불필요 |
| 대시보드 사용처 | 캠페인 목표, 입찰 전략 | 요금제, 캠페인 유형 | 상태, 지역, 기간 |

## Escape Hatch
New Composed component 필요 시: Qualification 기준 충족 확인 → 승인 요청 후 생성. `className` prop 금지.
