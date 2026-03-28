---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
  - "resources/js/**/*.tsx"
---

# Field Rules

Forms in dashboard pages use shadcn's Field component system. Card 래핑은 @.claude/rules/cards.md CARD-04를 따른다.
No custom Form abstraction layer. react-hook-form integrates via Controller.

## Principles

1. **Use shadcn Field system directly.** Field, FieldLabel, FieldSet, FieldLegend, FieldGroup, FieldDescription, FieldError, FieldSeparator, FieldContent are all imported from `@/components/ui/field`. No custom FormField/FormFieldSet/FormActions wrappers.
// WHY: shadcn's Field components are accessible, composable, and well-documented. Wrapping them without adding logic creates indirection with no benefit.

2. **Card + Field combination.** Card provides the visual boundary for the entire form. FieldSet provides section grouping within. One form = one Card. Multiple sections = multiple FieldSets inside one Card, NOT multiple Cards. Card 래핑 규칙: @.claude/rules/cards.md CARD-04.

3. **react-hook-form integrates via Controller directly.** No custom Form context wrapper. Controller renders Field components and wires up validation state via `data-invalid` and `aria-invalid`.
// WHY: Controller is react-hook-form's standard integration point. A custom wrapper adds API surface without adding capability.

## Field Component Hierarchy

Card 래핑(CardHeader → CardContent → CardFooter)은 @.claude/rules/cards.md CARD-04를 따른다.
이 파일은 `<form>` 내부 구조만 다룬다.

```
<form id="form-id">
  └─ FieldGroup
       └─ FieldSet
            └─ FieldLegend
            └─ Field
                 └─ FieldLabel
                 └─ Input | Select | Combobox | Textarea | Checkbox | DatePicker(Popover+Calendar)
                 └─ FieldDescription
                 └─ FieldError
```

---

## Common Imports

폼 패턴에서 공통으로 사용하는 import. 각 FIELD 예제에서는 해당 패턴 고유 import만 표시한다.

```tsx
import { Field, FieldLabel, FieldGroup, FieldSet, FieldLegend, FieldSeparator, FieldDescription, FieldError, FieldContent } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"
import { Button } from "@/components/ui/button"
```

---

## FIELD-01 — Basic Form (Single Section)

form > FieldGroup > Field (FieldLabel + Input + FieldDescription).
Card 래핑과 CardFooter: @.claude/rules/cards.md CARD-04

```tsx
<form id="campaign-form" onSubmit={handleSubmit}>
  <FieldGroup>
    <Field>
      <FieldLabel>Campaign Name</FieldLabel>
      <Input name="name" placeholder="Enter campaign name" />
      <FieldDescription>This will be displayed in the campaign list.</FieldDescription>
    </Field>
    <Field>
      <FieldLabel>Description</FieldLabel>
      <Textarea name="description" placeholder="Optional description" />
    </Field>
  </FieldGroup>
</form>
```

## FIELD-02 — Multi-Section Form (FieldSet Grouping)

form > FieldGroup > FieldSet (FieldLegend) + FieldSeparator + FieldSet.
Card 래핑: @.claude/rules/cards.md CARD-04

`<form>` 내부만 표시. Card 래핑: @.claude/rules/cards.md CARD-04

```tsx
<form id="settings-form" onSubmit={handleSubmit}>
  <FieldGroup>
    <FieldSet>
      <FieldLegend>Basic Info</FieldLegend>
      <Field>
        <FieldLabel>Campaign Name</FieldLabel>
        <Input name="name" />
      </Field>
      <Field>
        <FieldLabel>Description</FieldLabel>
        <Textarea name="description" />
      </Field>
    </FieldSet>

    <FieldSeparator />

    <FieldSet>
      <FieldLegend>Targeting</FieldLegend>
      <Field>
        <FieldLabel>Region</FieldLabel>
        <Select name="region">
          <SelectTrigger><SelectValue placeholder="Select region" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="us">United States</SelectItem>
            <SelectItem value="eu">Europe</SelectItem>
          </SelectContent>
        </Select>
      </Field>
      <Field>
        <FieldLabel>Budget</FieldLabel>
        <Input name="budget" type="number" />
        <FieldDescription>Daily budget in USD.</FieldDescription>
      </Field>
    </FieldSet>
  </FieldGroup>
</form>
```

## FIELD-03 — 2-Column Field Layout

Inside FieldSet, use a grid div to place Fields side by side. Can mix with full-width Fields.

```tsx
<FieldSet>
  <FieldLegend>Contact Details</FieldLegend>
  <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
    <Field>
      <FieldLabel>First Name</FieldLabel>
      <Input name="firstName" />
    </Field>
    <Field>
      <FieldLabel>Last Name</FieldLabel>
      <Input name="lastName" />
    </Field>
  </div>
  <Field>
    <FieldLabel>Email</FieldLabel>
    <Input name="email" type="email" />
    <FieldDescription>We will use this for notifications.</FieldDescription>
  </Field>
</FieldSet>
```

// WHY: The grid div is the minimal layout primitive needed for 2-column fields. FieldSet does not
// provide a cols prop — this is the canonical pattern for side-by-side fields.

## FIELD-04 — react-hook-form + Controller

Controller renders Field components. Use `data-invalid` on Field and `aria-invalid` on Input
to wire up validation state. FieldError receives the error via its `errors` prop.

Card 래핑: @.claude/rules/cards.md CARD-04. 고유 import: `import { useForm, Controller } from "react-hook-form"`

```tsx
function CampaignForm() {
  const { control, handleSubmit } = useForm({
    defaultValues: { name: "", budget: "" },
  })

  return (
    <form id="campaign-form" onSubmit={handleSubmit(onSubmit)}>
      <FieldGroup>
        <Controller
          control={control}
          name="name"
          rules={{ required: "Campaign name is required" }}
          render={({ field, fieldState }) => (
            <Field data-invalid={fieldState.invalid || undefined}>
              <FieldLabel>Campaign Name</FieldLabel>
              <Input {...field} aria-invalid={fieldState.invalid || undefined} />
              <FieldDescription>Unique identifier for this campaign.</FieldDescription>
              <FieldError errors={fieldState.error ? [fieldState.error] : undefined} />
            </Field>
          )}
        />
        <Controller
          control={control}
          name="budget"
          rules={{ required: "Budget is required", min: { value: 1, message: "Must be at least $1" } }}
          render={({ field, fieldState }) => (
            <Field data-invalid={fieldState.invalid || undefined}>
              <FieldLabel>Daily Budget</FieldLabel>
              <Input {...field} type="number" aria-invalid={fieldState.invalid || undefined} />
              <FieldError errors={fieldState.error ? [fieldState.error] : undefined} />
            </Field>
          )}
        />
      </FieldGroup>
    </form>
  )
}
```

// WHY: Controller is react-hook-form's standard render-prop integration. data-invalid on Field
// and aria-invalid on Input activate shadcn's built-in error styling without custom CSS.

## FIELD-05 — Checkbox/Switch Horizontal Layout

Use `orientation="horizontal"` on Field. Checkbox goes first, then FieldContent wraps
FieldLabel and FieldDescription side by side.

고유 import: `Checkbox` from `@/components/ui/checkbox`, `Switch` from `@/components/ui/switch`

```tsx
// Checkbox — discrete on/off (e.g., agree to terms, multi-select options)
<Field orientation="horizontal">
  <Checkbox name="notifications" />
  <FieldContent>
    <FieldLabel>Enable Notifications</FieldLabel>
    <FieldDescription>Receive email alerts when campaign status changes.</FieldDescription>
  </FieldContent>
</Field>

// Switch — toggle with immediate effect (e.g., enable/disable a feature)
<Field orientation="horizontal">
  <Switch name="autoOptimize" />
  <FieldContent>
    <FieldLabel>Auto Optimize</FieldLabel>
    <FieldDescription>Automatically adjust bids based on performance.</FieldDescription>
  </FieldContent>
</Field>
```

// WHY: orientation="horizontal" aligns the control and label on the same row. FieldContent
// groups the label + description so they wrap together next to the control.
// Checkbox = form submission용 선택, Switch = 즉시 반영되는 토글. 용도에 맞게 선택한다.

## FIELD-06 — Date Picker Field

폼 필드에서 날짜를 입력받을 때 Popover + Calendar을 조합한다.
트리거 버튼은 `variant="outline"`으로 선택된 날짜 또는 placeholder를 표시한다.

고유 import: `Calendar` from `@/components/ui/calendar`, `Popover/PopoverTrigger/PopoverContent` from `@/components/ui/popover`, `CalendarIcon` from `lucide-react`, `formatDate` from `@/lib/format`

```tsx
<Field>
  <FieldLabel>Start Date</FieldLabel>
  <Popover>
    <PopoverTrigger asChild>
      <Button
        variant="outline"
        className="w-full justify-start text-left font-normal"
        data-empty={!date || undefined}
      >
        <CalendarIcon className="mr-2 h-4 w-4" />
        {date ? formatDate(date, { locale: "ko-KR" }) : <span className="text-muted-foreground">날짜 선택</span>}
      </Button>
    </PopoverTrigger>
    <PopoverContent className="w-auto p-0" align="start">
      <Calendar mode="single" selected={date} onSelect={setDate} initialFocus />
    </PopoverContent>
  </Popover>
  <FieldDescription>Campaign start date.</FieldDescription>
</Field>
```

**Rules:**
- 트리거는 `Button variant="outline"` — Input이 아님
- `data-empty` 속성으로 placeholder 스타일링 (`data-[empty]:text-muted-foreground`)
- `PopoverContent`에 `className="w-auto p-0"`, `align="start"`
- `Calendar`에 `initialFocus`로 popover 열릴 때 키보드 포커스 이동
- `formatDate` from `@/lib/format`으로 날짜 표시 — `date-fns` 직접 사용 금지 (@.claude/rules/formatting.md FMT-04)

// WHY: Popover + Calendar 조합이 shadcn의 공식 Date Picker 패턴이다.
// 대시보드에서 Calendar 인라인은 사용하지 않는다 — 공간 효율을 위해 항상 Popover 안에 넣는다.

## FIELD-07 — Combobox Field

옵션이 많거나(10개 이상) 서버에서 Ajax로 로드하는 경우 Combobox를 사용한다.
옵션이 ~10개 이하 고정 목록이면 Select를 사용한다 (@.claude/rules/components.md SELECT-01).

고유 import: `Combobox/ComboboxInput/ComboboxContent/ComboboxList/ComboboxItem/ComboboxEmpty` from `@/components/ui/combobox`

```tsx
const campaigns = [
  { value: "camp-1", label: "Summer Sale 2026" },
  { value: "camp-2", label: "Brand Awareness Q1" },
  // ... 수십~수백 개
]

<Field>
  <FieldLabel>Campaign</FieldLabel>
  <Combobox
    items={campaigns}
    value={selectedCampaign}
    onValueChange={setSelectedCampaign}
    itemToStringValue={(item) => item.label}
  >
    <ComboboxInput placeholder="Search campaigns..." />
    <ComboboxContent>
      <ComboboxList>
        {(item) => <ComboboxItem>{item.label}</ComboboxItem>}
      </ComboboxList>
      <ComboboxEmpty>No campaigns found.</ComboboxEmpty>
    </ComboboxContent>
  </Combobox>
  <FieldDescription>Select the target campaign.</FieldDescription>
</Field>
```

**Ajax 로드 패턴:**
```tsx
// Combobox의 onValueChange에서 debounce + fetch 후 items 갱신
const [query, setQuery] = useState("")
const [items, setItems] = useState([])

useEffect(() => {
  const timer = setTimeout(() => {
    fetch(`/api/campaigns?q=${query}`).then(res => res.json()).then(setItems)
  }, 300)
  return () => clearTimeout(timer)
}, [query])

<Combobox items={items} onValueChange={setSelectedCampaign}>
  <ComboboxInput placeholder="Search campaigns..." value={query} onChange={(e) => setQuery(e.target.value)} />
  {/* ... */}
</Combobox>
```

**Rules:**
- 필터 바에서 사용할 때는 Field 래핑 불필요 (fields.md Exception 참고)
- 폼 필드에서 사용할 때는 반드시 Field > FieldLabel 안에 배치
- shadcn 공식 문서에 async 패턴은 없음 — debounce + fetch로 직접 구현

// WHY: Select는 검색 기능이 없어 옵션이 많으면 사용 불가능하다.
// Combobox는 타이핑 즉시 필터링하므로 대량 목록에서도 빠르게 찾을 수 있다.

---

## CardFooter Button Rules

CardFooter 버튼 규칙: @.claude/rules/cards.md CARD-04

---

## Forbidden Patterns

Card 래핑 관련 금지 패턴(Card-less Form, Submit Button 위치, Card-per-Section): @.claude/rules/cards.md CARD-04

### FieldLabel-less Input

NEVER place an Input inside Field without a FieldLabel.
// WHY: FieldLabel provides the accessible label association. Without it, the input has no label for screen readers or visual context.

```tsx
// FORBIDDEN — Input without FieldLabel
<Field>
  <Input placeholder="Campaign name" />
</Field>

// CORRECT
<Field>
  <FieldLabel>Campaign Name</FieldLabel>
  <Input placeholder="Campaign name" />
</Field>
```

### Bare Input Outside Field

NEVER use Input, Select, Textarea, or Checkbox outside a Field wrapper in form contexts.
// WHY: Field provides label association, description, error display, and validation state. Bare inputs skip all of this.

```tsx
// FORBIDDEN — bare Input
<CardContent>
  <Input placeholder="Campaign name" />
</CardContent>

// CORRECT
<CardContent>
  <form id="my-form">
    <FieldGroup>
      <Field>
        <FieldLabel>Campaign Name</FieldLabel>
        <Input placeholder="Campaign name" />
      </Field>
    </FieldGroup>
  </form>
</CardContent>
```

### Button Variant 미구분

주요 액션과 보조 액션은 반드시 variant로 시각적으로 구분해야 한다.
// WHY: 주요 액션은 시각적으로 구분되어야 사용자가 결과를 예측할 수 있다.
CardFooter 버튼 예제: @.claude/rules/cards.md CARD-04

---

## Exception

**Search/filter toolbar Inputs above DataTable do NOT need Field wrapping.** These are toolbar controls, not form fields. See @.claude/rules/cards.md CARD-03b for the toolbar pattern.

## Escape Hatch

If a form element is genuinely not coverable by the Field system (e.g., custom file uploader, rich text editor):
1. STOP -- do not use raw `<input>` or `<div>` layout
2. Describe the needed element and ask for approval
3. After approval, wrap it inside a Field so FieldLabel, FieldDescription, and FieldError still apply
4. If Field wrapping is structurally impossible, create a Composed component (see @.claude/rules/components.md Escape Hatch)

For Card wrapper patterns, see: @.claude/rules/cards.md
For token rules, see: @.claude/rules/tokens.md
For forbidden patterns, see: @.claude/rules/forbidden.md
