/**
 * WebUSB 印表機驅動。
 *
 * 移植自 web_pos_full/printer_test/public/app.js（已在 Windows 實機上驗證：
 * Xprinter XP-N160II 換 Zadig/WinUSB 後可從 Chrome 直接列印），並依
 * web_pos_full/docs/POS_printer_integration_v3.md 第 4 節的 PrinterDriver
 * 介面重寫成 TypeScript class，擴充成收據／廚房／標籤三個角色各自獨立配對。
 *
 * 平台範圍（第一階段）：Windows + Android，統一 Chrome。iOS 不支援 WebUSB，
 * 之後如需支援需另外實作一個走本地列印伺服器的 driver（介面不變）。
 */
import type { PrinterDriver, PrinterKind } from './types'

interface OpenedDevice {
  device: USBDevice
  ifaceNum: number
  epOut: number
}

interface SavedDeviceId {
  vendorId: number
  productId: number
}

const KIND_LABEL: Record<PrinterKind, string> = {
  receipt: '收據機',
  kitchen: '廚房機',
  label: '標籤機',
}

const STORAGE_PREFIX = 'pos_web.printer.'

function isWebUsbSupported(): boolean {
  return typeof navigator !== 'undefined' && 'usb' in navigator && !!navigator.usb
}

export class WebUsbUnsupportedError extends Error {
  constructor() {
    super(
      '此瀏覽器/環境不支援 WebUSB。請用 Chrome 或 Edge，並確認網址是 https:// 或 http://localhost（iOS 完全不支援）。',
    )
    this.name = 'WebUsbUnsupportedError'
  }
}

export class WebUSBDriver implements PrinterDriver {
  private opened: Partial<Record<PrinterKind, OpenedDevice>> = {}

  constructor() {
    if (isWebUsbSupported()) {
      navigator.usb!.addEventListener('disconnect', (e) => {
        for (const kind of Object.keys(this.opened) as PrinterKind[]) {
          if (this.opened[kind]?.device === e.device) {
            delete this.opened[kind]
          }
        }
      })
    }
  }

  private savedId(kind: PrinterKind): SavedDeviceId | null {
    const raw = localStorage.getItem(STORAGE_PREFIX + kind)
    if (!raw) return null
    try {
      return JSON.parse(raw) as SavedDeviceId
    } catch {
      return null
    }
  }

  private saveId(kind: PrinterKind, device: USBDevice) {
    localStorage.setItem(
      STORAGE_PREFIX + kind,
      JSON.stringify({ vendorId: device.vendorId, productId: device.productId }),
    )
  }

  private matches(device: USBDevice, id: SavedDeviceId | null): boolean {
    return !!id && device.vendorId === id.vendorId && device.productId === id.productId
  }

  forget(kind: PrinterKind): void {
    localStorage.removeItem(STORAGE_PREFIX + kind)
    delete this.opened[kind]
  }

  /** 這一台裝置有沒有被配成別的角色（同一台裝置不能身兼兩職） */
  private otherKindClaims(device: USBDevice, kind: PrinterKind): PrinterKind | null {
    const kinds: PrinterKind[] = ['receipt', 'kitchen', 'label']
    for (const k of kinds) {
      if (k === kind) continue
      if (this.matches(device, this.savedId(k))) return k
    }
    return null
  }

  private async claimPrinterInterface(device: USBDevice): Promise<{ ifaceNum: number; epOut: number }> {
    const config = device.configuration
    if (!config) throw new Error('裝置沒有可用的 configuration')

    const candidates: { ifaceNum: number; epOut: number; cls: number; priority: number }[] = []
    for (const iface of config.interfaces) {
      const alt = iface.alternates[0]
      const epOut = alt.endpoints.find((e) => e.direction === 'out' && e.type === 'bulk')
      if (!epOut) continue
      candidates.push({
        ifaceNum: iface.interfaceNumber,
        epOut: epOut.endpointNumber,
        cls: alt.interfaceClass,
        // vendor-specific(0xFF) 與 printer class(0x07) 優先
        priority: alt.interfaceClass === 0xff ? 0 : alt.interfaceClass === 0x07 ? 1 : 2,
      })
    }
    candidates.sort((a, b) => a.priority - b.priority)

    if (candidates.length === 0) {
      throw new Error('找不到 bulk OUT endpoint，這台裝置可能不是支援 raw 列印的印表機')
    }

    const errors: string[] = []
    for (const c of candidates) {
      try {
        await device.claimInterface(c.ifaceNum)
        return { ifaceNum: c.ifaceNum, epOut: c.epOut }
      } catch (e) {
        errors.push(`介面 #${c.ifaceNum}: ${(e as Error).message}`)
      }
    }
    throw new Error(
      `claim 介面失敗（${errors.join('；')}）。Windows 上通常是驅動被 usbprint.sys 佔用，` +
        '需用 Zadig（https://zadig.akeo.ie/）把該印表機換成 WinUSB 驅動，詳見部署文件。',
    )
  }

  /** 找回已授權裝置並開啟／claim；找不到時（僅限使用者手動配對時）才跳系統選單 */
  private async getOrOpenDevice(kind: PrinterKind, { allowPrompt }: { allowPrompt: boolean }): Promise<OpenedDevice> {
    if (!isWebUsbSupported()) throw new WebUsbUnsupportedError()
    const cached = this.opened[kind]
    if (cached) return cached

    let device: USBDevice | null = null
    const id = this.savedId(kind)
    if (id) {
      const granted = await navigator.usb!.getDevices()
      device = granted.find((d) => this.matches(d, id)) ?? null
    }

    if (!device) {
      if (!allowPrompt) {
        throw new Error(`${KIND_LABEL[kind]}尚未配對，請先到「印表機設定」配對裝置`)
      }
      device = await navigator.usb!.requestDevice({ filters: [] })
      const conflict = this.otherKindClaims(device, kind)
      if (conflict) {
        throw new Error(`這台裝置已配對為「${KIND_LABEL[conflict]}」，請選擇另一台裝置`)
      }
      this.saveId(kind, device)
    }

    if (!device.opened) await device.open()
    if (device.configuration === null) await device.selectConfiguration(1)
    const claimed = await this.claimPrinterInterface(device)

    const opened: OpenedDevice = { device, ...claimed }
    this.opened[kind] = opened
    return opened
  }

  async pair(kind: PrinterKind): Promise<void> {
    // 配對一定是使用者點擊觸發（WebUSB 規定），所以允許跳系統選單。
    this.forget(kind)
    await this.getOrOpenDevice(kind, { allowPrompt: true })
  }

  async isReady(kind: PrinterKind): Promise<boolean> {
    if (!isWebUsbSupported()) return false
    if (this.opened[kind]) return true
    if (!this.savedId(kind)) return false
    try {
      await this.getOrOpenDevice(kind, { allowPrompt: false })
      return true
    } catch {
      return false
    }
  }

  async print(kind: PrinterKind, bytes: Uint8Array): Promise<void> {
    const { device, epOut } = await this.getOrOpenDevice(kind, { allowPrompt: false })
    const result = await device.transferOut(epOut, bytes)
    if (result.status !== 'ok') {
      delete this.opened[kind]
      throw new Error(`傳輸失敗：${result.status}`)
    }
  }

  async openCashDrawer(): Promise<void> {
    const { escCashDrawer } = await import('./raster')
    await this.print('receipt', escCashDrawer())
  }
}

export const webUsbSupported = isWebUsbSupported
export { KIND_LABEL }
