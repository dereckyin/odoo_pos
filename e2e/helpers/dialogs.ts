import type { Page } from '@playwright/test'

const handled = new WeakSet<Page>()

/** Auto-accept alert/confirm dialogs (e.g. table open success). */
export function acceptDialogs(page: Page) {
  if (handled.has(page)) return
  handled.add(page)
  page.on('dialog', (dialog) => dialog.accept())
}
