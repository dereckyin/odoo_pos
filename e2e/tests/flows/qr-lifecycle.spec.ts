import { test, expect } from '@playwright/test'
import { existsSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { env } from '../../config/env.js'
import { requireTerminalApiKey } from '../../config/env.js'
import { acceptDialogs } from '../../helpers/dialogs.js'
import { apiPosLogin, ensureShiftOpen, listTables, openTableSession, onlineOrderingEnabled } from '../../helpers/api.js'
import { sampleProductName } from '../../fixtures/demo-users.js'
import {
  customerSubmitOrder,
  customerTableTag,
  kdsAcceptBtn,
  kdsOrderCards,
} from '../../helpers/selectors.js'

const cashierState = resolve(dirname(fileURLToPath(import.meta.url)), '../../.auth/cashier-pos.json')

test.describe('QR 桌邊點餐全流程', () => {
  test.beforeEach(() => {
    test.skip(!process.env.POS_TERMINAL_API_KEY, 'POS_TERMINAL_API_KEY not set')
    test.skip(!onlineOrderingEnabled(), 'online_ordering module disabled')
  })

  test('開桌 → 顧客送單 → KDS 接單', async ({ browser, request }) => {
    const apiKey = requireTerminalApiKey()
    const session = await apiPosLogin(request, apiKey)
    await ensureShiftOpen(request, session.access_token)

    const tables = await listTables(request, session.access_token, session.store_id)
    test.skip(!tables.length, 'no dining tables in demo store')

    const opened = await openTableSession(request, session.access_token, tables[0].id)
    const customerUrl = opened.customer_order_url

    const customerContext = await browser.newContext({
      baseURL: env.customerBaseUrl,
    })
    const customerPage = await customerContext.newPage()
    try {
      await customerPage.goto(customerUrl)
      await expect(customerTableTag(customerPage)).toBeVisible({ timeout: 20_000 })

      await customerPage.getByText(sampleProductName).first().click()
      const cartBar = customerPage.locator('.cart-bar')
      await expect(cartBar).toBeVisible({ timeout: 10_000 })
      await cartBar.click()
      await expect(customerPage.locator('.cart-page')).toBeVisible({ timeout: 10_000 })
      await customerSubmitOrder(customerPage).click()
      await expect(customerPage).toHaveURL(/\/status\//, { timeout: 20_000 })
    } finally {
      await customerContext.close()
    }

    const posContext = await browser.newContext({
      baseURL: env.posBaseUrl,
      storageState: existsSync(cashierState) ? cashierState : undefined,
    })
    const posPage = await posContext.newPage()
    acceptDialogs(posPage)
    try {
      await posPage.goto('kds')
      await posPage.getByRole('button', { name: '重新整理' }).click()

      const card = kdsOrderCards(posPage)
        .filter({ hasText: sampleProductName })
        .filter({ hasText: '新訂單' })
        .first()
      await expect(card).toBeVisible({ timeout: 30_000 })

      await kdsAcceptBtn(card).click()
      const accepted = kdsOrderCards(posPage)
        .filter({ hasText: sampleProductName })
        .filter({ has: posPage.locator('.status', { hasText: '製作中' }) })
        .first()
      await expect(accepted).toBeVisible({ timeout: 20_000 })

      await accepted.getByRole('button', { name: '出餐完成' }).click()
      await expect(
        kdsOrderCards(posPage).filter({ hasText: sampleProductName }).filter({ hasText: '待送達' }).first(),
      ).toBeVisible({ timeout: 15_000 })
    } finally {
      await posContext.close()
    }
  })
})
