import { test, expect } from '../../fixtures/pos-session.js'
import { fillPosLoginForm, submitPosLogin, ensureShiftOpenUi } from '../../helpers/pos-login.js'
import { requireTerminalApiKey } from '../../config/env.js'
import { demoUsers } from '../../fixtures/demo-users.js'
import { posLoginForm, productGrid } from '../../helpers/selectors.js'

test.describe('POS-01 登入', () => {
  test.use({ storageState: { cookies: [], origins: [] } })

  test('錯誤 API Key 應顯示登入失敗', async ({ posPage: page }) => {
    await page.goto('login')
    await fillPosLoginForm(page, { apiKey: 'invalid-api-key-for-e2e' })
    await submitPosLogin(page)
    await expect(page.locator('.error')).toContainText(/登入失敗|invalid|認證/)
  })

  test('正確登入並開班後進入收銀畫面', async ({ posPage: page }) => {
    test.skip(!process.env.POS_TERMINAL_API_KEY, 'POS_TERMINAL_API_KEY not set')

    await page.goto('login')
    await fillPosLoginForm(page, { apiKey: requireTerminalApiKey() })
    await submitPosLogin(page)
    await ensureShiftOpenUi(page)
    await expect(productGrid(page)).toBeVisible({ timeout: 20_000 })
    await expect(page.getByText(demoUsers.cashier.displayName)).toBeVisible()
  })
})

test.describe('POS-04 登出', () => {
  test.beforeEach(async ({ posPage: page }) => {
    test.skip(!process.env.POS_TERMINAL_API_KEY, 'POS_TERMINAL_API_KEY not set')
    const { useCashierSession } = await import('../../fixtures/pos-session.js')
    await useCashierSession(page)
  })

  test('登出後回到登入頁', async ({ posPage: page }) => {
    await page.getByRole('button', { name: '登出' }).click()
    await expect(page).toHaveURL(/\/login\/?/)
    await expect(posLoginForm(page)).toBeVisible()
  })
})
