import { test, expect } from '@playwright/test'
import { loginAdmin } from '../../fixtures/admin-session.js'
import {
  assertProductViaApi,
  buildProductCsvRow,
  cleanupE2eProducts,
  e2eProductName,
  e2eProductSku,
  fetchDemoCategory,
  fillProductForm,
  findProductIdBySku,
  gotoProductImport,
  gotoProductList,
  productTableRow,
  searchProducts,
  submitProductForm,
  uploadProductCsv,
  waitForProductFormReady,
} from '../../helpers/admin-products.js'

test.describe.configure({ mode: 'serial' })

test.describe('ADM-09~10 商品進階', () => {
  const csvSku = e2eProductSku('CSV')
  const csvName = `E2E CSV 匯入 ${csvSku}`
  const categorySku = e2eProductSku('CAT')
  const categoryName = e2eProductName(categorySku)
  let snackCategory = { id: '', path_label: '零食' }
  let csvProductId = ''
  let categoryProductId = ''

  test.beforeAll(async () => {
    test.skip(!process.env.ADMIN_PASSWORD, 'ADMIN_PASSWORD not set')
    snackCategory = await fetchDemoCategory('零食')
  })

  test.afterAll(async () => {
    await cleanupE2eProducts()
  })

  test.beforeEach(async ({ page }) => {
    test.skip(!process.env.ADMIN_PASSWORD, 'ADMIN_PASSWORD not set')
    await loginAdmin(page)
  })

  test('ADM-09 CSV 匯入：新增商品並帶分類', async ({ page }) => {
    test.setTimeout(60_000)

    await gotoProductImport(page)
    const csv = buildProductCsvRow({
      sku: csvSku,
      name: csvName,
      price_cents: 77,
      category_path: snackCategory.path_label,
      barcode: csvSku,
      is_weighted: 0,
      unit: '個',
    })

    const result = await uploadProductCsv(page, csv)
    expect(result.created).toBeGreaterThanOrEqual(1)
    expect(result.errors ?? []).toHaveLength(0)

    await gotoProductList(page)
    await searchProducts(page, csvSku)
    const row = productTableRow(page, csvSku)
    await expect(row).toContainText(csvName)
    await expect(row).toContainText('NT$77')
    await expect(row).toContainText(snackCategory.path_label)

    csvProductId = (await findProductIdBySku(csvSku)) ?? ''
    expect(csvProductId).toBeTruthy()
    await assertProductViaApi(csvProductId, {
      name: csvName,
      sku: csvSku,
      price_cents: 77,
      category_id: snackCategory.id,
      is_active: true,
    })
  })

  test('ADM-09b CSV 匯入：相同 SKU 更新售價', async ({ page }) => {
    test.setTimeout(60_000)
    test.skip(!csvProductId, 'CSV import step did not run')

    await gotoProductImport(page)
    const csv = buildProductCsvRow({
      sku: csvSku,
      name: `${csvName}（更新）`,
      price_cents: 88,
      category_path: snackCategory.path_label,
    })

    const result = await uploadProductCsv(page, csv)
    expect(result.updated).toBeGreaterThanOrEqual(1)

    await gotoProductList(page)
    await searchProducts(page, csvSku)
    await expect(productTableRow(page, csvSku)).toContainText('NT$88')

    await assertProductViaApi(csvProductId, {
      name: `${csvName}（更新）`,
      price_cents: 88,
    })
  })

  test('ADM-10 分類指派：表單選擇分類後列表與 API 一致', async ({ page }) => {
    test.setTimeout(60_000)

    await page.goto('/products/create')
    await waitForProductFormReady(page)
    await fillProductForm(page, {
      name: categoryName,
      sku: categorySku,
      priceYuan: 66,
      categoryLabel: snackCategory.name,
    })

    const createRes = page.waitForResponse(
      (r) => r.url().includes('/products') && r.request().method() === 'POST' && r.ok(),
      { timeout: 20_000 },
    )
    await submitProductForm(page, 'create')
    categoryProductId = ((await (await createRes).json()) as { id: string }).id

    await searchProducts(page, categorySku)
    const row = productTableRow(page, categorySku)
    await expect(row).toContainText(categoryName)
    await expect(row).toContainText('NT$66')
    await expect(row).toContainText(snackCategory.path_label)

    await assertProductViaApi(categoryProductId, {
      name: categoryName,
      sku: categorySku,
      price_cents: 66,
      category_id: snackCategory.id,
    })
  })
})
