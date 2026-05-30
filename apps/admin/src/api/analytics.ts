import client from './client'
import type { ReportQuery } from './reports'

export interface StoreComparisonRow {
  store_id: string
  store_name: string
  store_code: string
  latitude: number | null
  longitude: number | null
  revenue_cents: number
  net_cents: number
  order_count: number
  avg_order_cents: number
  refund_cents: number
  refund_rate: number
  prior_revenue_cents: number | null
  growth_pct: number | null
}

export interface AovBucket {
  label: string
  count: number
}

export interface DiscountStats {
  total_discount_cents: number
  discounted_orders: number
  discount_rate_pct: number
}

export interface AddonStat {
  choice_name: string
  count: number
  revenue_cents: number
}

export interface InsightItem {
  text: string
  kind: string
}

export interface WeekdayPattern {
  weekday: number
  weekday_label: string
  revenue_cents: number
  order_count: number
}

export interface WeatherDayPoint {
  date: string
  revenue_cents: number
  order_count: number
  temp_c: number | null
  precip_mm: number
  rainy: boolean
}

export interface WeatherCorrelation {
  rainy_avg_revenue: number
  clear_avg_revenue: number
  rainy_avg_orders: number
  clear_avg_orders: number
  daily: WeatherDayPoint[]
  insights: InsightItem[]
}

export function getStoreComparison(params?: ReportQuery) {
  return client.get<StoreComparisonRow[]>('/analytics/store-comparison', { params })
}

export function getAovDistribution(params?: ReportQuery) {
  return client.get<AovBucket[]>('/analytics/aov-distribution', { params })
}

export function getDiscountStats(params?: ReportQuery) {
  return client.get<DiscountStats>('/analytics/discount-stats', { params })
}

export function getTopAddons(params?: ReportQuery) {
  return client.get<AddonStat[]>('/analytics/top-addons', { params })
}

export function getWeekdayPattern(params?: ReportQuery) {
  return client.get<WeekdayPattern[]>('/analytics/weekday-pattern', { params })
}

export function getAnalyticsInsights(params?: ReportQuery) {
  return client.get<InsightItem[]>('/analytics/insights', { params })
}

export function getWeatherCorrelation(params?: ReportQuery) {
  return client.get<WeatherCorrelation>('/analytics/weather-correlation', { params })
}
