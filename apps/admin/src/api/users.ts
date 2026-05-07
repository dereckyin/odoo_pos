import client from './client'
import type { UserRead, UserCreate, UserUpdate } from '@/types'

export function listUsers() {
  return client.get<UserRead[]>('/users')
}

export function createUser(data: UserCreate) {
  return client.post<UserRead>('/users', data)
}

export function updateUser(id: string, data: UserUpdate) {
  return client.patch<UserRead>(`/users/${id}`, data)
}

export function deleteUser(id: string) {
  return client.delete(`/users/${id}`)
}
