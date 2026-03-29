---
paths:
  - "src/**/*.tsx"
  - "src/**/*.ts"
  - "app/**/*.tsx"
  - "app/**/*.ts"
  - "lib/**/*.ts"
  - "resources/js/**/*.tsx"
  - "resources/js/**/*.ts"
---

# Formatting Rules

All number/currency/percentage/date display MUST use `@/lib/format` utilities. NEVER format inline in JSX.

## Principles

1. **Locale-based** — Same number renders differently in ko-KR vs en-US.
2. **KPI = compact, Table = exact** — KPI uses 만/억 or K/M/B; Table shows exact comma-separated values.
3. **Unified** — All formatting flows through `@/lib/format`. No inline formatting logic in components.

## ko-KR Rules

| Item | Rule | Example |
|------|------|---------|
| Currency | number + "원" (no ₩) | `12,500원` |
| Decimals | No decimals for won | `12,500원` |
| KPI compact (money) | 만/억 + "원" | `1.2만원`, `125만원`, `1.2억원` |
| KPI compact (quantity) | 만/억, no suffix | `1.2만`, `125만`, `1.2억` |
| Table cell (money) | Exact + "원" | `12,500원` |
| Table cell (quantity) | Comma-separated | `125,000` |
| Percent | 2 decimals | `2.74%` |
| Delta | Sign + value | `+12.5%`, `-0.3%` |
| Date (default/long/slash) | `YYYY-MM-DD` / `YYYY년 MM월 DD일` / `YYYY/MM/DD` | `2026-03-29` |

## en-US Rules

| Item | Rule | Example |
|------|------|---------|
| Currency | "$" prefix, 2 decimals | `$12,500.00` |
| KPI compact | K/M/B units | `1.2K`, `1.2M` |
| Table cell (money/quantity) | `$12,500.00` / `125,000` | — |
| Percent / Delta | `2.74%` / `+12.5%` | — |
| Date | `Mon DD, YYYY` | `Mar 29, 2026` |

## Format Utilities

```tsx
import { formatCurrency, formatCurrencyCompact, formatCompact, formatNumber, formatPercent, formatDelta, formatDate } from "@/lib/format"

interface FormatOptions { locale: "ko-KR" | "en-US"; currency?: "KRW" | "USD" }
```

**Signatures:**
```
formatCompact(125000, { locale: "ko-KR" })                              → "12.5만"
formatCurrencyCompact(1250000, { locale: "ko-KR", currency: "KRW" })   → "125만원"
formatNumber(125000, { locale: "ko-KR" })                               → "125,000"
formatCurrency(12500, { locale: "ko-KR", currency: "KRW" })            → "12,500원"
formatPercent(0.0274, { locale: "ko-KR" })                              → "2.74%"
formatDelta(0.125)                                                       → "+12.5%"
formatDate(new Date("2026-03-29"), { locale: "ko-KR" })                → "2026-03-29"
formatDate(new Date("2026-03-29"), { locale: "ko-KR", format: "long" })→ "2026년 03월 29일"
```

## Context Application

| Context | Function | ko-KR | en-US |
|---------|----------|-------|-------|
| KPI value (money) | `formatCurrencyCompact` | `1.2만원` | `$12.5K` |
| KPI value (quantity) | `formatCompact` | `12.5만` | `125K` |
| KPI delta | `formatDelta` | `+12.5%` | `+12.5%` |
| Table cell (money) | `formatCurrency` | `12,500원` | `$12,500.00` |
| Table cell (quantity) | `formatNumber` | `125,000` | `125,000` |
| Table cell (ratio) | `formatPercent` | `2.74%` | `2.74%` |
| Date | `formatDate` | `2026-03-29` | `Mar 29, 2026` |

## Forbidden

- **FMT-01**: `toLocaleString()`, `Intl.NumberFormat` 직접 사용 금지 — format 유틸리티 사용
- **FMT-02**: `₩`, `$`, `원` JSX에 직접 작성 금지 — format 함수가 심볼 처리
- **FMT-03**: locale 파라미터 생략 금지 — 모든 format 호출에 명시적 locale 필수
- **FMT-04**: `date-fns format()`, `toLocaleDateString()` 직접 사용 금지 — `formatDate` 사용

**Escape Hatch:** 새 포맷이 필요하면 `@/lib/format`에 함수 추가 제안 후 승인받아 구현. 컴포넌트에 인라인 포맷 금지.
