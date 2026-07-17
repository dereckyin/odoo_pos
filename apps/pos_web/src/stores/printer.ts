/**
 * 印表機橋接模組：配對狀態管理 + print-jobs 輪詢/送印迴圈。
 * 對照 web_pos_full/docs/POS_printer_integration_v3.md 的 PrintService／WebUSBDriver 設計，
 * 這裡是把兩者接上 apps/api 的 /print-jobs 佇列的最上層（Pinia store，方便在 App 啟動時
 * 全域啟動一次，不綁在特定畫面上）。
 */
import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import * as printJobsApi from '@/api/printJobs'
import { PrintService } from '@/print/PrintService'
import { KIND_LABEL, WebUSBDriver, webUsbSupported } from '@/print/WebUSBDriver'
import type { PrinterKind, PrinterStatus, PrintJobRead } from '@/print/types'
import { useAuthStore } from '@/stores/auth'

const POLL_INTERVAL_MS = 2500
const KINDS: PrinterKind[] = ['receipt', 'kitchen', 'label']
const LOG_LIMIT = 30

export interface PrinterLogEntry {
  time: string
  level: 'info' | 'ok' | 'error'
  message: string
}

export const usePrinterStore = defineStore('printer', () => {
  const driver = new WebUSBDriver()
  const printService = new PrintService(driver)

  const supported = webUsbSupported()
  const status = ref<Record<PrinterKind, PrinterStatus>>({
    receipt: 'unpaired',
    kitchen: 'unpaired',
    label: 'unpaired',
  })
  const lastError = ref<Record<PrinterKind, string | null>>({
    receipt: null,
    kitchen: null,
    label: null,
  })
  const polling = ref(false)
  const lastPolledAt = ref<string | null>(null)
  const printedCount = ref(0)
  const failedCount = ref(0)
  const logs = ref<PrinterLogEntry[]>([])

  let timer: ReturnType<typeof setInterval> | null = null
  let inFlight = false

  function pushLog(level: PrinterLogEntry['level'], message: string) {
    logs.value.unshift({ time: new Date().toLocaleTimeString('zh-TW', { hour12: false }), level, message })
    if (logs.value.length > LOG_LIMIT) logs.value.length = LOG_LIMIT
  }

  const allReady = computed(() => KINDS.every((k) => status.value[k] === 'ready'))

  /** 開機／登入後呼叫：嘗試靜默重連先前授權過的裝置，不跳選單 */
  async function refreshStatus() {
    if (!supported) return
    for (const kind of KINDS) {
      const ready = await driver.isReady(kind)
      status.value[kind] = ready ? 'ready' : 'unpaired'
    }
  }

  /** 使用者點擊「配對」按鈕觸發（WebUSB 規定必須由使用者手勢觸發） */
  async function pair(kind: PrinterKind) {
    if (!supported) {
      lastError.value[kind] = 'WebUSB 不可用（需 Chrome/Edge + HTTPS 或 localhost）'
      status.value[kind] = 'error'
      return
    }
    status.value[kind] = 'connecting'
    lastError.value[kind] = null
    try {
      await driver.pair(kind)
      status.value[kind] = 'ready'
      pushLog('ok', `${KIND_LABEL[kind]}配對成功`)
    } catch (e) {
      status.value[kind] = 'error'
      lastError.value[kind] = (e as Error).message
      pushLog('error', `${KIND_LABEL[kind]}配對失敗：${(e as Error).message}`)
    }
  }

  function forget(kind: PrinterKind) {
    driver.forget(kind)
    status.value[kind] = 'unpaired'
    lastError.value[kind] = null
    pushLog('info', `已清除${KIND_LABEL[kind]}配對紀錄`)
  }

  async function testPrint(kind: PrinterKind) {
    try {
      const { ESC_INIT, ESC_CUT, escFeed, textBytes, concatBytes } = await import('@/print/raster')
      const bytes = concatBytes(
        ESC_INIT,
        textBytes(`${KIND_LABEL[kind]}測試列印 OK\n${new Date().toLocaleString('sv-SE')}\n`),
        escFeed(3),
        ESC_CUT,
      )
      await driver.print(kind, bytes)
      pushLog('ok', `${KIND_LABEL[kind]}測試列印完成`)
    } catch (e) {
      pushLog('error', `${KIND_LABEL[kind]}測試列印失敗：${(e as Error).message}`)
    }
  }

  async function printOneJob(job: PrintJobRead) {
    try {
      await printService.dispatch(job)
      await printJobsApi.completePrintJob(job.id)
      printedCount.value += 1
      pushLog('ok', `已列印 ${job.doc_type}（${KIND_LABEL[job.printer_role]}）`)
    } catch (e) {
      const message = (e as Error).message || String(e)
      failedCount.value += 1
      pushLog('error', `列印失敗 ${job.doc_type}：${message}`)
      try {
        await printJobsApi.failPrintJob(job.id, message)
      } catch {
        // 連回報失敗都失敗（通常是網路問題），下次輪詢伺服器會自行處理逾時重試
      }
    }
  }

  async function pollOnce() {
    if (inFlight) return
    const auth = useAuthStore()
    if (!auth.storeId) return
    inFlight = true
    try {
      // 只搶「已配對」角色的單；全未配對則傳空陣列，避免把佇列搶光並標失敗
      const readyRoles = KINDS.filter((k) => status.value[k] === 'ready')
      lastPolledAt.value = new Date().toISOString()
      if (!readyRoles.length) return
      const { data } = await printJobsApi.pollPendingPrintJobs(auth.storeId, readyRoles)
      for (const job of data.items) {
        await printOneJob(job)
      }
    } catch {
      // 網路或伺服器暫時不可用，靜默略過，下個輪詢週期再試
    } finally {
      inFlight = false
    }
  }

  async function start() {
    if (polling.value) return
    polling.value = true
    await refreshStatus()
    await pollOnce()
    timer = setInterval(pollOnce, POLL_INTERVAL_MS)
  }

  function stop() {
    polling.value = false
    if (timer) {
      clearInterval(timer)
      timer = null
    }
  }

  return {
    supported,
    status,
    lastError,
    polling,
    lastPolledAt,
    printedCount,
    failedCount,
    logs,
    allReady,
    refreshStatus,
    pair,
    forget,
    testPrint,
    start,
    stop,
  }
})
