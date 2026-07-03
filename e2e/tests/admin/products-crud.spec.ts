import { test, expect, request as playwrightRequest } from '@playwright/test'
import { loginAdmin } from '../../fixtures/admin-session.js'
import { apiAdminLogin } from '../../helpers/api.js'
import { apiUrl } from '../../helpers/api-url.js'
import {
  assertProductViaApi,
  cleanupE2eProducts,
  confirmPopconfirm,
  deleteProductFromList,
  e2eProductName,
  e2eProductSku,
  fillProductForm,
  gotoProductList,
  gotoProductEdit,
  productRowAction,
  productTableRow,
  searchProducts,
  setProductName,
  setProductPriceYuan,
  submitProductForm,
  waitForProductFormReady,
  productFormSubmit,
} from '../../helpers/admin-products.js'

test.describe.configure({ mode: 'serial' })

test.describe('ADM-05~08 商品 CRUD', () => {
  const sku = e2eProductSku('CRUD')
  const initialName = e2eProductName(sku)
  const updatedName = `${initialName}（已修改）`
  const barcode = `BC${sku.replace(/-/g, '')}`
  let productId = ''

  test.beforeAll(async () => {
    test.skip(!process.env.ADMIN_PASSWORD, 'ADMIN_PASSWORD not set')
    await cleanupE2eProducts()
  })

  test.afterAll(async () => {
    await cleanupE2eProducts()
  })

  test.beforeEach(async ({ page }) => {
    test.skip(!process.env.ADMIN_PASSWORD, 'ADMIN_PASSWORD not set')
    await loginAdmin(page)
  })

  test('ADM-05 新增商品：必填欄位驗證與建立', async ({ page }) => {
    test.setTimeout(60_000)
    await page.goto('/products/create')
    await expect(page.locator('.ant-page-header-heading-title').filter({ hasText: '新增商品' })).toBeVisible()
    await waitForProductFormReady(page)

    await productFormSubmit(page).click()
    await expect(page.locator('.ant-form-item-explain-error').first()).toBeVisible()

    await fillProductForm(page, {
      name: initialName,
      sku,
      priceYuan: 88,
      description: 'E2E 自動化測試用商品',
      barcode,
    })

    const createRes = page.waitForResponse(
      (r) => r.url().includes('/products') && r.request().method() === 'POST' && r.ok(),
      { timeout: 20_000 },
    )
    await submitProductForm(page, 'create')
    const created = await (await createRes).json()
    productId = created.id as string

    await searchProducts(page, sku)
    const row = productTableRow(page, sku)
    await expect(row).toHaveCount(1)
    await expect(row).toContainText(initialName)
    await expect(row).toContainText('NT$88')
    await expect(row.locator('.ant-tag').filter({ hasText: '上架' })).toBeVisible()
    await expect(row.locator('.ant-tag').filter({ hasText: barcode })).toBeVisible()

    await assertProductViaApi(productId, {
      name: initialName,
      sku,
      price_cents: 88,
      is_active: true,
    })
  })

  test('ADM-06 編輯商品：修改名稱與售價', async ({ page }) => {
    test.setTimeout(60_000)
    test.skip(!productId, 'create step did not run')

    await gotoProductEdit(page, productId)

    await setProductName(page, updatedName)
    await setProductPriceYuan(page, 99)

    const patchRes = page.waitForResponse(
      (r) =>
        r.url().includes(`/products/${productId}`) &&
        r.request().method() === 'PATCH' &&
        !r.url().includes('option'),
      { timeout: 20_000 },
    )
    await submitProductForm(page, 'edit')
    const patch = await patchRes
    expect(patch.ok(), `product PATCH failed: ${patch.status()}`).toBeTruthy()
    const patched = (await patch.json()) as { name: string; price_cents: number; hide_from_pos_browse?: boolean }
    expect(patched.name).toBe(updatedName)
    expect(patched.price_cents).toBe(99)

    await gotoProductList(page)
    await searchProducts(page, sku)
    const row = productTableRow(page, sku)
    await expect(row).toContainText(updatedName)
    await expect(row).toContainText('NT$99')

    await assertProductViaApi(productId, {
      name: updatedName,
      price_cents: 99,
    })
  })

  test('ADM-06b 編輯商品：POS 隱藏開關', async ({ page }) => {
    test.setTimeout(60_000)
    test.skip(!productId, 'create step did not run')

    await gotoProductEdit(page, productId)
    const posBrowseSwitch = page
      .locator('.ant-form-item')
      .filter({ hasText: '不顯示於 POS「全部」瀏覽' })
      .locator('.ant-switch')
    if ((await posBrowseSwitch.getAttribute('aria-checked')) !== 'true') {
      await posBrowseSwitch.click()
    }
    await submitProductForm(page, 'edit')

    await assertProductViaApi(productId, { hide_from_pos_browse: true })
  })

  test('ADM-07 列表操作：搜尋與上架/下架', async ({ page }) => {
    test.setTimeout(60_000)
    test.skip(!productId, 'create step did not run')

    await gotoProductList(page)
    await searchProducts(page, sku)

    const row = productTableRow(page, sku)
    await productRowAction(page, row, '下架').click()
    await expect(page.locator('.ant-message-success').filter({ hasText: '已下架' })).toBeVisible()
    await expect(row.locator('.ant-tag').filter({ hasText: '下架' })).toBeVisible()

    await assertProductViaApi(productId, { is_active: false })

    await productRowAction(page, row, '上架').click()
    await expect(page.locator('.ant-message-success').filter({ hasText: '已上架' })).toBeVisible()
    await expect(row.locator('.ant-tag').filter({ hasText: '上架' })).toBeVisible()

    await assertProductViaApi(productId, { is_active: true })
  })

  test('ADM-08 刪除商品：確認後從列表消失且 API 404', async ({ page }) => {
    test.setTimeout(60_000)
    test.skip(!productId, 'create step did not run')

    await deleteProductFromList(page, sku)
    await searchProducts(page, sku, { requireRow: false })
    await expect(productTableRow(page, sku)).toHaveCount(0)

    const { withAdminApi } = await import('../../helpers/admin-products.js')
    const { apiGetProduct } = await import('../../helpers/api.js')
    await withAdminApi(async (ctx, token) => {
      const product = await apiGetProduct(ctx, token, productId)
      expect(product).toBeNull()
    })
    productId = ''
  })
})

test.describe('ADM-05b 重複 SKU', () => {
  test.beforeEach(async ({ page }) => {
    test.skip(!process.env.ADMIN_PASSWORD, 'ADMIN_PASSWORD not set')
    await loginAdmin(page)
  })

  test('建立重複 SKU 應顯示錯誤', async ({ page }) => {
    test.setTimeout(60_000)

    const ctx = await playwrightRequest.newContext()
    let existingSku = ''
    try {
      const session = await apiAdminLogin(ctx)
      const list = await ctx.get(apiUrl('/products?limit=1'), {
        headers: { Authorization: `Bearer ${session.access_token}` },
      })
      expect(list.ok()).toBeTruthy()
      const products = (await list.json()) as Array<{ sku: string; name: string }>
      expect(products.length).toBeGreaterThan(0)
      existingSku = products[0].sku

      await page.goto('/products/create')
      await waitForProductFormReady(page)
      await fillProductForm(page, {
        name: `E2E 重複 SKU 測試 ${Date.now()}`,
        sku: existingSku,
        priceYuan: 60,
      })

      const dupRes = page.waitForResponse(
        (r) => r.url().includes('/products') && r.request().method() === 'POST',
        { timeout: 20_000 },
      )
      await productFormSubmit(page).click()
      const response = await dupRes
      expect(response.status(), 'duplicate SKU should be rejected').toBeGreaterThanOrEqual(400)
      await expect(page).toHaveURL(/\/products\/create/)
    } finally {
      await ctx.dispose()
    }
  })
})
