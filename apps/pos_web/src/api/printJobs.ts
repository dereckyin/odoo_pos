import client from './client'
import type { PrintJobPendingResponse, PrintJobRead } from '@/print/types'

export function createPrintJob(payload: {
  store_id?: string
  printer_role: string
  doc_type: string
  payload: Record<string, unknown>
}) {
  return client.post('/print-jobs', payload)
}

/** 收銀站的印表機橋接模組輪詢這支端點；後端會用 SKIP LOCKED 原子搶單，
 * 回傳的工作已經是 status='printing'，印完直接呼叫 complete/fail 即可。
 * 傳入 roles 只搶已配對角色的單；傳空陣列則不搶任何單。 */
export function pollPendingPrintJobs(storeId: string, roles?: string[], limit = 10) {
  return client.get<PrintJobPendingResponse>('/print-jobs/pending', {
    params: { store_id: storeId, limit, printer_role: roles ?? undefined },
    paramsSerializer: {
      // FastAPI list query: ?printer_role=receipt&printer_role=kitchen
      serialize: (params) => {
        const sp = new URLSearchParams()
        for (const [k, v] of Object.entries(params)) {
          if (v == null) continue
          if (Array.isArray(v)) {
            for (const item of v) sp.append(k, String(item))
          } else {
            sp.append(k, String(v))
          }
        }
        return sp.toString()
      },
    },
  })
}

export function completePrintJob(jobId: string) {
  return client.post<PrintJobRead>(`/print-jobs/${jobId}/complete`)
}

export function failPrintJob(jobId: string, error: string) {
  return client.post<PrintJobRead>(`/print-jobs/${jobId}/fail`, { error: error.slice(0, 2000) })
}
