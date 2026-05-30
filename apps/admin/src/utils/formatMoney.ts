/** Format integer cents as NT$ with thousands separators. */
export function formatMoney(cents: number | null | undefined): string {
  const n = Math.round(Number(cents ?? 0))
  return `NT$${n.toLocaleString('zh-TW')}`
}

export function formatMoneyPlain(cents: number | null | undefined): number {
  return Math.round(Number(cents ?? 0)) / 100
}

/** Ant Design Vue 4 Statistic formatter: receives `{ value }`, not the raw number. */
export function statMoneyFormatter({ value }: { value: number | string | null | undefined }): string {
  return formatMoneyPlain(Number(value)).toLocaleString('zh-TW', {
    style: 'currency',
    currency: 'TWD',
    maximumFractionDigits: 0,
  })
}
