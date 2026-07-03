import type { Page } from '@playwright/test'
import { env } from '../config/env.js'
import { adminLoginForm } from '../helpers/selectors.js'

export interface AdminLoginOptions {
  tenantCode?: string
  username?: string
  password?: string
}

export async function fillAdminLoginForm(page: Page, opts: AdminLoginOptions = {}) {
  const tenant = opts.tenantCode ?? env.tenantCode
  const username = opts.username ?? env.adminUser
  const password = opts.password ?? env.adminPassword

  await page.getByLabel('租戶代號').fill(tenant)
  await page.getByLabel('帳號', { exact: true }).fill(username)
  await page.getByLabel('密碼', { exact: true }).fill(password)
}

export async function submitAdminLogin(page: Page) {
  await adminLoginForm(page).getByRole('button', { name: /登\s*入/ }).click()
}

export async function loginAdmin(page: Page, opts: AdminLoginOptions = {}) {
  await page.goto('login')
  await fillAdminLoginForm(page, opts)
  await submitAdminLogin(page)
  await page.waitForURL((url) => !url.pathname.includes('/login'), { timeout: 15_000 })
  await page.locator('.ant-layout-sider, .app-sider').first().waitFor({ state: 'visible', timeout: 15_000 })
}
