# shadcn-rules

AI가 shadcn/ui 기반 대시보드를 생성할 때 일관된 코드를 보장하는 규칙 시스템.

## 규칙의 3계층

| 계층 | 설명 | 예시 |
|------|------|------|
| **절대 규칙** | 위반 불가 | inline style 금지, 하드코딩 색상 금지, Card 구조 |
| **기본값** | 특별한 지시 없으면 이대로 생성 | p-4 spacing, chart-1~5, KPI→Chart→Table 순서 |
| **커스텀 허용** | 사용자 지시 시 토큰 시스템 안에서 변경 가능 | 색상 팔레트 확장, spacing 조정 |

## 컴포넌트 모델

2-tier component model:
- **shadcn tier**: `@/components/ui/*` 직접 사용
- **Composed tier**: `@/components/composed/*` — DataTable, SearchBar, KpiCard only

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

- **shadcn 컴포넌트 원본 수정 금지**: `@/components/ui/*` 소스 코드를 절대 수정하지 않는다. 기본값이 부족하면 규칙 파일의 예제 코드에서 className으로 보완한다.
  // WHY: shadcn 원본을 건드리면 업데이트 시 충돌하고, `.claude/` 디렉토리만 복사해서 재사용할 수 없다.

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
