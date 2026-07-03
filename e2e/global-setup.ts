import { request } from '@playwright/test'
import { env, requireTerminalApiKey } from './config/env.js'
import { apiAdminLogin, apiPosLogin } from './helpers/api.js'
import { apiUrl } from './helpers/api-url.js'

export default async function globalSetup() {
  let apiKey: string
  try {
    apiKey = requireTerminalApiKey()
  } catch {
    console.warn('[e2e] POS_TERMINAL_API_KEY not set — POS login tests will fail')
    return
  }

  const ctx = await request.newContext()
  try {
    try {
      await apiPosLogin(ctx, apiKey)
    } catch (e) {
      console.warn(`[e2e] global-setup: POS login failed — ${(e as Error).message}`)
    }

    if (process.env.ADMIN_PASSWORD) {
      try {
        const adminSession = await apiAdminLogin(ctx)
        const modsRes = await ctx.get(apiUrl('/tenant/modules'), {
          headers: { Authorization: `Bearer ${adminSession.access_token}` },
        })
        const contentType = modsRes.headers()['content-type'] ?? ''
        if (modsRes.ok() && contentType.includes('application/json')) {
          const mods = await modsRes.json()
          process.env.E2E_ONLINE_ORDERING = String(!!mods.online_ordering)
          console.log(`[e2e] modules: online_ordering=${process.env.E2E_ONLINE_ORDERING}`)
        } else {
          process.env.E2E_ONLINE_ORDERING = 'true'
        }
        const { setCachedAdminToken } = await import('./helpers/api.js')
        setCachedAdminToken(adminSession.access_token)
      } catch (e) {
        console.warn(`[e2e] global-setup: admin/modules skipped — ${(e as Error).message}`)
        process.env.E2E_ONLINE_ORDERING = 'true'
      }
    } else {
      process.env.E2E_ONLINE_ORDERING = 'true'
    }
  } finally {
    await ctx.dispose()
  }
}
