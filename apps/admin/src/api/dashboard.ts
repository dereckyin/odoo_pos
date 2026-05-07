import client from './client'

export interface DashboardStats {
  products: number
  active_promotions: number
  members: number
  today_orders: number
  today_revenue_cents: number
}

export function getDashboardStats() {
  return client.get<DashboardStats>('/dashboard/stats')
}
