import type { FulfillmentMode } from './types'

export interface EntryParams {
  store: string
  mode: FulfillmentMode
  table: string
  lockedDineIn: boolean
}

export function parseEntryFromSearch(search: string): EntryParams {
  const q = new URLSearchParams(search.startsWith('?') ? search : `?${search}`)
  const store = (q.get('store') || '').trim()
  const table = (q.get('table') || '').trim()
  const rawMode = (q.get('mode') || '').trim().toLowerCase()

  let mode: FulfillmentMode = 'takeout'
  if (table) mode = 'dinein'
  else if (rawMode === 'dinein' || rawMode === 'dine_in') mode = 'dinein'
  else if (rawMode === 'delivery') mode = 'delivery'
  else if (rawMode === 'takeout' || rawMode === 'pickup') mode = 'takeout'

  return {
    store,
    mode,
    table: table || (mode === 'dinein' ? 'A5' : ''),
    lockedDineIn: Boolean(table),
  }
}

export function buildEntryQuery(params: {
  store?: string
  mode?: FulfillmentMode
  table?: string
}): Record<string, string> {
  const out: Record<string, string> = {}
  if (params.store) out.store = params.store
  if (params.mode) out.mode = params.mode === 'dinein' ? 'dinein' : params.mode
  if (params.table) out.table = params.table
  return out
}

/** Amounts are TWD integers (same convention as marketplace_*_cents fields in this monorepo). */
export function moneyYuan(amount: number): string {
  return Math.round(amount).toLocaleString('en-US')
}
