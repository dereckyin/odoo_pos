import type { Page } from '@playwright/test'

/** API rejects limit>200; older pos_web builds request 500 — rewrite until deployed. */
export async function patchProductListLimit(page: Page) {
  await page.route('**/products**', async (route) => {
    const req = route.request()
    if (req.method() !== 'GET') {
      await route.continue()
      return
    }
    const url = new URL(req.url())
    if (!url.pathname.endsWith('/products')) {
      await route.continue()
      return
    }
    const limit = Number(url.searchParams.get('limit') ?? 0)
    if (limit > 200) {
      url.searchParams.set('limit', '200')
      await route.continue({ url: url.toString() })
      return
    }
    await route.continue()
  })
}
