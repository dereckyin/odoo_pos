/**
 * TSPL 文件 encoder：doc_type 'label'（飲料杯標籤，printer_role: label）。
 * 標籤尺寸預設 40x30mm、間距 2mm（見 web_pos_full/docs/POS_printer_integration_v3.md 6.2 節），
 * 採購標籤紙後如尺寸不同，調整 LABEL_WIDTH_MM / LABEL_HEIGHT_MM 與 DPI 即可。
 * 品名等中文一律走 BITMAP（canvas 點陣圖），避免 TSPL 文字指令的中文碼表問題。
 */
import { canvasToBitmap, concatBytes, createTicket, finalizeTicket, textBytes } from './raster'
import type { DrinkLabelPayload, LabelDocPayload } from './types'

const DPI = 203
const MM_TO_DOTS = DPI / 25.4
const LABEL_WIDTH_MM = 40
const LABEL_HEIGHT_MM = 30
const LABEL_WIDTH_DOTS = Math.round(LABEL_WIDTH_MM * MM_TO_DOTS) // ≈ 320
const LABEL_HEIGHT_DOTS = Math.round(LABEL_HEIGHT_MM * MM_TO_DOTS) // ≈ 240

function fmtTime(iso: string | null | undefined): string {
  if (!iso) return ''
  try {
    return new Date(iso).toLocaleString('sv-SE', { hour12: false }).slice(5, 16)
  } catch {
    return iso
  }
}

function renderLabelCanvas(label: DrinkLabelPayload): HTMLCanvasElement {
  const t = createTicket(LABEL_WIDTH_DOTS, LABEL_HEIGHT_DOTS + 40)
  t.y = 6
  t.centerText(label.product_name, 30, 'bold', 4)
  if (label.options_label) t.centerText(label.options_label, 18, 'normal', 4)
  const cupInfo = label.cup_total > 1 ? `第 ${label.cup_index}/${label.cup_total} 杯` : ''
  t.row(label.table_label || '', cupInfo, 16, 'normal', 4)
  t.row(`#${label.order_ref}`, fmtTime(label.placed_at), 14, 'normal', 4)
  if (label.note) t.centerText(label.note, 14, 'normal', 0)
  return finalizeTicket(t, 6)
}

function bitmapCommand(canvas: HTMLCanvasElement): Uint8Array {
  const { bitmap, bytesPerRow, height } = canvasToBitmap(canvas, 170)
  const header = textBytes(`BITMAP 0,0,${bytesPerRow},${height},0,`)
  return concatBytes(header, bitmap, textBytes('\r\n'))
}

function buildSingleLabel(label: DrinkLabelPayload): Uint8Array {
  const canvas = renderLabelCanvas(label)
  const setup = textBytes(
    [
      `SIZE ${LABEL_WIDTH_MM} mm,${LABEL_HEIGHT_MM} mm`,
      'GAP 2 mm,0 mm',
      'DENSITY 8',
      'DIRECTION 1',
      'CLS',
      '',
    ].join('\r\n'),
  )
  const bitmap = bitmapCommand(canvas)
  const print = textBytes('PRINT 1,1\r\n')
  return concatBytes(setup, bitmap, print)
}

/** payload.labels 可能有多杯，逐杯各自一段 TSPL 區塊（各自 CLS/PRINT），串成一個列印工作 */
export function buildLabelDoc(payload: LabelDocPayload): Uint8Array {
  return concatBytes(...payload.labels.map(buildSingleLabel))
}
