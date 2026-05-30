const KEY = 'mp_order_tokens'

export function saveOrderAccess(orderId: string, accessToken: string) {
  const map = loadAll()
  map[orderId] = accessToken
  localStorage.setItem(KEY, JSON.stringify(map))
}

export function getOrderAccess(orderId: string): string | null {
  return loadAll()[orderId] ?? null
}

function loadAll(): Record<string, string> {
  try {
    return JSON.parse(localStorage.getItem(KEY) || '{}')
  } catch {
    return {}
  }
}
