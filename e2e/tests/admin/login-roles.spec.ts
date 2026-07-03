import { test, expect } from '@playwright/test'
import { demoUsers } from '../../fixtures/demo-users.js'
import { loginAdmin } from '../../fixtures/admin-session.js'

test.describe('ADM-01 / ADM-02 後台登入權限', () => {
  test('tenant_admin 可登入並見管理選單', async ({ page }) => {
    test.skip(!process.env.ADMIN_PASSWORD, 'ADMIN_PASSWORD not set')

    await loginAdmin(page)
    await expect(page).toHaveURL(/\/(|$)/, { timeout: 15_000 })
    await expect(page.getByRole('menu').getByText('總覽')).toBeVisible()
    await expect(page.getByRole('menu').getByText('產品管理')).toBeVisible()
    await expect(page.getByRole('menu').getByText('門店帳號')).toBeVisible()
    await expect(page.getByRole('menu').getByText('租戶設定')).toBeVisible()
  })

  test('cashier 無法登入後台', async ({ page }) => {
    await page.goto('login')
    const { fillAdminLoginForm, submitAdminLogin } = await import('../../fixtures/admin-session.js')
    await fillAdminLoginForm(page, {
      username: demoUsers.cashier.username,
      password: demoUsers.cashier.password,
    })
    await submitAdminLogin(page)
    await expect(page.getByRole('alert')).toContainText(/insufficient permissions|沒有權限|權限/)
  })
})
