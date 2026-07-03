import type { Page } from '@playwright/test'
import { env, requireTerminalApiKey } from '../config/env.js'
import { demoUsers } from '../fixtures/demo-users.js'
import { posLoginSubmit, shiftOpenBtn } from './selectors.js'

export interface PosLoginOptions {
  apiKey?: string
  username?: string
  password?: string
}

export async function fillPosLoginForm(page: Page, opts: PosLoginOptions = {}) {
  const apiKey = opts.apiKey ?? requireTerminalApiKey()
  const username = opts.username ?? demoUsers.cashier.username
  const password = opts.password ?? demoUsers.cashier.password

  await page.getByLabel('租戶代碼').fill(env.tenantCode)
  await page.getByLabel('門市代碼').fill(env.storeCode)
  await page.getByLabel('終端代碼').fill(env.terminalCode)
  await page.getByLabel('終端 API Key').fill(apiKey)
  await page.getByLabel('帳號', { exact: true }).fill(username)
  await page.getByLabel('密碼', { exact: true }).fill(password)
}

export async function submitPosLogin(page: Page) {
  await posLoginSubmit(page).click()
  await page.waitForURL(/\/(shift|pos)\/?/, { timeout: 15_000 })
}

export async function loginPos(page: Page, opts: PosLoginOptions = {}) {
  await page.goto('login')
  await fillPosLoginForm(page, opts)
  await submitPosLogin(page)
}

export async function ensureShiftOpenUi(page: Page) {
  await page.waitForURL(/\/(shift|pos)\/?/, { timeout: 15_000 })
  if (page.url().includes('/shift')) {
    await shiftOpenBtn(page).click()
    await page.locator('.topbar').waitFor({ state: 'visible', timeout: 20_000 })
  }
}

export async function loginPosAndOpenShift(page: Page, opts: PosLoginOptions = {}) {
  await page.goto('')
  if (page.url().includes('/login')) {
    await loginPos(page, opts)
    await ensureShiftOpenUi(page)
  } else if (page.url().includes('/shift')) {
    await ensureShiftOpenUi(page)
  }
  await page.locator('.topbar').waitFor({ state: 'visible', timeout: 15_000 })
}
