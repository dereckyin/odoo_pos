import { test, expect } from '@playwright/test'
import { existsSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { env } from '../../config/env.js'
import { loginAdmin } from '../../fixtures/admin-session.js'
import {
  cleanupE2eProducts,
  e2eProductSku,
  fetchDemoCategory,
  fillProductForm,
  submitProductForm,
  waitForProductFormReady,
} from '../../helpers/admin-products.js'
import { patchProductListLimit } from '../../helpers/catalog-route.js'
import { acceptDialogs } from '../../helpers/dialogs.js'
import { productGrid } from '../../helpers/selectors.js'

const cashierState = resolve(dirname(fileURLToPath(import.meta.url)), '../../.auth/cashier-pos.json')

test.describe('商品 POS 可見性', () => {
  const sku = e2eProductSku('POS')
  const name = `E2E POS 可見 ${sku}`

  test.beforeAll(async () => {
    test.skip(!process.env.ADMIN_PASSWORD, 'ADMIN_PASSWORD not set')
    test.skip(!process.env.POS_TERMINAL_API_KEY, 'POS_TERMINAL_API_KEY not set')
  })

  test.afterAll(async () => {
    await cleanupE2eProducts()
  })

  test('ADM-11 後台新建上架商品在 POS 全部與分類中可見', async ({ browser }) => {
    test.setTimeout(90_000)

    const snackCategory = await fetchDemoCategory('零食')

    const adminContext = await browser.newContext({ baseURL: env.adminBaseUrl })
    const adminPage = await adminContext.newPage()
    try {
      await loginAdmin(adminPage)
      await adminPage.goto('/products/create')
      await waitForProductFormReady(adminPage)
      await fillProductForm(adminPage, {
        name,
        sku,
        priceYuan: 55,
        categoryLabel: snackCategory.name,
      })
      await submitProductForm(adminPage, 'create')
    } finally {
      await adminContext.close()
    }

    const posContext = await browser.newContext({
      baseURL: env.posBaseUrl,
      storageState: existsSync(cashierState) ? cashierState : undefined,
    })
    const posPage = await posContext.newPage()
    acceptDialogs(posPage)
    try {
      await patchProductListLimit(posPage)

      const [productsRes] = await Promise.all([
        posPage.waitForResponse(
          (r) =>
            r.url().includes('/products') &&
            r.request().method() === 'GET' &&
            r.ok(),
          { timeout: 30_000 },
        ),
        posPage.goto(''),
      ])
      expect(productsRes.ok()).toBeTruthy()

      await expect(productGrid(posPage).getByRole('button').filter({ hasText: name }).first()).toBeVisible({
        timeout: 30_000,
      })

      await posPage.getByRole('button', { name: snackCategory.name, exact: true }).click()
      await expect(productGrid(posPage).getByRole('button').filter({ hasText: name }).first()).toBeVisible({
        timeout: 15_000,
      })

      await posPage.getByPlaceholder('搜尋商品 / SKU / 條碼').fill(sku)
      await expect(productGrid(posPage).getByRole('button').filter({ hasText: name }).first()).toBeVisible({
        timeout: 15_000,
      })
    } finally {
      await posContext.close()
    }
  })
})
