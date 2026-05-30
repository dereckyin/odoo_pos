import client from './client'

export interface ReportQuery {
  since?: string
  until?: string
  store_id?: string
  compare_prior?: boolean
  limit?: number
}

export interface SalesSummary {
  total_revenue_cents: number
  net_revenue_cents: number
  total_orders: number
  avg_order_cents: number
  refund_cents: number
  refund_rate: number
  qr_order_count: number
  qr_ratio: number
  prior_revenue_cents: number | null
  prior_order_count: number | null
  revenue_change_pct: number | null
}

export interface DailyPoint {
  date: string
  revenue_cents: number
  net_cents: number
  order_count: number
}

export interface HeatmapCell {
  weekday: number
  hour: number
  order_count: number
  revenue_cents: number
}

export interface PaymentMixItem {
  method: string
  count: number
  amount_cents: number
}

export interface TopProduct {
  product_id: string
  product_name: string
  sku: string
  total_qty: number
  total_revenue_cents: number
}

export interface CategoryMixItem {
  category_id: string | null
  category_name: string
  revenue_cents: number
  qty: number
}

export function getSalesSummary(params?: ReportQuery) {
  return client.get<SalesSummary>('/reports/sales-summary', { params })
}

export function getDailySeries(params?: ReportQuery) {
  return client.get<DailyPoint[]>('/reports/daily-series', { params })
}

export function getHourlyHeatmap(params?: ReportQuery) {
  return client.get<HeatmapCell[]>('/reports/hourly-heatmap', { params })
}

export function getPaymentMix(params?: ReportQuery) {
  return client.get<PaymentMixItem[]>('/reports/payment-mix', { params })
}

export function getTopProducts(params?: ReportQuery) {
  return client.get<TopProduct[]>('/reports/top-products', { params })
}

export function getCategoryMix(params?: ReportQuery) {
  return client.get<CategoryMixItem[]>('/reports/category-mix', { params })
}
