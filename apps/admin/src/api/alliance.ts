import client from './client'
import type { AllianceNetworkRead, AllianceTenantRead, AllianceDashboard } from '@/types'

export function listAllianceNetworks() {
  return client.get<AllianceNetworkRead[]>('/alliance/networks')
}

export function createAllianceNetwork(data: { name: string; code: string; description?: string }) {
  return client.post<AllianceNetworkRead>('/alliance/networks', data)
}

export function joinAlliance(data: { alliance_id: string; data_scope?: string }) {
  return client.post<AllianceTenantRead>('/alliance/join', data)
}

export function getMyAlliance() {
  return client.get<AllianceTenantRead | null>('/alliance/me')
}

export function getAllianceDashboard() {
  return client.get<AllianceDashboard>('/alliance/dashboard')
}
