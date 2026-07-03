import { test, expect } from '../../fixtures/pos-session.js'
import { useCashierSession } from '../../fixtures/pos-session.js'
import { patchProductListLimit } from '../../helpers/catalog-route.js'
import { cartCheckoutBtn, checkoutConfirmBtn, productGrid } from '../../helpers/selectors.js'

test.describe('POS-03 點餐結帳', () => {
  test.beforeEach(async ({ posPage: page }) => {
    test.skip(!process.env.POS_TERMINAL_API_KEY, 'POS_TERMINAL_API_KEY not set')
    await patchProductListLimit(page)
    await useCashierSession(page)
  })

  test('現金結帳（不開發票）後購物車清空', async ({ posPage: page }) => {
    test.setTimeout(60_000)

    const [productsRes] = await Promise.all([
      page.waitForResponse(
        (r) =>
          r.url().includes('/products') &&
          r.request().method() === 'GET' &&
          r.ok(),
        { timeout: 30_000 },
      ),
      page.goto(''),
    ])

    const products = (await productsRes.json()) as Array<{ name: string }>
    expect(products.length, 'no products returned from API').toBeGreaterThan(0)

    const targetName = products.find((p) => p.name.includes('礦泉水'))?.name ?? products[0].name
    const productBtn = productGrid(page).getByRole('button').filter({ hasText: targetName })
    await expect(productBtn.first()).toBeVisible({ timeout: 30_000 })
    await productBtn.first().click()

    await expect(page.locator('.cart .count')).toContainText('1 項')

    await cartCheckoutBtn(page).click()
    await expect(page.getByRole('heading', { name: '結帳' })).toBeVisible()

    await page.locator('label:has-text("開立電子發票") input[type="checkbox"]').uncheck()
    await checkoutConfirmBtn(page).click()

    await expect(page.locator('.cart .empty')).toBeVisible({ timeout: 20_000 })
    await expect(page.locator('.cart .count')).toContainText('0 項')
  })
})
