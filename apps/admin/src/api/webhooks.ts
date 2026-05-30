import client from './client'
import type { WebhookSubscriptionRead } from '@/types'

export function listWebhooks() {
  return client.get<WebhookSubscriptionRead[]>('/webhooks')
}

export function createWebhook(data: { url: string; secret?: string; events: string[] }) {
  return client.post<WebhookSubscriptionRead>('/webhooks', data)
}

export function updateWebhook(id: string, data: Partial<{ url: string; secret: string; events: string[]; is_active: boolean }>) {
  return client.patch<WebhookSubscriptionRead>(`/webhooks/${id}`, data)
}

export function deleteWebhook(id: string) {
  return client.delete(`/webhooks/${id}`)
}
