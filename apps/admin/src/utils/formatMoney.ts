/**
 * Money amounts for TWD are stored in whole dollars (元) in `*_cents` fields —
 * see pos_core Money._minorUnits (TWD => 1). Do not divide by 100.
 */
export function formatMoney(cents: number | null | undefined): string {
  const n = Math.round(Number(cents ?? 0))
  return `NT$${n.toLocaleString('zh-TW')}`
}

/** Numeric major-unit amount for charts / Statistic formatters (TWD: same as stored value). */
export function formatMoneyPlain(cents: number | null | undefined): number {
  return Math.round(Number(cents ?? 0))
}

/** Ant Design Vue 4 Statistic formatter: receives `{ value }`, not the raw number. */
export function statMoneyFormatter({ value }: { value: number | string | null | undefined }): string {
  return formatMoneyPlain(Number(value)).toLocaleString('zh-TW', {
    style: 'currency',
    currency: 'TWD',
    maximumFractionDigits: 0,
  })
}
