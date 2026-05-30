import client from './client'
import type {
  OptionChoiceCreate,
  OptionChoiceRead,
  OptionChoiceUpdate,
  OptionGroupCreate,
  OptionGroupRead,
  OptionGroupUpdate,
  ProductOptionGroupsSet,
  ProductOptionLinkRead,
  ProductOptionOverridesSet,
  ProductOptionChoiceOverrideRead,
} from '@/types'

export function listOptionGroups() {
  return client.get<OptionGroupRead[]>('/option-groups')
}

export function getOptionGroup(id: string) {
  return client.get<OptionGroupRead>(`/option-groups/${id}`)
}

export function createOptionGroup(data: OptionGroupCreate) {
  return client.post<OptionGroupRead>('/option-groups', data)
}

export function updateOptionGroup(id: string, data: OptionGroupUpdate) {
  return client.patch<OptionGroupRead>(`/option-groups/${id}`, data)
}

export function deleteOptionGroup(id: string) {
  return client.delete(`/option-groups/${id}`)
}

export function createOptionChoice(groupId: string, data: OptionChoiceCreate) {
  return client.post<OptionChoiceRead>(`/option-groups/${groupId}/choices`, data)
}

export function updateOptionChoice(groupId: string, choiceId: string, data: OptionChoiceUpdate) {
  return client.patch<OptionChoiceRead>(`/option-groups/${groupId}/choices/${choiceId}`, data)
}

export function deleteOptionChoice(groupId: string, choiceId: string) {
  return client.delete(`/option-groups/${groupId}/choices/${choiceId}`)
}

export function getProductOptionGroups(productId: string) {
  return client.get<ProductOptionLinkRead[]>(`/products/${productId}/option-groups`)
}

export function setProductOptionGroups(productId: string, data: ProductOptionGroupsSet) {
  return client.put<ProductOptionLinkRead[]>(`/products/${productId}/option-groups`, data)
}

export function getProductOptionOverrides(productId: string) {
  return client.get<ProductOptionChoiceOverrideRead[]>(`/products/${productId}/option-overrides`)
}

export function setProductOptionOverrides(productId: string, data: ProductOptionOverridesSet) {
  return client.put<ProductOptionChoiceOverrideRead[]>(`/products/${productId}/option-overrides`, data)
}

export function seedDrinkShopTemplate() {
  return client.post<OptionGroupRead[]>('/option-groups/seed/drink-shop')
}
