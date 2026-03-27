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

All number, currency, and percentage display MUST use format utility functions from `@/lib/format`.
NEVER format numbers inline in JSX. NEVER hardcode currency symbols in JSX templates.
// WHY: Inline formatting scatters locale logic across every file. A single format utility guarantees
// consistent output and makes locale changes a one-file operation.

## Principles

1. **Locale-based formatting** — Display format changes based on the active locale setting. The same number renders differently in ko-KR vs en-US.
2. **KPI = compact, Table = exact** — KPI cards use abbreviated units (만/억, K/M/B) for scannability. Table cells show exact comma-separated values for precision.
3. **Unified via format utilities** — All formatting flows through `@/lib/format` functions. No component or page file may contain its own formatting logic.

// WHY: These three principles eliminate ambiguity. AI always knows which function to call based on
// context (KPI vs Table) and locale — no judgment calls required.

## ko-KR Rules

| Item | Rule | Example |
|------|------|---------|
| Currency | number + "원" suffix (no ₩ symbol) | `12,500원` |
| Decimals | Truncate to won, no decimals | `12,500원` (O) / `12,500.00원` (X) |
| KPI compact (≥ 1만, money) | 만/억 units + "원" suffix | `1.2만원`, `125만원`, `1.2억원` |
| KPI compact (≥ 1만, quantity) | 만/억 units, no suffix | `1.2만`, `125만`, `1.2억` |
| Table cell (money) | No abbreviation, exact + "원" | `12,500원` |
| Table cell (quantity) | No abbreviation, comma-separated | `125,000` |
| Percent | 2 decimal places | `2.74%` |
| Delta | Sign + value | `+12.5%`, `-0.3%`, `+4건` |

**ko-KR abbreviation scale:**
```
10,000        → "1만"
12,400        → "1.2만"
125,000       → "12.5만"
1,250,000     → "125만"
45,000,000    → "4,500만"
120,000,000   → "1.2억"
```
// WHY: Korean uses 만(10⁴) and 억(10⁸) as natural grouping units. Using K/M in a ko-KR locale
// would confuse Korean-speaking users who expect 만/억 scales.

## en-US Rules

| Item | Rule | Example |
|------|------|---------|
| Currency | "$" prefix + number | `$12,500` |
| Decimals | Cents allowed (2 decimal places) | `$1,250.00` |
| KPI compact (≥ 1K) | K/M/B units | `1.2K`, `45.2K`, `1.2M`, `1.2B` |
| Table cell (money) | No abbreviation, 2 decimals | `$12,500.00` |
| Table cell (quantity) | No abbreviation, comma-separated | `125,000` |
| Percent | 2 decimal places | `2.74%` |
| Delta | Sign + value | `+12.5%`, `-0.3%` |

## Format Utility Interface

All functions live in `@/lib/format`. Import via:
```tsx
import { formatCurrency, formatCurrencyCompact, formatCompact, formatNumber, formatPercent, formatDelta } from "@/lib/format"
```

### FormatOptions
```tsx
interface FormatOptions {
  locale: "ko-KR" | "en-US"    // extensible for future locales
  currency?: "KRW" | "USD"     // currency type
}
```

### Function Signatures and Examples

```tsx
// KPI value — compact (quantity, no currency)
formatCompact(125000, { locale: "ko-KR" })              // "12.5만"
formatCompact(125000, { locale: "en-US" })               // "125K"

// KPI value — compact with currency
formatCurrencyCompact(1250000, { locale: "ko-KR", currency: "KRW" })  // "125만원"
formatCurrencyCompact(1250000, { locale: "en-US", currency: "USD" })  // "$1.2M"

// Table cell — exact number (quantity)
formatNumber(125000, { locale: "ko-KR" })                // "125,000"
formatNumber(125000, { locale: "en-US" })                // "125,000"

// Table cell — exact currency
formatCurrency(12500, { locale: "ko-KR", currency: "KRW" })  // "12,500원"
formatCurrency(12500, { locale: "en-US", currency: "USD" })  // "$12,500.00"

// Percent — always 2 decimal places
formatPercent(0.0274, { locale: "ko-KR" })               // "2.74%"
formatPercent(0.0274, { locale: "en-US" })               // "2.74%"

// Delta — always includes sign prefix
formatDelta(0.125)                                        // "+12.5%"
formatDelta(-0.003)                                       // "-0.3%"
```

## Context Application

Use this table to determine which function to call based on where the value appears:

| Context | Format Function | ko-KR Example | en-US Example |
|---------|----------------|---------------|---------------|
| KPI Card value (money) | `formatCurrencyCompact` | `1.2만원` | `$12.5K` |
| KPI Card value (quantity) | `formatCompact` | `12.5만` | `125K` |
| KPI Card delta | `formatDelta` | `+12.5%` | `+12.5%` |
| Table cell (money) | `formatCurrency` | `12,500원` | `$12,500.00` |
| Table cell (quantity) | `formatNumber` | `125,000` | `125,000` |
| Table cell (ratio) | `formatPercent` | `2.74%` | `2.74%` |

// WHY: This lookup table eliminates guesswork. Given a UI context and data type, there is exactly
// one correct function to call — AI cannot pick the wrong one.

## Forbidden Patterns

### FMT-01 — No Inline Number Formatting

NEVER call `toLocaleString()`, `Intl.NumberFormat`, or manual string concatenation in JSX or component code.
// WHY: Inline formatting scatters locale decisions across every file and makes auditing impossible.

```tsx
// FORBIDDEN — inline toLocaleString
<span>{value.toLocaleString("ko-KR")}원</span>

// FORBIDDEN — manual Intl.NumberFormat in JSX
<span>{new Intl.NumberFormat("en-US").format(value)}</span>

// CORRECT — format utility
<span>{formatCurrency(value, { locale: "ko-KR", currency: "KRW" })}</span>
```

### FMT-02 — No Hardcoded Currency Symbols

NEVER write `₩`, `$`, or `원` directly in JSX templates. The format function handles symbol placement.
// WHY: Symbol placement rules differ by locale (prefix vs suffix). Hardcoding symbols breaks when locale changes.

```tsx
// FORBIDDEN — hardcoded symbol
<span>₩{value.toLocaleString()}</span>
<span>${amount}</span>
<span>{amount}원</span>

// CORRECT — format utility handles symbols
<span>{formatCurrency(value, { locale: "ko-KR", currency: "KRW" })}</span>
<span>{formatCurrency(amount, { locale: "en-US", currency: "USD" })}</span>
```

### FMT-03 — No Missing Locale Parameter

NEVER call a format function without an explicit locale. Do not rely on defaults.
// WHY: Implicit locale creates hidden coupling. Every call site must declare its intent — makes
// locale bugs visible in code review.

```tsx
// FORBIDDEN — no locale
formatCurrency(12500)

// CORRECT — explicit locale
formatCurrency(12500, { locale: "ko-KR", currency: "KRW" })
```

## Escape Hatch

If a formatting need is not covered by the existing utility functions:
1. STOP — do not format inline
2. Propose a new function signature for `@/lib/format` and ask for approval
3. After approval, add the function to `@/lib/format` with locale support
4. NEVER add one-off formatting logic in a component file
