/**
 * TWD amounts are stored as whole dollars (元) in `*_cents` fields —
 * see pos_core Money._minorUnits (TWD => 1). Do not divide by 100.
 */
export function formatMoney(cents: number | null | undefined): string {
  const n = Math.round(Number(cents ?? 0))
  return `$${n.toLocaleString('zh-TW')}`
}
