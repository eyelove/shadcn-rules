interface FormatOptions {
  locale: "ko-KR" | "en-US"
  currency?: "KRW" | "USD"
}

export function formatNumber(value: number, options: FormatOptions): string {
  return new Intl.NumberFormat(options.locale).format(value)
}

export function formatCurrency(value: number, options: FormatOptions): string {
  if (options.locale === "ko-KR" && options.currency === "KRW") {
    return `${new Intl.NumberFormat("ko-KR", { maximumFractionDigits: 0 }).format(value)}\u{C6D0}`
  }
  return new Intl.NumberFormat(options.locale, {
    style: "currency",
    currency: options.currency ?? "USD",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value)
}

export function formatCurrencyCompact(value: number, options: FormatOptions): string {
  if (options.locale === "ko-KR" && options.currency === "KRW") {
    return formatKoCompact(value) + "\u{C6D0}"
  }
  return formatEnCompactCurrency(value, options.currency ?? "USD")
}

export function formatCompact(value: number, options: FormatOptions): string {
  if (options.locale === "ko-KR") {
    return formatKoCompact(value)
  }
  return formatEnCompact(value)
}

export function formatPercent(value: number, _options: FormatOptions): string {
  return (value * 100).toFixed(2) + "%"
}

export function formatDelta(value: number): string {
  const formatted = (value * 100).toFixed(1)
  const sign = Number(formatted) > 0 ? "+" : ""
  return `${sign}${formatted}%`
}

function formatKoCompact(value: number): string {
  const abs = Math.abs(value)
  const sign = value < 0 ? "-" : ""

  if (abs >= 1_0000_0000) {
    const v = abs / 1_0000_0000
    return sign + (v % 1 === 0 ? v.toFixed(0) : v.toFixed(1).replace(/\.0$/, "")) + "\u{C5B5}"
  }
  if (abs >= 1_0000) {
    const v = abs / 1_0000
    if (v >= 1000) {
      return sign + new Intl.NumberFormat("ko-KR").format(Math.round(v)) + "\u{B9CC}"
    }
    return sign + (v % 1 === 0 ? v.toFixed(0) : v.toFixed(1).replace(/\.0$/, "")) + "\u{B9CC}"
  }
  return sign + new Intl.NumberFormat("ko-KR").format(value)
}

function formatEnCompact(value: number): string {
  const abs = Math.abs(value)
  const sign = value < 0 ? "-" : ""

  if (abs >= 1_000_000_000) {
    const v = abs / 1_000_000_000
    return sign + (v % 1 === 0 ? v.toFixed(0) : v.toFixed(1).replace(/\.0$/, "")) + "B"
  }
  if (abs >= 1_000_000) {
    const v = abs / 1_000_000
    return sign + (v % 1 === 0 ? v.toFixed(0) : v.toFixed(1).replace(/\.0$/, "")) + "M"
  }
  if (abs >= 1_000) {
    const v = abs / 1_000
    return sign + (v % 1 === 0 ? v.toFixed(0) : v.toFixed(1).replace(/\.0$/, "")) + "K"
  }
  return sign + value.toString()
}

function formatEnCompactCurrency(value: number, currency: string): string {
  const symbol = currency === "USD" ? "$" : currency
  return symbol + formatEnCompact(value)
}

interface DateFormatOptions {
  locale: "ko-KR" | "en-US"
  format?: "default" | "long" | "slash"
}

export function formatDate(date: Date, options: DateFormatOptions): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, "0")
  const d = String(date.getDate()).padStart(2, "0")

  if (options.locale === "ko-KR") {
    switch (options.format) {
      case "long":
        return `${y}\u{B144} ${m}\u{C6D4} ${d}\u{C77C}`
      case "slash":
        return `${y}/${m}/${d}`
      default:
        return `${y}-${m}-${d}`
    }
  }

  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  return `${months[date.getMonth()]} ${date.getDate()}, ${y}`
}
