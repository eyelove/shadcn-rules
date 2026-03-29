# shadcn-rules를 내 프로젝트에 적용하기

shadcn/ui 기반 프로젝트에 이 규칙 시스템을 적용하는 방법을 안내합니다.

## 전제 조건

- shadcn/ui가 설치된 프로젝트 (Next.js, Vite 등)
- Claude Code (CLI, IDE 확장, 또는 claude.ai/code)

## 적용 구조

적용 후 프로젝트 디렉토리 구조:

```
my-project/
├── CLAUDE.md                         # 규칙 허브 (Claude Code가 자동 로드)
├── .claude/
│   └── rules/                        # 규칙 파일 9개
│       ├── components.md
│       ├── cards.md
│       ├── fields.md
│       ├── data-table.md
│       ├── formatting.md
│       ├── tokens.md
│       ├── forbidden.md
│       ├── naming.md
│       └── page-templates.md
├── src/
│   ├── components/
│   │   ├── ui/                       # shadcn/ui 원본 (수정 금지)
│   │   └── composed/                 # Composed 컴포넌트
│   │       ├── index.ts              #   barrel export
│   │       ├── DataTable.tsx
│   │       ├── SearchBar.tsx
│   │       └── KpiCard.tsx
│   └── lib/
│       ├── utils.ts                  # cn() 유틸리티 (shadcn 기본 제공)
│       └── format.ts                 # 숫자/통화/날짜 포맷 유틸리티
└── ...
```

## Step 1 — 규칙 파일 복사

```bash
RULES_REPO="path/to/shadcn-rules"
MY_PROJECT="path/to/my-project"

# .claude/rules/ 복사
mkdir -p "$MY_PROJECT/.claude/rules"
cp "$RULES_REPO/.claude/rules/"*.md "$MY_PROJECT/.claude/rules/"

# CLAUDE.md 복사
cp "$RULES_REPO/CLAUDE.md" "$MY_PROJECT/CLAUDE.md"
```

## Step 2 — CLAUDE.md 편집

복사한 `CLAUDE.md`에서 **eval 전용 섹션을 제거**합니다:

```markdown
# 이 섹션 전체 삭제:
## Eval Preview 환경 주의사항
...
```

프로젝트에 맞게 커스터마이즈할 수 있는 항목:

| 항목 | 위치 | 커스터마이즈 예시 |
|------|------|-----------------|
| Composed 컴포넌트 목록 | `## 컴포넌트 모델` | 프로젝트 전용 Composed 추가 |
| 규칙 파일 참조 | `## 규칙 파일` | 불필요한 규칙 제거 |
| Always Apply | `## Always Apply` | 프로젝트 고유 제약 추가 |

## Step 3 — Composed 컴포넌트 설치

```bash
# Composed 컴포넌트 복사
mkdir -p "$MY_PROJECT/src/components/composed"
cp "$RULES_REPO/scripts/templates/composed/DataTable.tsx" "$MY_PROJECT/src/components/composed/"
cp "$RULES_REPO/scripts/templates/composed/SearchBar.tsx" "$MY_PROJECT/src/components/composed/"
cp "$RULES_REPO/scripts/templates/composed/KpiCard.tsx" "$MY_PROJECT/src/components/composed/"
```

barrel export 파일 생성 (`src/components/composed/index.ts`):

```ts
export { DataTable } from "./DataTable"
export { SearchBar } from "./SearchBar"
export { KpiCard } from "./KpiCard"
```

### Composed 컴포넌트 의존성

```bash
# DataTable이 사용하는 TanStack Table
pnpm add @tanstack/react-table
```

### 필요한 shadcn 컴포넌트

Composed 컴포넌트가 의존하는 shadcn 컴포넌트입니다. 아직 설치하지 않았다면:

```bash
npx shadcn@latest add card badge button checkbox input textarea select \
  field chart separator popover calendar switch radio-group combobox \
  table tabs dropdown-menu dialog alert-dialog toggle-group
```

## Step 4 — 포맷 유틸리티 설치

```bash
cp "$RULES_REPO/scripts/templates/format.ts" "$MY_PROJECT/src/lib/format.ts"
```

이 파일은 외부 의존성 없이 `Intl.NumberFormat`과 자체 compact 로직을 사용합니다.

제공 함수:

| 함수 | 용도 | 예시 (ko-KR) |
|------|------|-------------|
| `formatNumber` | 정수/소수 표시 | `125,000` |
| `formatCurrency` | 통화 표시 (정확값) | `12,500원` |
| `formatCurrencyCompact` | 통화 표시 (축약) | `125만원` |
| `formatCompact` | 수량 축약 | `12.5만` |
| `formatPercent` | 백분율 | `2.74%` |
| `formatDelta` | 변화율 (부호 포함) | `+12.5%` |
| `formatDate` | 날짜 표시 | `2026-03-29` |

## Step 5 — 커스텀 토큰 추가 (선택)

대시보드 확장 토큰을 CSS에 추가합니다. `src/index.css` (또는 `globals.css`)의 `:root` 블록 안에:

```css
/* KPI tokens */
--kpi-bg: var(--color-card);
--kpi-positive: oklch(0.627 0.194 149.214);
--kpi-negative: oklch(0.577 0.245 27.325);

/* Table tokens */
--table-row-hover: var(--color-accent);
```

dark mode 블록(`.dark`)에도 필요시 오버라이드를 추가하세요.

## 동작 확인

적용 후 Claude Code에서 프로젝트를 열고 테스트합니다:

```
# Claude Code에서 실행
> 캠페인 목록 페이지를 만들어줘
```

정상 적용 시 생성된 코드가 다음을 준수합니다:
- `div.flex.flex-col.gap-4.p-4` 루트 래퍼
- Card > CardHeader > CardContent 구조
- `@/components/ui/*` 직접 import
- `@/components/composed` barrel import
- `@/lib/format` 포맷 유틸리티 사용
- CSS 토큰 기반 색상/간격 (하드코딩 없음)
- Field > FieldLabel 폼 구조

## 규칙 커스터마이즈

### 규칙 파일 선택 적용

모든 규칙이 필요하지 않다면 `CLAUDE.md`에서 참조를 제거합니다:

```markdown
# 차트가 없는 프로젝트라면 cards.md에서 CARD-02 관련 내용 불필요
# 폼이 없는 프로젝트라면 fields.md 제거 가능

## 규칙 파일
@.claude/rules/components.md
@.claude/rules/cards.md
@.claude/rules/fields.md        # <- 폼 없으면 제거
@.claude/rules/data-table.md
@.claude/rules/formatting.md
@.claude/rules/tokens.md
@.claude/rules/forbidden.md
@.claude/rules/naming.md
@.claude/rules/page-templates.md
```

### 로케일 변경

`formatting.md`의 기본 로케일은 `ko-KR`입니다. 다른 로케일이 필요하면:

1. `formatting.md`에 새 로케일 규칙 추가
2. `format.ts`에 해당 로케일 처리 로직 추가

### Composed 컴포넌트 추가

프로젝트 고유 Composed가 필요하면:

1. `components.md`의 Composed Qualification 기준 확인 (상태 관리, 도메인 로직, 3회 이상 반복)
2. `components.md` Composed 테이블에 추가
3. `naming.md` 규칙에 따라 PascalCase로 생성
4. barrel export (`index.ts`)에 추가

## 주의사항

- **shadcn 원본 수정 금지**: `@/components/ui/*`는 절대 수정하지 않습니다. `npx shadcn@latest add`로 업데이트할 때 충돌이 발생합니다.
- **규칙 파일은 paths 매칭**: 각 규칙 파일의 frontmatter에 `paths:` 설정이 있어 해당 경로의 파일에만 적용됩니다. 프로젝트 구조가 다르면 paths를 수정하세요.
- **eval 시스템은 별도**: `scripts/`, `tests/`, `preview/`는 eval 전용입니다. 규칙 적용에는 `.claude/`와 `CLAUDE.md`만 필요합니다.
