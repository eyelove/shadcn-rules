# shadcn-rules

## 이 프로젝트가 하는 일

AI가 shadcn/ui 기반 대시보드를 생성할 때, **누가 언제 요청하든 일관된 코드**가 나오도록 보장하는 규칙 시스템이다.

### 왜 필요한가

shadcn 공식 문서를 참조해도 AI는 일관된 코드를 생성하지 않는다. className을 inline으로 남발하거나, shadcn이 제공하는 컴포넌트를 무시하고 div로 직접 만든다. 이 프로젝트는 규칙 파일과 예제 코드를 통해 이 문제를 해결한다.

### 규칙의 3계층

| 계층 | 설명 | 예시 |
|------|------|------|
| **절대 규칙** | 위반 불가. shadcn을 올바르게 쓰기 위한 최소 규칙 | inline style 금지, 하드코딩 색상 금지, Card 구조 |
| **기본값** | 특별한 지시 없으면 이대로 생성 | p-4 spacing, chart-1~5, KPI→Chart→Table 순서 |
| **커스텀 허용** | 사용자 지시 시 토큰 시스템 안에서 변경 가능 | 색상 팔레트 확장, spacing 조정, 섹션 순서 변경 |

"대충 요청하면 기본값으로 동일하게, 사용자가 직접 지시하면 규칙 안에서 자유롭게."

### 개선 사이클

1. 규칙 + 예제 작성 (`.claude/rules/`)
2. AI에게 페이지 생성 요청 (`/eval`)
3. 결과 검증 — 일관성, 규칙 준수 여부
4. 실패한 부분 → 규칙/예제 보강
5. 반복

규칙 파일의 예제 코드는 "있으면 좋은 것"이 아니라, **AI가 올바르게 따르는지 eval로 검증된 것**만 남긴다.

### 다른 프로젝트에서 사용

`.claude/` 디렉토리를 복사하면 동일한 규칙이 적용된다. 프로젝트별 커스텀은 이 CLAUDE.md에서 기본값을 재정의한다.

---

## 컴포넌트 모델

2-tier component model:
- **shadcn tier**: Use shadcn/ui components directly (`@/components/ui/*`)
- **Composed tier**: Domain-specific components with internal logic (`@/components/composed/*` — DataTable, SearchBar, KpiCard only)

## 규칙 파일

Follow these rules for every file you touch.

@.claude/rules/components.md
@.claude/rules/cards.md
@.claude/rules/fields.md
@.claude/rules/data-table.md
@.claude/rules/formatting.md
@.claude/rules/tokens.md
@.claude/rules/forbidden.md
@.claude/rules/naming.md
@.claude/rules/page-templates.md

## Always Apply

- **Imports**: Use shadcn components directly from `@/components/ui/*`. Use `@/components/composed/` only for DataTable, SearchBar, KpiCard.
  // WHY: shadcn components are the standard. Composed is only for domain logic that can't be expressed with direct shadcn usage.

- **Card wrapping**: Every independent dashboard section (chart, table, form) MUST be wrapped in a Card. No Card double-wrapping. See `cards.md`.
  // WHY: Card provides visual consistency across all sections. Double-wrapping breaks spacing.

- **Field system**: All form inputs MUST be inside a `<Field>` with `<FieldLabel>`. Form buttons go in `<CardFooter>`. See `fields.md`.
  // WHY: Field provides accessible labels and validation state. CardFooter gives consistent button placement.

- **Tokens**: Use CSS custom property tokens for ALL color, spacing, and radius values. Never hardcode hex, rgb, or oklch literals.
  // WHY: Hardcoded values break theming and make dark mode impossible to maintain.

- **No inline styles**: Never use `style={{}}` on any element. No exceptions. This includes Recharts `contentStyle` — use shadcn's `ChartTooltip` + `ChartTooltipContent` instead. Do not pass `stroke` to `CartesianGrid`/`XAxis`/`YAxis` — `ChartContainer` handles axis styling.
  // WHY: Inline styles bypass the token system. shadcn's chart components handle theming internally.

- **Formatting**: Use locale-aware format utility functions for all numbers, currency, and percentages. See `formatting.md`.
  // WHY: Consistent number formatting across KPI cards and tables. Supports multi-locale (ko-KR, en-US).

- **Rule files**: When in doubt about what is allowed, read the specific rule file. Do not infer — look it up.
