---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
  - "resources/js/**/*.tsx"
---

# Field Rules

## Principles

1. **shadcn Field 직접 사용.** `@/components/ui/field`에서 import. 커스텀 FormField 래퍼 금지.
2. **Card + Field 조합.** 1 form = 1 Card. 복수 섹션 = 1 Card 안에 복수 FieldSet.
3. **react-hook-form은 Controller로 통합.** 커스텀 Form context 래퍼 금지. `data-invalid` + `aria-invalid`로 validation 연결.

## Field Component Hierarchy

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

## Common Imports

```tsx
import { Field, FieldLabel, FieldGroup, FieldSet, FieldLegend, FieldSeparator, FieldDescription, FieldError, FieldContent, FieldTitle } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"
import { Button } from "@/components/ui/button"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
```

## FIELD Patterns

**FIELD-01 — Basic Form:** `form > FieldGroup > Field(FieldLabel + Input + FieldDescription)`. 단일 섹션 폼.

**FIELD-02 — Multi-Section:** `FieldGroup > FieldSet(FieldLegend) + FieldSeparator + FieldSet`로 섹션 구분.

**FIELD-03 — 2-Column:** FieldSet 내 `<div className="grid grid-cols-1 gap-4 sm:grid-cols-2">`로 Field 배치. full-width Field와 혼합 가능.

**FIELD-04 — react-hook-form Controller:** `data-invalid`(Field) + `aria-invalid`(Input) + `FieldError errors` 연결 패턴. 최소 예제:

```tsx
<Controller
  control={control}
  name="name"
  rules={{ required: "Required" }}
  render={({ field, fieldState }) => (
    <Field data-invalid={fieldState.invalid || undefined}>
      <FieldLabel>Name</FieldLabel>
      <Input {...field} aria-invalid={fieldState.invalid || undefined} />
      <FieldError errors={fieldState.error ? [fieldState.error] : undefined} />
    </Field>
  )}
/>
```

**FIELD-05 — Checkbox/Switch:** `Field orientation="horizontal"` + Checkbox/Switch + `FieldContent(FieldLabel + FieldDescription)`. Checkbox = 폼 선택, Switch = 즉시 토글.

**FIELD-06 — Date Picker:** `Popover + Calendar(mode="single")` 조합. 트리거는 `Button variant="outline"`. `formatDate`로 날짜 표시. `PopoverContent className="w-auto p-0" align="start"`, `Calendar initialFocus`.

**FIELD-07 — Combobox:** 10개 이상 옵션 또는 Ajax 로드 시 사용. `Combobox > ComboboxInput + ComboboxContent > ComboboxList + ComboboxEmpty`. 10개 이하 고정 목록은 Select.

**FIELD-08 — RadioGroup:** 2~5개 상호 배타적 옵션. 각 아이템은 `div.flex.items-center.gap-2 > RadioGroupItem + FieldLabel(htmlFor, font-normal)`.

**FIELD-09 — Choice Card:** 옵션에 제목+설명이 필요할 때. 각 아이템: `FieldLabel(htmlFor) > Field(orientation="horizontal") > FieldContent(FieldTitle + FieldDescription) + RadioGroupItem`. 단순 라벨이면 FIELD-08.

## CardFooter Button Rules

- CardFooter에 `className="gap-2"` 필수 (shadcn 기본 gap 없음)
- 보조 액션은 `variant="outline"`, 주요 액션은 default variant
- `<form>`에 `id` 부여, submit 버튼은 `form="form-id"`로 CardFooter에서 연결

## Exception

DataTable 위 검색/필터 toolbar의 Input은 Field 래핑 불필요.

## Escape Hatch

Field로 커버 불가한 폼 요소(파일 업로더, 리치 텍스트 등)는 구현 전 승인 요청. 승인 후 가능하면 Field 안에 래핑하여 FieldLabel/FieldDescription/FieldError 유지.
