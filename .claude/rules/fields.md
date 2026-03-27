---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
  - "resources/js/**/*.tsx"
---

# Field Rules

Forms in dashboard pages use shadcn's Field component system directly inside Card wrappers.
No custom Form abstraction layer. react-hook-form integrates via Controller.

## Principles

1. **Use shadcn Field system directly.** Field, FieldLabel, FieldSet, FieldLegend, FieldGroup, FieldDescription, FieldError, FieldSeparator, FieldContent are all imported from `@/components/ui/field`. No custom FormField/FormFieldSet/FormActions wrappers.
// WHY: shadcn's Field components are accessible, composable, and well-documented. Wrapping them without adding logic creates indirection with no benefit.

2. **Card + Field combination.** Card provides the visual boundary for the entire form. FieldSet provides section grouping within. One form = one Card. Multiple sections = multiple FieldSets inside one Card, NOT multiple Cards.
// WHY: Card-per-section splitting fragments the form visually and breaks the single-form mental model. FieldSet + FieldSeparator handles sectioning within a Card.

3. **react-hook-form integrates via Controller directly.** No custom Form context wrapper. Controller renders Field components and wires up validation state via `data-invalid` and `aria-invalid`.
// WHY: Controller is react-hook-form's standard integration point. A custom wrapper adds API surface without adding capability.

## Field Component Hierarchy

```
Card
  └─ CardHeader (CardTitle + CardDescription)
  └─ CardContent
  │    └─ <form id="form-id">
  │         └─ FieldGroup
  │              └─ FieldSet
  │                   └─ FieldLegend
  │                   └─ Field
  │                        └─ FieldLabel
  │                        └─ Input | Select | Textarea | Checkbox
  │                        └─ FieldDescription
  │                        └─ FieldError
  └─ CardFooter (Cancel + Submit)
```

// WHY: CardFooter holds action buttons outside the scrollable form content area. The `form` attribute on Submit links it to the form in CardContent without nesting buttons inside the form element.

---

## FIELD-01 — Basic Form (Single Section)

Card > CardContent > form > FieldGroup > Field (FieldLabel + Input + FieldDescription).
CardFooter with Cancel (outline) + Save (submit), linked via form id.

```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card"
import { Field, FieldLabel, FieldGroup, FieldDescription } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Button } from "@/components/ui/button"

<Card>
  <CardHeader>
    <CardTitle>Create Campaign</CardTitle>
    <CardDescription>Fill in the details for your new campaign.</CardDescription>
  </CardHeader>
  <CardContent>
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
  </CardContent>
  <CardFooter className="border-t">
    <Button variant="outline" type="button" onClick={handleCancel}>Cancel</Button>
    <Button type="submit" form="campaign-form">Save</Button>
  </CardFooter>
</Card>
```

## FIELD-02 — Multi-Section Form (FieldSet Grouping)

Card > CardContent > form > FieldGroup > FieldSet (FieldLegend) + FieldSeparator + FieldSet.
One form = one Card. Sections divided by FieldSet, NOT by multiple Cards.

```tsx
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from "@/components/ui/card"
import { Field, FieldLabel, FieldGroup, FieldSet, FieldLegend, FieldSeparator, FieldDescription } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { Button } from "@/components/ui/button"

<Card>
  <CardHeader>
    <CardTitle>Campaign Settings</CardTitle>
  </CardHeader>
  <CardContent>
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
  </CardContent>
  <CardFooter className="border-t">
    <Button variant="outline" type="button" onClick={handleCancel}>Cancel</Button>
    <Button type="submit" form="settings-form">Save</Button>
  </CardFooter>
</Card>
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

```tsx
import { useForm, Controller } from "react-hook-form"
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from "@/components/ui/card"
import { Field, FieldLabel, FieldGroup, FieldError, FieldDescription } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"

function CampaignForm() {
  const { control, handleSubmit } = useForm({
    defaultValues: { name: "", budget: "" },
  })

  return (
    <Card>
      <CardHeader>
        <CardTitle>Create Campaign</CardTitle>
      </CardHeader>
      <CardContent>
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
      </CardContent>
      <CardFooter className="border-t">
        <Button variant="outline" type="button" onClick={handleCancel}>Cancel</Button>
        <Button type="submit" form="campaign-form">Save</Button>
      </CardFooter>
    </Card>
  )
}
```

// WHY: Controller is react-hook-form's standard render-prop integration. data-invalid on Field
// and aria-invalid on Input activate shadcn's built-in error styling without custom CSS.

## FIELD-05 — Checkbox/Switch Horizontal Layout

Use `orientation="horizontal"` on Field. Checkbox goes first, then FieldContent wraps
FieldLabel and FieldDescription side by side.

```tsx
import { Field, FieldLabel, FieldContent, FieldDescription } from "@/components/ui/field"
import { Checkbox } from "@/components/ui/checkbox"

<Field orientation="horizontal">
  <Checkbox name="notifications" />
  <FieldContent>
    <FieldLabel>Enable Notifications</FieldLabel>
    <FieldDescription>Receive email alerts when campaign status changes.</FieldDescription>
  </FieldContent>
</Field>
```

// WHY: orientation="horizontal" aligns the checkbox and label on the same row. FieldContent
// groups the label + description so they wrap together next to the control.

---

## CardFooter Button Rules

- Cancel (variant="outline", type="button") ALWAYS before Save (type="submit")
- Submit button uses `form="form-id"` attribute to link to the form in CardContent
- CardFooter gets `className="border-t"` for visual separation

```tsx
// CORRECT — Cancel before Save, form id linking
<CardFooter className="border-t">
  <Button variant="outline" type="button" onClick={onCancel}>Cancel</Button>
  <Button type="submit" form="campaign-form">Save</Button>
</CardFooter>

// FORBIDDEN — reversed order
<CardFooter className="border-t">
  <Button type="submit" form="campaign-form">Save</Button>
  <Button variant="outline" type="button" onClick={onCancel}>Cancel</Button>
</CardFooter>
```

// WHY: Dismissive action (Cancel) before primary action (Save) is a consistent pattern that
// prevents accidental submissions. form id linking keeps buttons outside the form element.

---

## Forbidden Patterns

### Card-less Form

NEVER render a form without a Card wrapper in dashboard pages.
// WHY: Card provides the visual boundary, header context, and footer button placement. Without it, forms float without structure.

```tsx
// FORBIDDEN — form without Card
<form onSubmit={handleSubmit}>
  <FieldGroup>
    <Field><FieldLabel>Name</FieldLabel><Input /></Field>
  </FieldGroup>
  <Button type="submit">Save</Button>
</form>

// CORRECT — form inside Card
<Card>
  <CardContent>
    <form id="my-form" onSubmit={handleSubmit}>
      <FieldGroup>
        <Field><FieldLabel>Name</FieldLabel><Input /></Field>
      </FieldGroup>
    </form>
  </CardContent>
  <CardFooter className="border-t">
    <Button type="submit" form="my-form">Save</Button>
  </CardFooter>
</Card>
```

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

### Card-per-Section Splitting

NEVER use multiple Cards to represent sections within a single form.
// WHY: Multiple Cards break the single-form model. Use FieldSet + FieldSeparator for sectioning within one Card.

```tsx
// FORBIDDEN — multiple Cards for form sections
<Card><CardHeader><CardTitle>Basic Info</CardTitle></CardHeader>
  <CardContent><Field>...</Field></CardContent></Card>
<Card><CardHeader><CardTitle>Targeting</CardTitle></CardHeader>
  <CardContent><Field>...</Field></CardContent></Card>

// CORRECT — one Card, multiple FieldSets
<Card>
  <CardHeader><CardTitle>Campaign Settings</CardTitle></CardHeader>
  <CardContent>
    <form id="settings-form">
      <FieldGroup>
        <FieldSet><FieldLegend>Basic Info</FieldLegend>...</FieldSet>
        <FieldSeparator />
        <FieldSet><FieldLegend>Targeting</FieldLegend>...</FieldSet>
      </FieldGroup>
    </form>
  </CardContent>
  <CardFooter className="border-t">...</CardFooter>
</Card>
```

### Submit Button Inside CardContent

NEVER place the submit button inside CardContent. It belongs in CardFooter.
// WHY: CardFooter provides consistent button placement at the bottom of the Card with border-t separation.

```tsx
// FORBIDDEN — submit inside CardContent
<CardContent>
  <form onSubmit={handleSubmit}>
    <FieldGroup>...</FieldGroup>
    <Button type="submit">Save</Button>
  </form>
</CardContent>

// CORRECT — submit in CardFooter with form id
<CardContent>
  <form id="my-form" onSubmit={handleSubmit}>
    <FieldGroup>...</FieldGroup>
  </form>
</CardContent>
<CardFooter className="border-t">
  <Button type="submit" form="my-form">Save</Button>
</CardFooter>
```

### Button Order Reversed

NEVER place Save before Cancel.

```tsx
// FORBIDDEN
<CardFooter className="border-t">
  <Button type="submit" form="my-form">Save</Button>
  <Button variant="outline" type="button">Cancel</Button>
</CardFooter>

// CORRECT
<CardFooter className="border-t">
  <Button variant="outline" type="button" onClick={onCancel}>Cancel</Button>
  <Button type="submit" form="my-form">Save</Button>
</CardFooter>
```

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
