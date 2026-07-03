import type { Page, Locator } from '@playwright/test'
import { expect } from '@playwright/test'

export function posLoginForm(page: Page): Locator {
  return page.getByTestId('pos-login-form').or(page.locator('form.card'))
}

export function posLoginSubmit(page: Page): Locator {
  return page.getByTestId('pos-login-submit').or(page.getByRole('button', { name: '登入' }))
}

export function shiftOpenBtn(page: Page): Locator {
  return page.getByTestId('shift-open-btn').or(page.getByRole('button', { name: '開始收銀' }))
}

export function productGrid(page: Page): Locator {
  return page.getByTestId('product-grid').or(page.locator('.cashier .grid'))
}

export function cartCheckoutBtn(page: Page): Locator {
  return page.getByTestId('cart-checkout-btn').or(page.getByRole('button', { name: '結帳' }))
}

export function checkoutConfirmBtn(page: Page): Locator {
  return page.getByTestId('checkout-confirm').or(page.getByRole('button', { name: '確認收款' }))
}

export function tableGrid(page: Page): Locator {
  return page.getByTestId('table-grid').or(page.locator('.tables-page .grid'))
}

export function customerOrderLink(page: Page): Locator {
  return page.getByTestId('customer-order-link').or(page.locator('.result a[href*="customer"]'))
}

export function kdsOrderCards(page: Page): Locator {
  return page.getByTestId('kds-order-card').or(page.locator('.kds article.card'))
}

export function kdsAcceptBtn(card: Locator): Locator {
  return card.getByTestId('kds-accept-btn').or(card.getByRole('button', { name: '接單並列印' }))
}

export function customerTableTag(page: Page): Locator {
  return page.getByTestId('customer-table-tag').or(page.locator('.table-tag'))
}

export function customerSubmitOrder(page: Page): Locator {
  return page.getByTestId('customer-submit-order').or(page.getByRole('button', { name: '送出點餐' }))
}

export async function waitForCatalogReady(page: Page) {
  await productGrid(page).waitFor({ state: 'visible', timeout: 20_000 })
  if ((await productGrid(page).getByRole('button').count()) > 0) return

  await page.waitForResponse((r) => r.url().includes('/products') && r.ok(), { timeout: 30_000 }).catch(
    () => {},
  )
  await expect(productGrid(page).getByRole('button').first()).toBeVisible({ timeout: 30_000 })
}

/** Wait until catalog products appear (API may lag after login). */
export async function waitForCatalogProduct(page: Page, productName: string) {
  await waitForCatalogReady(page)
  const productBtn = productGrid(page).getByRole('button').filter({ hasText: productName })
  if (await productBtn.count()) {
    return productBtn.first()
  }
  await page.getByPlaceholder('搜尋商品 / SKU / 條碼').fill(productName)
  await expect(productGrid(page).getByRole('button').filter({ hasText: productName }).first()).toBeVisible({
    timeout: 15_000,
  })
  return productGrid(page).getByRole('button').filter({ hasText: productName }).first()
}

export function adminLoginForm(page: Page): Locator {
  return page.getByTestId('admin-login-form').or(page.locator('form'))
}
