import { test as setup } from '@playwright/test'
import { mkdirSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { requireTerminalApiKey } from '../../config/env.js'
import { acceptDialogs } from '../../helpers/dialogs.js'
import { ensureShiftOpenUi, fillPosLoginForm, submitPosLogin } from '../../helpers/pos-login.js'

const authFile = resolve(dirname(fileURLToPath(import.meta.url)), '../../.auth/cashier-pos.json')

setup('cashier POS session', async ({ page }) => {
  setup.skip(!process.env.POS_TERMINAL_API_KEY, 'POS_TERMINAL_API_KEY not set')
  mkdirSync(dirname(authFile), { recursive: true })
  acceptDialogs(page)
  await page.goto('login')
  await fillPosLoginForm(page, { apiKey: requireTerminalApiKey() })
  await submitPosLogin(page)
  await ensureShiftOpenUi(page)
  await page.locator('.topbar').waitFor({ state: 'visible', timeout: 15_000 })
  await page.context().storageState({ path: authFile })
})

export { authFile }
