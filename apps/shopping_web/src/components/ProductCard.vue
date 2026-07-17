<template>
  <div class="item" :class="{ soldout: product.soldout || hideForDelivery }">
    <div class="thumb">
      <img v-if="product.imageUrl" :src="product.imageUrl" :alt="product.name" />
      <span v-else v-html="ic(product.iconKey)" />
    </div>
    <div class="info">
      <div class="name">
        {{ product.name }}
        <span class="tags">
          <span v-for="t in product.tags" :key="t" class="tag" :class="t">{{ tagLabel(t) }}</span>
          <span v-if="product.noDelivery && mode !== 'delivery'" class="tag nodelivery">不外送</span>
        </span>
      </div>
      <div v-if="product.description" class="desc">{{ product.description }}</div>
      <div class="bottom">
        <div class="price">
          <small>NT$</small><span class="num">{{ moneyYuan(product.priceCents) }}</span>
          <small v-if="hasSizeFrom" style="margin-left: 3px; color: var(--muted)">起</small>
        </div>
        <span v-if="product.soldout" class="soldout-label">今日售完</span>
        <span v-else-if="hideForDelivery" class="soldout-label">此品項不外送</span>
        <button v-else type="button" class="addbtn" :class="{ on: qty > 0 }" @click="$emit('add')">
          加入
          <span v-if="qty" class="cnt num">{{ qty }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { moneyYuan } from '@/entry'
import { ic } from '@/icons'
import type { FulfillmentMode, MenuProduct } from '@/types'

const props = defineProps<{
  product: MenuProduct
  mode: FulfillmentMode
  qty: number
}>()

defineEmits<{ add: [] }>()

const hideForDelivery = computed(() => props.mode === 'delivery' && props.product.noDelivery)

const hasSizeFrom = computed(() =>
  props.product.optionGroups.some(
    (g) =>
      g.is_required &&
      g.selection_type === 'single' &&
      g.choices.some((c) => c.price_delta_cents !== 0),
  ),
)

function tagLabel(t: string) {
  if (t === 'rec') return '推薦'
  if (t === 'hot') return '熱門'
  return '蔬食'
}
</script>
