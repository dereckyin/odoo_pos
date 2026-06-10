import client from './client'

export interface RefundApprovalItem {
  id: string
  order_id: string
  user_id: string
  method: string
  total_amount_cents: number
  reason: string | null
  status: string
  approver_id: string | null
  decided_at: string | null
  reject_reason: string | null
  created_at: string
  order_no?: string | null
  store_name?: string | null
  user_name?: string | null
}

export interface VoidApprovalItem {
  id: string
  order_no?: string | null
  store_id: string
  store_name?: string | null
  total_cents: number
  status: string
  void_status: string | null
  void_reason: string | null
  voided_by: string | null
  created_at: string
}

export function listRefundApprovals(status?: string) {
  return client.get<RefundApprovalItem[]>('/approvals/refunds', { params: { status } })
}

export function approveRefund(id: string) {
  return client.post(`/approvals/refunds/${id}/approve`)
}

export function rejectRefund(id: string, reason?: string) {
  return client.post(`/approvals/refunds/${id}/reject`, { reason })
}

export function listVoidApprovals(status?: string) {
  return client.get<VoidApprovalItem[]>('/approvals/voids', { params: { status } })
}

export function approveVoid(orderId: string) {
  return client.post(`/approvals/voids/${orderId}/approve`)
}

export function rejectVoid(orderId: string, reason?: string) {
  return client.post(`/approvals/voids/${orderId}/reject`, { reason })
}
