import { test as base, type Page } from '@playwright/test'
import { acceptDialogs } from '../helpers/dialogs.js'
import { ensureShiftOpenUi, loginPosAndOpenShift } from '../helpers/pos-login.js'
import { productGrid } from '../helpers/selectors.js'
import { requireTerminalApiKey } from '../config/env.js'

type PosFixtures = {
  posPage: Page
}

export const test = base.extend<PosFixtures>({
  posPage: async ({ page }, use) => {
    acceptDialogs(page)
    await use(page)
  },
})

export { expect } from '@playwright/test'

/** Ensure authenticated cashier on POS home (reuses storageState when possible). */
export async function useCashierSession(page: Page) {
  acceptDialogs(page)
  await page.goto('')
  if (page.url().includes('/login')) {
    await loginPosAndOpenShift(page, { apiKey: requireTerminalApiKey() })
    return
  }
  if (page.url().includes('/shift')) {
    await ensureShiftOpenUi(page)
    return
  }
  await productGrid(page).waitFor({ state: 'visible', timeout: 20_000 }).catch(() => {})
}
