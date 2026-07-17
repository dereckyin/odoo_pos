<template>
  <div class="sumrow"><span>小計</span><span class="v">NT$ {{ moneyYuan(subtotal) }}</span></div>
  <div v-if="mode === 'delivery'" class="sumrow">
    <span>外送費</span><span class="v">NT$ {{ moneyYuan(deliveryFee) }}</span>
  </div>
  <div v-else-if="mode === 'takeout'" class="sumrow">
    <span>外帶包材</span><span class="v">免費</span>
  </div>
  <div v-if="discount" class="sumrow disc">
    <span>會員折抵</span><span class="v">－NT$ {{ moneyYuan(discount) }}</span>
  </div>
  <div class="sumrow total">
    <span>合計</span><span class="v">NT$ {{ moneyYuan(total) }}</span>
  </div>
</template>

<script setup lang="ts">
import { moneyYuan } from '@/entry'
import type { FulfillmentMode } from '@/types'

defineProps<{
  mode: FulfillmentMode
  subtotal: number
  deliveryFee: number
  discount: number
  total: number
}>()
</script>
