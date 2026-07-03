import { test, expect } from '../../fixtures/pos-session.js'
import { useCashierSession } from '../../fixtures/pos-session.js'
import { kdsOrderCards } from '../../helpers/selectors.js'

test.describe('POS-06 KDS', () => {
  test.beforeEach(async ({ posPage: page }) => {
    test.skip(!process.env.POS_TERMINAL_API_KEY, 'POS_TERMINAL_API_KEY not set')
    await useCashierSession(page)
  })

  test('KDS 頁面可載入（空狀態或訂單卡片）', async ({ posPage: page }) => {
    await page.goto('kds')
    await expect(page.getByRole('heading', { name: /廚房顯示/ })).toBeVisible()

    const empty = page.getByText('目前沒有待處理訂單')
    const cards = kdsOrderCards(page)
    await expect(empty.or(cards.first())).toBeVisible({ timeout: 15_000 })
  })
})
