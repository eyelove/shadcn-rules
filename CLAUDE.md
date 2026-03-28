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

## Eval & Preview

### 테스트 방법

`/eval`(또는 `run-eval.sh`)을 실행하면 동일한 프롬프트로 두 버전의 페이지를 생성한다.

- **Arm A** (`{page}.with_rules.tsx`): `.claude/rules/` 규칙을 적용해서 생성
- **Arm B** (`{page}.without_rules.tsx`): 규칙 없이 생성

생성된 코드는 `check-rules.sh`(grep 기반 패턴 검사)와 `tsc -b`(빌드 체크)로 자동 검증되고, 결과는 `tests/snapshots/`에 날짜별로 아카이브된다.

### 왜 preview를 만드는가

자동 검증은 "inline style이 없다", "Card 구조가 맞다" 같은 코드 패턴만 확인한다. 하지만 규칙을 100% 준수한 코드가 화면에서 깨질 수 있고, 점수가 낮은 코드가 시각적으로는 괜찮아 보일 수도 있다. 코드 점수와 실제 화면 품질은 다른 문제다.

`preview/`는 `npx shadcn@latest init`으로 생성되는 완전한 Vite + shadcn 앱이다. AI가 생성한 페이지를 이 앱 안에서 `pnpm dev`로 띄워서 **사람이 브라우저에서 실제 렌더링 결과를 눈으로 확인**한다. 코드 검증의 마지막 단계는 사람의 시각적 리뷰다.

preview/는 git에서 추적하지 않는다. `reset-preview.sh`로 언제든 삭제 후 재생성할 수 있으며, 매번 처음부터 만들어서 환경의 일관성을 보장한다.

### 무엇을 확인할 수 있는가

**A/B 비교** — viewer(`open-viewer.sh` → `pnpm dev`)에서 같은 페이지의 규칙 적용 버전과 미적용 버전을 좌우로 놓고 비교한다. 규칙이 실제로 화면 품질에 차이를 만드는지 판단한다. 이 비교가 없으면 규칙의 효과를 증명할 근거가 없다.

**개선 추적** — 규칙을 수정한 뒤 다시 eval을 돌리면 새 snapshot이 생긴다. viewer의 Run vs Run 모드에서 이전 snapshot과 현재 snapshot을 비교하면 "이번 규칙 변경이 실제로 나아졌는가"를 확인할 수 있다. snapshot을 보관하는 이유가 이것이다.

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
