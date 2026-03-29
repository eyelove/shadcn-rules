---
paths:
  - "src/**/*.tsx"
  - "src/**/*.css"
  - "app/**/*.tsx"
  - "app/**/*.css"
  - "components/**/*.tsx"
  - "components/**/*.css"
  - "resources/js/**/*.tsx"
  - "resources/css/**/*.css"
---

# Forbidden Patterns

6가지 절대 금지 패턴. 예외 없음.

## FORB-01 — No Inline Styles
NEVER use `style={{}}` on any element. Recharts `contentStyle`, axis/grid `stroke` 포함.
// WHY: Inline styles bypass the token system and cannot be audited.
```tsx
// FORBIDDEN
<div style={{ marginTop: "24px", padding: "16px" }}>
// CORRECT
<div className="mt-6 p-4">
```

## FORB-02 — No Hardcoded Colors
NEVER use hex, rgb(), oklch(), or Tailwind color primitives (`bg-zinc-900`, `text-gray-100`).
// WHY: Hardcoded values break theming and dark mode. Token names are stable.
```tsx
// FORBIDDEN
<div className="bg-zinc-900 text-gray-100" />
// CORRECT
<div className="bg-background text-foreground" />
```

## FORB-03 — No div as Card Substitute
NEVER use `<div>` with border/background/padding as Card substitute. Layout divs (`flex`, `grid`) are allowed.
// WHY: Card is the standard container with token-based surfaces. Raw divs fragment theming.
```tsx
// FORBIDDEN
<div className="rounded-lg border bg-card p-4"><h3>Revenue</h3></div>
// CORRECT
<Card><CardHeader><CardTitle>Revenue</CardTitle></CardHeader><CardContent>...</CardContent></Card>
```

## FORB-04 — No Unnecessary Composed Wrappers
NEVER create wrappers that merely pass through to shadcn without adding logic/layout/constraint.
// WHY: Thin wrappers add indirection with no benefit and drift from upstream shadcn.
```tsx
// FORBIDDEN
export function ActionButton(props) { return <Button {...props} /> }
// CORRECT
<Button onClick={handleCreate}>New Campaign</Button>
```

## FORB-05 — No Bare Input (Outside Field)
NEVER use Input/Select/Textarea/Checkbox outside `<Field>` in form contexts.
**Exception:** search/filter toolbar inputs above DataTable are allowed without Field.
// WHY: Field provides accessible label, description, and validation state.
```tsx
// FORBIDDEN
<Input placeholder="Campaign name" />
// CORRECT
<Field><FieldLabel>Campaign Name</FieldLabel><Input placeholder="Campaign name" /></Field>
```

## FORB-06 — No Card Double Wrapping
NEVER nest Card inside Card. One Card per section, one level deep. Sub-grouping uses Separator or gap.
// WHY: Double wrapping creates redundant padding, doubled borders, broken hierarchy.
```tsx
// FORBIDDEN
<Card><CardContent><Card>...</Card></CardContent></Card>
// CORRECT
<Card><CardContent className="space-y-4"><div>A</div><Separator /><div>B</div></CardContent></Card>
```

## Escape Hatch
금지 패턴이 정말 필요하면 멈추고, 이유 설명 후 승인 대기. 승인 시 `// EXCEPTION:` 주석 추가.
