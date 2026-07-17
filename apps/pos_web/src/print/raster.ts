/**
 * Canvas 排版 → 點陣圖 → ESC/POS ／ TSPL 位元組。
 *
 * 中文一律走圖像列印：熱感機文字模式的中文碼表在不同機種上不一致，
 * 用 canvas 畫成點陣圖再送印，字體、粗細、置中、分隔線都可控，也不會亂碼。
 * 邏輯移植並整理自 web_pos_full/printer_test/public/receipt_designed.js
 *（該檔已在真實硬體上驗證過 ESC/POS raster 列印）。
 *
 * QR code／barcode 則優先用印表機原生指令（GS ( k、GS k），比圖像清晰、掃描率更高。
 */

export const PAPER_WIDTH = 576 // 80mm 熱感機，203dpi，可列印寬度約 576 點
const PAD = 24
const INK = '#000'
const FONT_FAMILY = '"Microsoft JhengHei","PingFang TC","Noto Sans TC",sans-serif'

export interface TicketBuilder {
  readonly canvas: HTMLCanvasElement
  y: number
  centerText(text: string, size: number, weight?: string, gap?: number): void
  leftText(text: string, size: number, weight?: string, gap?: number): void
  row(left: string, right: string, size: number, weight?: string, gap?: number): void
  dashed(gap?: number): void
  solid(gap?: number, w?: number): void
  feed(px: number): void
}

/** 開一張足夠高的畫布，依序畫排版元素，最後用 finalizeTicket() 裁到實際高度 */
export function createTicket(width = PAPER_WIDTH, initialHeight = 2200): TicketBuilder {
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = initialHeight
  const ctx = canvas.getContext('2d')
  if (!ctx) throw new Error('無法取得 2D canvas context')
  ctx.fillStyle = '#fff'
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  ctx.fillStyle = INK
  ctx.textBaseline = 'top'
  const cx = width / 2

  const state = { y: PAD }
  const setFont = (size: number, weight: string) => {
    ctx.font = `${weight} ${size}px ${FONT_FAMILY}`
  }

  const builder: TicketBuilder = {
    canvas,
    get y() {
      return state.y
    },
    set y(v: number) {
      state.y = v
    },
    centerText(text, size, weight = 'normal', gap = 8) {
      setFont(size, weight)
      ctx.textAlign = 'center'
      ctx.fillText(text, cx, state.y)
      state.y += size + gap
    },
    leftText(text, size, weight = 'normal', gap = 6) {
      setFont(size, weight)
      ctx.textAlign = 'left'
      ctx.fillText(text, PAD, state.y)
      state.y += size + gap
    },
    row(left, right, size, weight = 'normal', gap = 8) {
      setFont(size, weight)
      ctx.textAlign = 'left'
      ctx.fillText(left, PAD, state.y)
      ctx.textAlign = 'right'
      ctx.fillText(right, width - PAD, state.y)
      state.y += size + gap
    },
    dashed(gap = 14) {
      state.y += 4
      ctx.strokeStyle = INK
      ctx.lineWidth = 2
      ctx.setLineDash([6, 5])
      ctx.beginPath()
      ctx.moveTo(PAD, state.y)
      ctx.lineTo(width - PAD, state.y)
      ctx.stroke()
      ctx.setLineDash([])
      state.y += gap
    },
    solid(gap = 14, w = 2) {
      state.y += 4
      ctx.strokeStyle = INK
      ctx.lineWidth = w
      ctx.beginPath()
      ctx.moveTo(PAD, state.y)
      ctx.lineTo(width - PAD, state.y)
      ctx.stroke()
      state.y += gap
    },
    feed(px) {
      state.y += px
    },
  }
  return builder
}

/** 依實際內容高度裁切畫布，避免整張紙都用初始高度 */
export function finalizeTicket(t: TicketBuilder, bottomPad = PAD): HTMLCanvasElement {
  const finalH = Math.min(t.y + bottomPad, t.canvas.height)
  const out = document.createElement('canvas')
  out.width = t.canvas.width
  out.height = finalH
  const octx = out.getContext('2d')
  if (!octx) throw new Error('無法取得 2D canvas context')
  octx.fillStyle = '#fff'
  octx.fillRect(0, 0, out.width, finalH)
  octx.drawImage(t.canvas, 0, 0)
  return out
}

export function canvasToBitmap(canvas: HTMLCanvasElement, threshold = 160) {
  const w = canvas.width
  const h = canvas.height
  const ctx = canvas.getContext('2d')
  if (!ctx) throw new Error('無法取得 2D canvas context')
  const img = ctx.getImageData(0, 0, w, h).data
  const bytesPerRow = Math.ceil(w / 8)
  const bitmap = new Uint8Array(bytesPerRow * h)
  for (let yy = 0; yy < h; yy++) {
    for (let xx = 0; xx < w; xx++) {
      const i = (yy * w + xx) * 4
      const lum = 0.299 * img[i] + 0.587 * img[i + 1] + 0.114 * img[i + 2]
      const alpha = img[i + 3]
      if (alpha > 128 && lum < threshold) {
        bitmap[yy * bytesPerRow + (xx >> 3)] |= 0x80 >> (xx & 7)
      }
    }
  }
  return { bitmap, bytesPerRow, width: w, height: h }
}

export function concatBytes(...arrays: Uint8Array[]): Uint8Array {
  const total = arrays.reduce((n, a) => n + a.length, 0)
  const out = new Uint8Array(total)
  let offset = 0
  for (const a of arrays) {
    out.set(a, offset)
    offset += a.length
  }
  return out
}

export function textBytes(str: string): Uint8Array {
  return Uint8Array.from(unescape(encodeURIComponent(str)), (c) => c.charCodeAt(0))
}

// ---------------------------------------------------------------------------
// ESC/POS（小票機／廚房機）
// ---------------------------------------------------------------------------

export const ESC_INIT = new Uint8Array([0x1b, 0x40])
export const ESC_ALIGN_LEFT = new Uint8Array([0x1b, 0x61, 0x00])
export const ESC_ALIGN_CENTER = new Uint8Array([0x1b, 0x61, 0x01])
export const ESC_CUT = new Uint8Array([0x1d, 0x56, 0x42, 0x00]) // GS V B 0 半切

export function escFeed(lines: number): Uint8Array {
  return new Uint8Array([0x1b, 0x64, lines & 0xff])
}

/** ESC p 0 25 250 — 透過小票機 RJ11 埠踢開錢箱 */
export function escCashDrawer(): Uint8Array {
  return new Uint8Array([0x1b, 0x70, 0x00, 0x19, 0xfa])
}

/** canvas → ESC/POS raster bit image（GS v 0） */
export function canvasToEscposRaster(canvas: HTMLCanvasElement): Uint8Array {
  const { bitmap, bytesPerRow, height } = canvasToBitmap(canvas)
  const xL = bytesPerRow & 0xff
  const xH = (bytesPerRow >> 8) & 0xff
  const yL = height & 0xff
  const yH = (height >> 8) & 0xff
  const header = new Uint8Array([0x1d, 0x76, 0x30, 0x00, xL, xH, yL, yH])
  return concatBytes(header, bitmap)
}

/** ESC/POS 原生 QR code（GS ( k，Model 2）。比圖像 QR 清晰、掃描率高。 */
export function escposQr(text: string, moduleSize = 8): Uint8Array {
  const bytes = textBytes(text)
  const parts: number[] = []
  parts.push(0x1d, 0x28, 0x6b, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00) // model 2
  parts.push(0x1d, 0x28, 0x6b, 0x03, 0x00, 0x31, 0x43, moduleSize) // module size
  parts.push(0x1d, 0x28, 0x6b, 0x03, 0x00, 0x31, 0x45, 0x31) // error correction M
  const len = bytes.length + 3
  parts.push(0x1d, 0x28, 0x6b, len & 0xff, (len >> 8) & 0xff, 0x31, 0x50, 0x30, ...Array.from(bytes))
  parts.push(0x1d, 0x28, 0x6b, 0x03, 0x00, 0x31, 0x51, 0x30) // print
  return new Uint8Array(parts)
}

/** ESC/POS 原生 CODE39 barcode（GS k，函式 4），電子發票證明聯用 */
export function escposBarcode(data: string, heightDots = 80, moduleWidth = 2): Uint8Array {
  const clean = data.toUpperCase().replace(/[^0-9A-Z\-. $/+%]/g, '')
  const bytes = textBytes(clean)
  const height = new Uint8Array([0x1d, 0x68, heightDots & 0xff]) // GS h n
  const width = new Uint8Array([0x1d, 0x77, moduleWidth & 0xff]) // GS w n
  const hri = new Uint8Array([0x1d, 0x48, 0x02]) // GS H 2 — 條碼下方印文字
  const cmd = new Uint8Array([0x1d, 0x6b, 0x04, bytes.length, ...Array.from(bytes)]) // GS k 4 CODE39
  return concatBytes(height, width, hri, cmd)
}

// ---------------------------------------------------------------------------
// TSPL（標籤機）
// ---------------------------------------------------------------------------

/**
 * TSPL BITMAP 指令：把 canvas 點陣圖直接印在標籤上（承載中文品名）。
 * 呼叫端仍需先送 SIZE/GAP/DENSITY/CLS，最後送 PRINT。
 */
export function tsplBitmapCommand(canvas: HTMLCanvasElement, x = 0, y = 0): Uint8Array {
  const { bitmap, bytesPerRow, height } = canvasToBitmap(canvas)
  const header = textBytes(`BITMAP ${x},${y},${bytesPerRow},${height},0,`)
  return concatBytes(header, bitmap, textBytes('\r\n'))
}

export function tsplLine(cmd: string): Uint8Array {
  return textBytes(cmd + '\r\n')
}
