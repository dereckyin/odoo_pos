import { expect, type APIRequestContext, type Page } from '@playwright/test'
import {
  apiAdminLogin,
  apiCleanupProductsBySkuPrefix,
  apiGetProduct,
  apiListProducts,
  type ProductRead,
} from './api.js'
import { apiUrl } from './api-url.js'

export const E2E_PRODUCT_SKU_PREFIX = 'E2E-'

export function e2eProductSku(tag: string, suffix = Date.now().toString(36)) {
  return `${E2E_PRODUCT_SKU_PREFIX}${tag}-${suffix}`
}

export function e2eProductName(sku: string) {
  return `E2E 測試商品 ${sku}`
}

export interface DemoCategory {
  id: string
  name: string
  path_label: string
}

export async function fetchDemoCategory(name = '零食'): Promise<DemoCategory> {
  return withAdminApi(async (ctx, token) => {
    const res = await ctx.get(apiUrl('/categories/tree'), {
      headers: { Authorization: `Bearer ${token}` },
    })
    if (!res.ok()) throw new Error(`categories tree failed: ${res.status()}`)
    const tree = (await res.json()) as Array<{
      id: string
      name: string
      path_label?: string
      children?: typeof tree
    }>

    function walk(nodes: typeof tree): DemoCategory | null {
      for (const n of nodes) {
        const path = n.path_label || n.name
        if (n.name === name || path === name) {
          return { id: n.id, name: n.name, path_label: path }
        }
        if (n.children?.length) {
          const found = walk(n.children)
          if (found) return found
        }
      }
      return null
    }

    const cat = walk(tree)
    if (!cat) throw new Error(`category not found: ${name}`)
    return cat
  })
}

export function productCategoryField(page: Page) {
  return page.locator('.ant-form-item').filter({
    has: page.locator('label').filter({ hasText: /^分類$/ }),
  })
}

export async function selectProductCategory(page: Page, categoryLabel: string) {
  const field = productCategoryField(page)
  await expect(field).toBeVisible({ timeout: 10_000 })
  await field.locator('.ant-select-selector').first().click()
  const node = page
    .locator('.ant-select-dropdown:visible .ant-select-tree-title')
    .filter({ hasText: categoryLabel })
    .first()
  await node.scrollIntoViewIfNeeded()
  await node.click()
}

export async function gotoProductImport(page: Page) {
  await page.goto('/products/import')
  await expect(page.locator('.ant-page-header-heading-title').filter({ hasText: 'CSV 批次匯入' })).toBeVisible({
    timeout: 15_000,
  })
}

export async function uploadProductCsv(page: Page, csvContent: string) {
  const importRes = page.waitForResponse(
    (r) => r.url().includes('/products/import-csv') && r.request().method() === 'POST',
    { timeout: 30_000 },
  )
  await page.locator('.ant-upload input[type="file"]').setInputFiles({
    name: 'e2e-import.csv',
    mimeType: 'text/csv',
    buffer: Buffer.from(`\uFEFF${csvContent}`, 'utf-8'),
  })
  const response = await importRes
  expect(response.ok(), `CSV import failed: ${response.status()}`).toBeTruthy()
  await expect(page.locator('.ant-result-title').filter({ hasText: '匯入完成' })).toBeVisible({
    timeout: 20_000,
  })
  return response.json() as Promise<{ created: number; updated: number; errors: unknown[] }>
}

export function buildProductCsvRow(row: Record<string, string | number>) {
  const header = 'sku,name,price_cents,category_path,barcode,is_weighted,unit'
  const values = [
    row.sku,
    row.name,
    row.price_cents,
    row.category_path ?? '',
    row.barcode ?? '',
    row.is_weighted ?? 0,
    row.unit ?? '個',
  ]
  return `${header}\n${values.join(',')}`
}

export async function gotoProductList(page: Page) {
  await page.goto('/products')
  await expect(page.locator('.ant-page-header-heading-title').filter({ hasText: '商品列表' })).toBeVisible({
    timeout: 15_000,
  })
  await expect(page.locator('.ant-table').first()).toBeVisible()
}

export async function searchProducts(page: Page, query: string, options?: { requireRow?: boolean }) {
  const requireRow = options?.requireRow ?? true
  const search = page.getByPlaceholder('搜尋商品名稱/SKU')
  await search.fill(query)
  await search.press('Enter')
  await page.locator('.ant-table-tbody').waitFor({ state: 'visible' })
  await page.waitForResponse(
    (r) => r.url().includes('/products') && r.request().method() === 'GET' && r.ok(),
    { timeout: 15_000 },
  ).catch(() => {})
  if (requireRow) {
    await expect(productTableRow(page, query).first()).toBeVisible({ timeout: 15_000 })
  }
}

export async function gotoProductEdit(page: Page, productId: string) {
  await page.goto(`/products/${productId}/edit`)
  await expect(page.locator('.ant-page-header-heading-title').filter({ hasText: '編輯商品' })).toBeVisible({
    timeout: 15_000,
  })
  await waitForProductFormReady(page)
}

export function productTableRow(page: Page, text: string) {
  return page.locator('.ant-table-tbody tr').filter({ hasText: text })
}

export function productRowAction(page: Page, row: ReturnType<typeof productTableRow>, label: string) {
  return row.getByRole('button', { name: new RegExp(label.split('').join('\\s*')) })
}

export async function waitForProductFormReady(page: Page) {
  await page.locator('.ant-spin-spinning').waitFor({ state: 'hidden', timeout: 20_000 }).catch(() => {})
  await expect(page.getByLabel('商品名稱')).toBeVisible({ timeout: 20_000 })
}

export function productFormSubmit(page: Page) {
  return page.locator('form button.ant-btn-primary[type="submit"]')
}

export async function setProductName(page: Page, name: string) {
  const input = page.locator('#form_item_name')
  await input.waitFor({ state: 'visible' })
  await input.click()
  await input.clear()
  await input.fill(name)
}

export async function setProductPriceYuan(page: Page, yuan: number | string) {
  const input = page.locator('#form_item_price_cents').or(
    page.locator('.ant-form-item').filter({ hasText: '售價 (元)' }).locator('.ant-input-number-input'),
  )
  await input.click()
  await input.clear()
  await input.fill(String(yuan))
  await input.press('Tab')
}

export async function fillProductForm(
  page: Page,
  data: {
    name: string
    sku: string
    priceYuan: number
    description?: string
    barcode?: string
    hideFromPosBrowse?: boolean
    categoryLabel?: string
  },
) {
  await waitForProductFormReady(page)
  await setProductName(page, data.name)
  await page.getByLabel('SKU').fill(data.sku)
  await setProductPriceYuan(page, data.priceYuan)

  if (data.categoryLabel) {
    await selectProductCategory(page, data.categoryLabel)
  }

  if (data.description !== undefined) {
    await page.locator('.ant-form-item').filter({ hasText: '描述' }).locator('textarea').fill(data.description)
  }

  if (data.barcode) {
    await page.getByRole('button', { name: '+ 新增條碼' }).click()
    const barcodeInput = page.locator('.ant-form-item').filter({ hasText: '條碼' }).locator('input').last()
    await barcodeInput.fill(data.barcode)
  }

  if (data.hideFromPosBrowse) {
    const posBrowseSwitch = page
      .locator('.ant-form-item')
      .filter({ hasText: '不顯示於 POS「全部」瀏覽' })
      .locator('.ant-switch')
    if ((await posBrowseSwitch.getAttribute('aria-checked')) !== 'true') {
      await posBrowseSwitch.click()
    }
  }
}

export async function submitProductForm(page: Page, mode: 'create' | 'edit') {
  await waitForProductFormReady(page)
  const label = mode === 'create' ? '建立' : '儲存'
  await productFormSubmit(page).click()
  await page.waitForURL(/\/products\/?$/, { timeout: 20_000 })
  await expect(page.locator('.ant-message-success, .ant-message-notice-content').filter({
    hasText: mode === 'create' ? '已建立' : '已更新',
  }).first()).toBeVisible({ timeout: 10_000 })
}

export async function confirmPopconfirm(page: Page) {
  const pop = page.locator('.ant-popconfirm:visible')
  await expect(pop).toBeVisible({ timeout: 5_000 })
  await pop.locator('.ant-popconfirm-buttons .ant-btn-primary').click()
}

export async function deleteProductFromList(page: Page, sku: string) {
  await gotoProductList(page)
  await searchProducts(page, sku)
  const row = productTableRow(page, sku)
  await expect(row).toHaveCount(1)
  await productRowAction(page, row, '刪除').click()
  await confirmPopconfirm(page)
  await expect(page.locator('.ant-message-success').filter({ hasText: '已刪除' })).toBeVisible({
    timeout: 10_000,
  })
}

export async function withAdminApi<T>(fn: (ctx: APIRequestContext, token: string) => Promise<T>): Promise<T> {
  const { request } = await import('@playwright/test')
  const ctx = await request.newContext()
  try {
    const session = await apiAdminLogin(ctx)
    return await fn(ctx, session.access_token)
  } finally {
    await ctx.dispose()
  }
}

export async function cleanupE2eProducts() {
  try {
    await withAdminApi(async (ctx, token) => {
      await apiCleanupProductsBySkuPrefix(ctx, token, E2E_PRODUCT_SKU_PREFIX)
    })
  } catch (e) {
    console.warn(`[e2e] cleanup skipped: ${(e as Error).message}`)
  }
}

export async function assertProductViaApi(
  productId: string,
  expected: Partial<
    Pick<ProductRead, 'name' | 'sku' | 'price_cents' | 'is_active' | 'hide_from_pos_browse' | 'category_id'>
  >,
) {
  await withAdminApi(async (ctx, token) => {
    const product = await apiGetProduct(ctx, token, productId)
    expect(product, `product ${productId} should exist`).not.toBeNull()
    if (expected.name !== undefined) expect(product!.name).toBe(expected.name)
    if (expected.sku !== undefined) expect(product!.sku).toBe(expected.sku)
    if (expected.price_cents !== undefined) expect(product!.price_cents).toBe(expected.price_cents)
    if (expected.is_active !== undefined) expect(product!.is_active).toBe(expected.is_active)
    if (expected.hide_from_pos_browse !== undefined) {
      expect(product!.hide_from_pos_browse).toBe(expected.hide_from_pos_browse)
    }
    if (expected.category_id !== undefined) expect(product!.category_id).toBe(expected.category_id)
  })
}

export async function findProductIdBySku(sku: string): Promise<string | null> {
  return withAdminApi(async (ctx, token) => {
    const products = await apiListProducts(ctx, token, { q: sku })
    return products.find((p) => p.sku === sku)?.id ?? null
  })
}
