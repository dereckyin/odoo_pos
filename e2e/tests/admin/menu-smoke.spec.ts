import { test, expect, request as playwrightRequest } from '@playwright/test'
import { requireTerminalApiKey } from '../../config/env.js'
import { apiPosLogin } from '../../helpers/api.js'
import { apiUrl } from '../../helpers/api-url.js'
import { loginAdmin } from '../../fixtures/admin-session.js'

test.describe('ADM-03 後台 smoke', () => {
  test.beforeEach(async ({ page }) => {
    test.skip(!process.env.ADMIN_PASSWORD, 'ADMIN_PASSWORD not set')
    await loginAdmin(page)
  })

  test('可進入商品列表', async ({ page }) => {
    await page.goto('/products')
    await expect(page.locator('.ant-page-header-heading-title').filter({ hasText: '商品列表' })).toBeVisible({ timeout: 15_000 })
    await expect(page.locator('.ant-table').first()).toBeVisible()
  })

  test('可進入訂單查詢', async ({ page }) => {
    await page.goto('/orders')
    await expect(page.locator('.ant-page-header-heading-title').filter({ hasText: '訂單查詢' })).toBeVisible({ timeout: 15_000 })
  })
})

test.describe('ADM-04 API 權限', () => {
  test('cashier token 無法建立商品', async () => {
    test.skip(!process.env.POS_TERMINAL_API_KEY, 'POS_TERMINAL_API_KEY not set')

    const ctx = await playwrightRequest.newContext()
    try {
      const session = await apiPosLogin(ctx, requireTerminalApiKey())
      const res = await ctx.post(apiUrl('/products'), {
        headers: { Authorization: `Bearer ${session.access_token}` },
        data: {
          name: 'e2e-forbidden-product',
          sku: `E2E-${Date.now()}`,
          price_cents: 100,
          tax_rate: 0.05,
          is_active: true,
        },
      })
      expect(res.status()).toBe(403)
    } finally {
      await ctx.dispose()
    }
  })
})
