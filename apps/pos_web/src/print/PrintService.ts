/**
 * Print Service 抽象層：業務邏輯／輪詢迴圈只呼叫 dispatch(job)，
 * 不直接碰 WebUSB 或位元組編碼。對照
 * web_pos_full/docs/POS_printer_integration_v3.md 第 4 節的 PrintService 設計。
 */
import {
  buildConfirmationDoc,
  buildInvoiceProofDoc,
  buildKitchenTicketDoc,
  buildQrSlipDoc,
  buildReceiptDoc,
} from './escposDocuments'
import { buildLabelDoc } from './tsplDocuments'
import type {
  ConfirmationPayload,
  InvoiceProofPayload,
  KitchenTicketPayload,
  LabelDocPayload,
  PrinterDriver,
  PrintJobRead,
  QrSlipPayload,
  ReceiptPrintPayload,
} from './types'

export class UnknownDocTypeError extends Error {
  constructor(docType: string) {
    super(`不認得的 doc_type：${docType}`)
    this.name = 'UnknownDocTypeError'
  }
}

export class PrintService {
  constructor(private driver: PrinterDriver) {}

  /** 把一筆已 claim 的列印工作編碼並送到對應角色的印表機 */
  async dispatch(job: PrintJobRead): Promise<void> {
    const bytes = this.encode(job)
    await this.driver.print(job.printer_role, bytes)
  }

  private encode(job: PrintJobRead): Uint8Array {
    switch (job.doc_type) {
      case 'receipt':
        return buildReceiptDoc(job.payload as unknown as ReceiptPrintPayload)
      case 'kitchen_ticket':
        return buildKitchenTicketDoc(job.payload as unknown as KitchenTicketPayload)
      case 'confirmation':
        return buildConfirmationDoc(job.payload as unknown as ConfirmationPayload)
      case 'qr_slip':
        return buildQrSlipDoc(job.payload as unknown as QrSlipPayload)
      case 'invoice_proof':
        return buildInvoiceProofDoc(job.payload as unknown as InvoiceProofPayload)
      case 'label':
        return buildLabelDoc(job.payload as unknown as LabelDocPayload)
      default:
        throw new UnknownDocTypeError(job.doc_type)
    }
  }
}
