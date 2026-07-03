import { test, expect } from '../../fixtures/pos-session.js'
import { useCashierSession } from '../../fixtures/pos-session.js'
import { onlineOrderingEnabled } from '../../helpers/api.js'
import { customerOrderLink, tableGrid } from '../../helpers/selectors.js'

test.describe('POS-05 開桌', () => {
  test.beforeEach(async ({ posPage: page }) => {
    test.skip(!process.env.POS_TERMINAL_API_KEY, 'POS_TERMINAL_API_KEY not set')
    test.skip(!onlineOrderingEnabled(), 'online_ordering module disabled')
    await useCashierSession(page)
  })

  test('開桌後顯示顧客點餐連結', async ({ posPage: page }) => {
    await page.goto('tables')
    await expect(tableGrid(page)).toBeVisible({ timeout: 15_000 })

    const tableButtons = tableGrid(page).getByRole('button')
    const count = await tableButtons.count()
    test.skip(count === 0, 'no dining tables in demo store')

    const firstTable = tableButtons.first()
    await expect(firstTable).toBeEnabled()
    await firstTable.click()

    await expect(customerOrderLink(page)).toBeVisible({ timeout: 15_000 })
    const href = await customerOrderLink(page).getAttribute('href')
    expect(href).toMatch(/\/customer\/order\?t=/)
  })
})
