import client from './client'

export interface EventRead {
  id: string
  title: string
  description: string | null
  location: string | null
  image_url: string | null
  starts_at: string | null
  ends_at: string | null
  capacity: number
  price_cents: number
  is_published: boolean
  list_on_marketplace: boolean
  registered_count: number
}

export interface EventPayload {
  title: string
  description?: string | null
  location?: string | null
  image_url?: string | null
  starts_at?: string | null
  ends_at?: string | null
  capacity?: number
  price_cents?: number
  is_published?: boolean
  list_on_marketplace?: boolean
}

export interface RegistrationRead {
  id: string
  event_id: string
  member_id: string | null
  name: string
  phone: string | null
  qty: number
  amount_cents: number
  ticket_code: string
  status: string
  checked_in_at: string | null
  created_at: string
}

export function listEvents() {
  return client.get<EventRead[]>('/events')
}

export function createEvent(payload: EventPayload) {
  return client.post<EventRead>('/events', payload)
}

export function updateEvent(id: string, payload: Partial<EventPayload>) {
  return client.patch<EventRead>(`/events/${id}`, payload)
}

export function deleteEvent(id: string) {
  return client.delete(`/events/${id}`)
}

export function listRegistrations(eventId: string) {
  return client.get<RegistrationRead[]>(`/events/${eventId}/registrations`)
}

export function createRegistration(
  eventId: string,
  payload: { name: string; phone?: string | null; member_id?: string | null; qty?: number },
) {
  return client.post<RegistrationRead>(`/events/${eventId}/registrations`, payload)
}

export function checkInTicket(code: string) {
  return client.post<RegistrationRead>('/events/registrations/check-in', null, { params: { code } })
}

export function cancelRegistration(regId: string) {
  return client.post<RegistrationRead>(`/events/registrations/${regId}/cancel`)
}
