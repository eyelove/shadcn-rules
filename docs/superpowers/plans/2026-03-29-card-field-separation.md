# Card-Field 책임 분리 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Card 예제는 cards.md에 1곳, Field 예제는 fields.md에서 form 내부만 — CardFooter/CardHeader 중복을 근본 제거한다.

**Architecture:** cards.md CARD-04에 Form Card 전체 예제(Card > CardHeader > CardContent > form > CardFooter)를 복원하고, fields.md에서는 Card 래핑을 전부 제거하여 `<form>` 내부(FieldGroup/FieldSet/Field)만 다룬다. Forbidden 섹션의 Card 관련 예제도 cards.md 참조로 대체.

**현재 문제:**
- fields.md에 `<CardFooter>` 7회, `<Card>` 6회 등장 — "Field 규칙" 파일이 Card 예제를 품고 있음
- cards.md CARD-04는 참조만 있고 예제 없음 — Form Card의 기준 예제가 없는 상태

---

## Task 1: cards.md CARD-04에 Form Card 기준 예제 복원

**Files:**
- Modify: `.claude/rules/cards.md:267-272`

cards.md CARD-04를 Form Card의 **유일한 전체 예제**로 만든다. CardFooter에 `gap-2` 포함.

- [ ] **Step 1: CARD-04 섹션을 다음으로 교체**

```markdown
### CARD-04 — Form Card

Form cards embed a form inside a Card, typically on settings or edit pages.

```tsx
<Card>
  <CardHeader>
    <CardTitle>Campaign Settings</CardTitle>
    <CardDescription>Update campaign configuration</CardDescription>
  </CardHeader>
  <CardContent>
    <form id="campaign-form" onSubmit={handleSubmit}>
      {/* form 내부 패턴: @.claude/rules/fields.md FIELD-01~07 */}
    </form>
  </CardContent>
  <CardFooter className="gap-2">
    <Button variant="outline" type="button" onClick={onCancel}>Cancel</Button>
    <Button type="submit" form="campaign-form">Save</Button>
  </CardFooter>
</Card>
```

**Rules:**
- `<form>`에 `id` 부여, submit 버튼은 `form="form-id"`로 CardFooter에서 연결
- CardFooter에 `className="gap-2"` 필수 (shadcn CardFooter에 기본 gap 없음)
- 보조 액션은 `variant="outline"`, 주요 액션은 default variant
- 3개 이상 버튼 허용 (예: Cancel + Save Draft + Publish)
- form 내부 구조(FieldGroup, FieldSet, Field 등)는 @.claude/rules/fields.md 참조

// WHY: Card가 폼의 시각적 경계를 제공한다. CardFooter가 버튼을 CardContent 밖에 고정한다.
// form id linking으로 버튼이 form 엘리먼트 안에 있지 않아도 submit이 동작한다.
```

- [ ] **Step 2: 검증**

Run: `grep -c 'CardFooter' .claude/rules/cards.md`
Expected: 기존 + 1 (CARD-04에 추가된 것)

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/cards.md
git commit -m "refactor: CARD-04에 Form Card 기준 예제 복원"
```

---

## Task 2: fields.md에서 Card 래핑 전부 제거

**Files:**
- Modify: `.claude/rules/fields.md`

fields.md의 역할을 "`<form>` 내부 패턴만"으로 한정한다.

### 제거/변경 대상

1. **Common Imports 섹션** — Card 관련 import 제거 (Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter)
2. **Field Component Hierarchy** — Card 래핑을 제거하고 `<form>` 부터 시작하도록 변경. 상위에 "Card 래핑은 @cards.md CARD-04 참조" 한 줄 추가
3. **FIELD-01** — Card/CardHeader/CardContent/CardFooter 제거, `<form>` 내부만 남김. "Card 래핑과 CardFooter는 @cards.md CARD-04를 따른다" 안내
4. **FIELD-02~07** — 이미 form 내부만 표시하거나, 남은 Card 참조 제거
5. **CardFooter Button Rules 섹션** — 전체 삭제. 이 내용은 Task 1에서 cards.md CARD-04로 이동됨
6. **Forbidden Patterns** — Card 관련 예제(Card-less Form, Card-per-Section, Submit Button Inside CardContent) 삭제, cards.md 참조로 대체. FieldLabel-less Input, Bare Input Outside Field, Button Variant 미구분은 유지.

- [ ] **Step 1: Common Imports에서 Card import 제거**

변경 전:
```tsx
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card"
import { Field, FieldLabel, FieldGroup, FieldSet, FieldLegend, FieldSeparator, FieldDescription, FieldError, FieldContent } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"
import { Button } from "@/components/ui/button"
```

변경 후:
```tsx
import { Field, FieldLabel, FieldGroup, FieldSet, FieldLegend, FieldSeparator, FieldDescription, FieldError, FieldContent } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from "@/components/ui/select"
import { Button } from "@/components/ui/button"
```

- [ ] **Step 2: Field Component Hierarchy 변경**

변경 전:
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
  │                        └─ Input | Select | Combobox | Textarea | Checkbox | DatePicker(Popover+Calendar)
  │                        └─ FieldDescription
  │                        └─ FieldError
  └─ CardFooter (Cancel + Submit)
```

변경 후:
```markdown
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
```

- [ ] **Step 3: FIELD-01에서 Card 래핑 제거**

변경 전 (68~95줄):
```tsx
<Card>
  <CardHeader>
    ...
  </CardHeader>
  <CardContent>
    <form id="campaign-form" onSubmit={handleSubmit}>
      <FieldGroup>
        ...
      </FieldGroup>
    </form>
  </CardContent>
  <CardFooter className="gap-2">
    ...
  </CardFooter>
</Card>
```

변경 후:
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

FIELD-01 위의 설명도 변경:
```
Card > CardContent > form > FieldGroup > Field (...)
CardFooter with Cancel (outline) + Save (submit), linked via form id.
```
→
```
form > FieldGroup > Field (FieldLabel + Input + FieldDescription).
Card 래핑과 CardFooter: @.claude/rules/cards.md CARD-04
```

"FIELD-01이 Card 전체 구조의 기준 예제다..." 안내문도 삭제.

- [ ] **Step 4: FIELD-02 Card 참조 문구 제거**

"Card 래핑과 CardFooter는 FIELD-01과 동일. `<form>` 내부만 표시:" → "`<form>` 내부만 표시. Card 래핑: @.claude/rules/cards.md CARD-04"

FIELD-02 위의 설명도 변경:
```
Card > CardContent > form > FieldGroup > FieldSet (...)
One form = one Card. Sections divided by FieldSet, NOT by multiple Cards.
```
→
```
form > FieldGroup > FieldSet (FieldLegend) + FieldSeparator + FieldSet.
Card 래핑: @.claude/rules/cards.md CARD-04
```

- [ ] **Step 5: FIELD-04 Card 참조 문구 변경**

"Card 래핑과 CardFooter는 FIELD-01과 동일." → "Card 래핑: @.claude/rules/cards.md CARD-04"
"// Card > CardHeader > CardContent 래핑은 FIELD-01 참고" 주석 삭제.

- [ ] **Step 6: CardFooter Button Rules 섹션 전체 삭제 (355~374줄 부근)**

이 섹션의 내용(variant 구분, gap-2, form id linking)은 Task 1에서 cards.md CARD-04 Rules에 포함됨.
삭제하고 대신 1줄 참조: "CardFooter 버튼 규칙: @.claude/rules/cards.md CARD-04"

- [ ] **Step 7: Forbidden Patterns에서 Card 관련 항목 정리**

**삭제 → cards.md 참조:**
- "Card-less Form" (406~433줄) — 삭제, "@.claude/rules/cards.md CARD-04" 참조
- "Card-per-Section Splitting" (453~478줄) — 삭제, "@.claude/rules/cards.md" 참조
- "Submit Button Inside CardContent" (480~503줄) — 삭제, "@.claude/rules/cards.md CARD-04" 참조

**유지:**
- "FieldLabel-less Input" — fields.md 고유
- "Bare Input Outside Field" — fields.md 고유
- "Button Variant 미구분" — fields.md 고유 (CardFooter 예제는 cards.md CARD-04 참조로 변경)

"Button Variant 미구분" 예제에서 `<CardFooter>` 코드 블록 제거, 규칙 설명만 유지:
```markdown
### Button Variant 미구분

주요 액션과 보조 액션은 반드시 variant로 시각적으로 구분해야 한다.
// WHY: ...
CardFooter 버튼 예제: @.claude/rules/cards.md CARD-04
```

- [ ] **Step 8: Forbidden 섹션 상단에 Card 관련 참조 추가**

```markdown
## Forbidden Patterns

Card 래핑 관련 금지 패턴(Card-less Form, Submit Button 위치, Card-per-Section): @.claude/rules/cards.md CARD-04
```

- [ ] **Step 9: 검증**

Run: `grep -c '<CardFooter\|<CardHeader\|<Card>' .claude/rules/fields.md`
Expected: 0 (Card 관련 JSX가 전부 제거됨)

Run: `wc -l .claude/rules/fields.md`
Expected: ~420줄 이하 (현재 540줄)

- [ ] **Step 10: Commit**

```bash
git add .claude/rules/fields.md
git commit -m "refactor: fields.md에서 Card 래핑 제거, form 내부만 다루도록 분리"
```

---

## Task 3: cards.md CARD-04에 Form Card Forbidden 패턴 추가

**Files:**
- Modify: `.claude/rules/cards.md` (CARD-04 섹션)

Task 2에서 fields.md에서 삭제한 Card 관련 Forbidden 패턴 3개를 cards.md CARD-04에 추가한다.

- [ ] **Step 1: CARD-04 Rules 아래에 Forbidden 추가**

CARD-04의 Rules 뒤에 다음을 추가:

```markdown
**Forbidden:**

```tsx
// FORBIDDEN — form without Card
<form onSubmit={handleSubmit}>
  <FieldGroup>...</FieldGroup>
  <Button type="submit">Save</Button>
</form>
```
// WHY: Card provides visual boundary, header context, and footer button placement.

```tsx
// FORBIDDEN — submit button inside CardContent
<CardContent>
  <form onSubmit={handleSubmit}>
    <FieldGroup>...</FieldGroup>
    <Button type="submit">Save</Button>
  </form>
</CardContent>
```
// WHY: Submit belongs in CardFooter. form id linking keeps buttons outside the form element.

- 단일 폼은 하나의 Card. 멀티스텝/위저드에서만 복수 Card 허용.
```

- [ ] **Step 2: 검증**

Run: `grep -c 'FORBIDDEN' .claude/rules/cards.md`

- [ ] **Step 3: Commit**

```bash
git add .claude/rules/cards.md
git commit -m "refactor: CARD-04에 Form Card forbidden 패턴 추가"
```

---

## Task 4: page-templates.md PAGE-03의 CardFooter에 gap-2 추가

**Files:**
- Modify: `.claude/rules/page-templates.md:161`

- [ ] **Step 1: gap-2 추가**

변경 전:
```tsx
    <CardFooter>
```

변경 후:
```tsx
    <CardFooter className="gap-2">
```

- [ ] **Step 2: Commit**

```bash
git add .claude/rules/page-templates.md
git commit -m "fix: PAGE-03 CardFooter에 gap-2 추가"
```

---

## Task 5: cross-reference 정합성 확인

**Files:**
- Verify: `.claude/rules/*.md`

- [ ] **Step 1: fields.md에서 cards.md 참조가 올바른지 확인**

```bash
grep -n '@.*cards\.md' .claude/rules/fields.md
```

- [ ] **Step 2: cards.md에서 fields.md 참조가 올바른지 확인**

```bash
grep -n '@.*fields\.md' .claude/rules/cards.md
```

- [ ] **Step 3: fields.md에 Card JSX가 남아있지 않은지 확인**

```bash
grep -n '<Card\|<CardHeader\|<CardContent\|<CardFooter' .claude/rules/fields.md
```
Expected: 0 matches

- [ ] **Step 4: 필요시 수정 후 Commit**

---

## 실행 순서

```
Task 1 (cards.md CARD-04 복원)
  │
Task 2 (fields.md Card 제거) ← Task 1 완료 후 (참조 대상 필요)
  │
Task 3 (cards.md Forbidden 추가) ← Task 2 완료 후 (삭제된 내용 이동)
  │
Task 4 (page-templates.md gap-2) ← 독립, 아무때나
  │
Task 5 (cross-reference 검증) ← Task 1~4 완료 후
```

## 예상 결과

| 파일 | 현재 | 예상 | CardFooter 수 |
|------|------|------|-------------|
| fields.md | 540줄, CardFooter 7회 | ~400줄, CardFooter 0회 | 7 → 0 |
| cards.md | 390줄, CardFooter 3회 | ~420줄, CardFooter 4회 | 3 → 4 (CARD-04 추가) |
| page-templates.md | 259줄 | 259줄 (gap-2만 추가) | 변경 없음 |
