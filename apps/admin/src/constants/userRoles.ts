/** Roles assignable from 門店帳號 → 使用者管理 (matches API ALL_ROLES minus platform_super). */
export const USER_ROLE_OPTIONS = [
  { value: 'tenant_admin', label: '租戶管理員' },
  { value: 'store_manager', label: '店長' },
  { value: 'cashier', label: '收銀員' },
  { value: 'kitchen', label: '廚房' },
] as const

export type AssignableUserRole = (typeof USER_ROLE_OPTIONS)[number]['value']

export const USER_ROLE_LABELS: Record<string, string> = {
  tenant_owner: '店主',
  tenant_admin: '租戶管理員',
  store_manager: '店長',
  cashier: '收銀員',
  kitchen: '廚房',
  /** Legacy UI values; normalize to tenant_admin / store_manager on save. */
  admin: '租戶管理員',
  manager: '店長',
}

/** Map legacy role strings to API roles when loading the edit form. */
export function normalizeRoleForApi(role: string): AssignableUserRole {
  if (role === 'admin') return 'tenant_admin'
  if (role === 'manager') return 'store_manager'
  if (USER_ROLE_OPTIONS.some((o) => o.value === role)) return role as AssignableUserRole
  return 'cashier'
}

export const USER_ROLE_TAG_COLOR: Record<string, string> = {
  tenant_owner: 'red',
  tenant_admin: 'red',
  admin: 'red',
  store_manager: 'blue',
  manager: 'blue',
  cashier: 'green',
  kitchen: 'purple',
}

export function userRoleLabel(role: string): string {
  return USER_ROLE_LABELS[role] ?? role
}

export function userRoleTagColor(role: string): string {
  return USER_ROLE_TAG_COLOR[role] ?? 'default'
}
