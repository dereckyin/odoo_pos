import client from './client'

export function createPrintJob(payload: {
  store_id?: string
  printer_role: string
  doc_type: string
  payload: Record<string, unknown>
}) {
  return client.post('/print-jobs', payload)
}
