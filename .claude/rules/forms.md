---
paths:
  - "src/**/*.tsx"
  - "app/**/*.tsx"
  - "components/**/*.tsx"
---

# Form Rules

Forms MUST use the Composed component hierarchy. Never build form layout with raw HTML elements or inline styles.

## FORM-01 — Required Form Structure

All forms MUST follow this hierarchy:

```
PageLayout
  └─ PageHeader (with backHref for edit/create pages)
  └─ <form onSubmit={handleSubmit}>
       └─ FormFieldSet (legend="Group Name")  ← one per logical group
            └─ FormRow (cols={2})             ← for side-by-side fields
                 └─ FormField (label, required?, description?)
                      └─ Input | Select | Textarea | Checkbox | DateRangePicker
       └─ FormActions
            └─ ActionButton (variant="outline") Cancel
            └─ ActionButton (type="submit") Save
```

**Canonical example:**
```tsx
<PageLayout>
  <PageHeader title="Create Campaign" backHref="/campaigns" />
  <form onSubmit={handleSubmit}>
    <FormFieldSet legend="Basic Info">
      <FormRow cols={2}>
        <FormField label="Name" required><Input name="name" /></FormField>
        <FormField label="Status"><Select name="status" options={opts} /></FormField>
      </FormRow>
      <FormField label="Description" description="Optional">
        <Textarea name="description" />
      </FormField>
    </FormFieldSet>
    <FormActions>
      <ActionButton variant="outline" onClick={onCancel}>Cancel</ActionButton>
      <ActionButton type="submit">Save</ActionButton>
    </FormActions>
  </form>
</PageLayout>
```
// WHY: FormFieldSet provides visual sectioning. FormRow manages grid spacing. FormField encapsulates label + validation state. Component types enforce this — AI cannot accidentally break it.

**Card-wrapped variant** (form embedded in a larger page):
```tsx
<Card><CardHeader><CardTitle>Settings</CardTitle></CardHeader>
  <CardContent>
    <FormFieldSet legend="Preferences">
      <FormField label="Language"><Select options={langs} /></FormField>
    </FormFieldSet>
    <FormActions><ActionButton type="submit">Save</ActionButton></FormActions>
  </CardContent></Card>
```

## FORM-02 — FormActions Rules

FormActions MUST appear at the bottom of `<form>` (never inside FormFieldSet).
// WHY: Consistent button placement creates muscle memory. Cancel=outline (dismissive), Save=default (primary).

```tsx
// CORRECT — Cancel (outline) before Save (submit)
<FormActions>
  <ActionButton variant="outline" onClick={handleCancel}>Cancel</ActionButton>
  <ActionButton type="submit" disabled={isSubmitting}>{isSubmitting ? "Saving..." : "Save"}</ActionButton>
</FormActions>

// FORBIDDEN — reversed order (Save before Cancel)
<FormActions>
  <ActionButton type="submit">Save</ActionButton>
  <ActionButton variant="outline">Cancel</ActionButton>
</FormActions>

// FORBIDDEN — FormActions inside FormFieldSet
<FormFieldSet legend="Actions"><ActionButton type="submit">Save</ActionButton></FormFieldSet>
```

## FORM-03 — Forbidden Form Patterns

```tsx
// FORBIDDEN — raw div layout instead of FormFieldSet/FormRow
<form>
  <div style={{ marginBottom: 16 }}>
    <label>Name</label><input />
  </div>
</form>

// CORRECT — use FormFieldSet + FormField
<form><FormFieldSet legend="Basic Info">
  <FormField label="Name"><Input name="name" /></FormField>
</FormFieldSet></form>

// FORBIDDEN — bare Input outside FormField
<Card><Input placeholder="Campaign name" /></Card>

// FORBIDDEN — inline style on form components
<FormField style={{ marginTop: "24px" }} label="Name"><Input /></FormField>
```
// WHY: Raw HTML bypasses label association and spacing tokens. Inline styles cannot be audited automatically.
For the complete list of forbidden patterns, see: @.claude/rules/forbidden.md

## Validation Patterns

**Required fields:** Use `required` prop on FormField — do not add asterisks manually.
```tsx
// CORRECT
<FormField label="Campaign Name" required><Input name="name" /></FormField>
// FORBIDDEN — manual asterisk in label
<FormField label="Campaign Name *"><Input name="name" /></FormField>
```

**Error display:** FormField surfaces validation via its `error` prop. With react-hook-form, pass error to `description` as fallback.
// WHY: Error messages must appear adjacent to the field — FormField's layout guarantees this.
**Helper text:** Use `description` prop — never add a separate `<p>` below the input.
For full interface contracts, see: @.claude/rules/component-interfaces.md

## Escape Hatch

If genuinely not coverable by FormField (e.g., custom file uploader, rich text editor):
1. STOP — do not use raw `<input>` or `<div>` layout
2. Describe the needed element and ask for approval to create a new Composed wrapper
3. After approval, create it in `@/components/composed/` with typed props, no className passthrough
4. Wrap it inside a `FormField` so label, required indicator, and description still apply
