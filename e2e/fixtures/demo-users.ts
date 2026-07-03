import { env } from '../config/env.js'

export const demoUsers = {
  tenantCode: env.tenantCode,
  storeCode: env.storeCode,
  terminalCode: env.terminalCode,

  cashier: {
    username: env.cashierUser,
    password: env.cashierPassword,
    displayName: '收銀員',
    role: 'cashier',
  },

  admin: {
    username: env.adminUser,
    password: env.adminPassword,
    displayName: '管理員',
    role: 'tenant_admin',
  },
} as const

/** Stable seed product for checkout tests. */
export const sampleProductName = '礦泉水 600ml'
