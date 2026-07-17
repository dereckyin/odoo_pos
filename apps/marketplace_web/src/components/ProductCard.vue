<template>
  <article class="product-card" :class="{ compact: compact }">
    <div class="media" @click="onAdd">
      <img v-if="card.image_url" :src="resolveUploadPath(card.image_url)" :alt="card.product_name" />
      <div v-else class="media-ph">{{ card.product_name.charAt(0) }}</div>
      <button class="add-btn" type="button" :disabled="adding" @click.stop="onAdd">
        {{ adding ? '…' : card.has_options ? '選規格' : '+' }}
      </button>
    </div>
    <div class="body">
      <h3 class="name">{{ card.product_name }}</h3>
      <p v-if="card.description" class="desc">{{ card.description }}</p>
      <div class="meta">
        <span class="price">${{ Math.round(card.price_cents) }}</span>
        <button type="button" class="store-link" @click.stop="goStore">{{ card.store_name }}</button>
      </div>
    </div>

    <OptionModal
      :open="optionProduct != null"
      :product="optionProduct"
      @close="optionProduct = null"
      @confirm="onOptionsConfirmed"
    />
  </article>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { resolveUploadPath } from '@/api'
import OptionModal from '@/components/OptionModal.vue'
import { useCartStore } from '@/stores/cart'
import { useMenuCacheStore } from '@/stores/menuCache'
import type { MarketplaceProductCard, PublicProduct, SelectedOption } from '@/types'

const props = defineProps<{ card: MarketplaceProductCard; compact?: boolean }>()

const compact = computed(() => props.compact ?? false)

const router = useRouter()
const cart = useCartStore()
const menuCache = useMenuCacheStore()
const adding = ref(false)
const optionProduct = ref<PublicProduct | null>(null)

function cardToProduct(card: MarketplaceProductCard): PublicProduct {
  return {
    id: card.product_id,
    sku: '',
    name: card.product_name,
    price_cents: card.price_cents,
    category_id: null,
    image_url: card.image_url,
    unit: '份',
    description: card.description,
    option_groups: [],
  }
}

function goStore() {
  router.push({ name: 'store', params: { slug: props.card.store_slug } })
}

const activeMeta = ref<import('@/types').MarketplaceMenuMeta | null>(null)

async function onAdd() {
  if (adding.value) return
  adding.value = true
  try {
    const menu = await menuCache.ensureMenu(props.card.store_slug)
    activeMeta.value = menu.meta
    if (!props.card.has_options) {
      cart.add(menu.meta, cardToProduct(props.card), 1)
      return
    }
    const product = menu.products.find((p) => p.id === props.card.product_id)
    if (!product) {
      alert('此餐點暫時無法加購')
      return
    }
    if (product.option_groups?.length) {
      optionProduct.value = product
    } else {
      cart.add(menu.meta, product, 1)
    }
  } finally {
    adding.value = false
  }
}

function onOptionsConfirmed(options: SelectedOption[]) {
  if (optionProduct.value && activeMeta.value) {
    cart.add(activeMeta.value, optionProduct.value, 1, options)
    optionProduct.value = null
  }
}
</script>

<style scoped>
.product-card {
  background: var(--surface);
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid var(--border);
  box-shadow: none;
  display: flex;
  flex-direction: column;
}
.media {
  position: relative;
  aspect-ratio: 4 / 3;
  background: var(--accent-soft);
  border-bottom: 1px solid var(--border);
  cursor: pointer;
}
.media img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.media-ph {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  font-weight: 700;
  color: var(--accent);
}
.add-btn {
  position: absolute;
  right: 8px;
  bottom: 8px;
  min-width: 36px;
  height: 32px;
  padding: 0 10px;
  border: 1.5px solid var(--accent);
  border-radius: 6px;
  background: var(--accent);
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  line-height: 1;
  box-shadow: none;
}
.add-btn:disabled {
  opacity: 0.7;
}
.body {
  padding: 10px 12px 12px;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.name {
  margin: 0;
  font-size: 0.95rem;
  font-weight: 600;
  line-height: 1.3;
}
.desc {
  margin: 0;
  font-size: 12px;
  color: var(--muted);
  line-height: 1.35;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-top: auto;
  padding-top: 4px;
}
.price {
  color: var(--accent);
  font-weight: 700;
  font-size: 0.95rem;
}
.store-link {
  border: 0;
  background: transparent;
  padding: 0;
  font-size: 12px;
  color: var(--muted);
  text-decoration: underline;
  text-underline-offset: 2px;
  max-width: 55%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.product-card.compact .body {
  padding: 8px 10px 10px;
}
.product-card.compact .name {
  font-size: 0.88rem;
}
.product-card.compact .desc {
  -webkit-line-clamp: 1;
}
</style>
