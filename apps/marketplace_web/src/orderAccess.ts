const KEY = 'mp_order_tokens'
const GROUP_KEY = 'mp_order_groups'

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

export interface GroupOrderRef {
  order_id: string
  access_token: string
}

export function saveOrderGroup(groupId: string, orders: GroupOrderRef[]) {
  const map = loadGroups()
  map[groupId] = orders
  localStorage.setItem(GROUP_KEY, JSON.stringify(map))
}

export function getOrderGroup(groupId: string): GroupOrderRef[] {
  return loadGroups()[groupId] ?? []
}

function loadGroups(): Record<string, GroupOrderRef[]> {
  try {
    return JSON.parse(localStorage.getItem(GROUP_KEY) || '{}')
  } catch {
    return {}
  }
}
