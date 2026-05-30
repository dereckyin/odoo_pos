<template>
  <div class="page">
    <header class="hero">
      <h1>點餐趣美食市集</h1>
      <p>探索附近商家，外帶、外送、內用一站搞定</p>
      <form class="search-bar" @submit.prevent="goSearch">
        <input v-model="query" placeholder="搜尋商家或餐點…" />
        <button type="submit">搜尋</button>
      </form>
    </header>

    <div class="chips">
      <button :class="['chip', !fulfillment ? 'active' : '']" @click="setFulfillment('')">全部</button>
      <button :class="['chip', fulfillment === 'pickup' ? 'active' : '']" @click="setFulfillment('pickup')">外帶</button>
      <button :class="['chip', fulfillment === 'delivery' ? 'active' : '']" @click="setFulfillment('delivery')">外送</button>
      <button :class="['chip', fulfillment === 'dine_in' ? 'active' : '']" @click="setFulfillment('dine_in')">內用</button>
    </div>

    <div v-if="loading" class="state-page">載入中…</div>
    <div v-else-if="error" class="state-page">{{ error }}</div>
    <div v-else class="store-list">
      <router-link
        v-for="s in stores"
        :key="s.slug"
        :to="{ name: 'store', params: { slug: s.slug } }"
        class="store-card"
      >
        <div class="store-banner" :style="bannerStyle(s)" />
        <div class="store-body">
          <img v-if="s.logo_url" :src="resolveUploadPath(s.logo_url)" class="store-logo" alt="" />
          <div v-else class="store-logo-ph">{{ s.display_name.charAt(0) }}</div>
          <div class="store-meta">
            <h2>{{ s.display_name }}</h2>
            <p>{{ s.tagline || s.store_address || '歡迎光臨' }}</p>
            <div class="badges">
              <span v-if="!s.is_open" class="closed-tag">休息中</span>
              <span v-if="s.distance_km != null" class="badge">{{ s.distance_km }} km</span>
              <span v-if="s.supports_pickup" class="badge">外帶</span>
              <span v-if="s.supports_delivery" class="badge">外送 ${{ Math.round(s.delivery_fee_cents) }}</span>
              <span v-for="tag in s.cuisine_tags.slice(0, 2)" :key="tag" class="badge">{{ tag }}</span>
            </div>
          </div>
        </div>
      </router-link>
      <p v-if="stores.length === 0" class="state-page">目前尚無上架商家</p>
    </div>

    <button v-if="cart.itemCount > 0" class="cart-fab" @click="$router.push({ name: 'cart' })">
      <span>購物車 {{ cart.itemCount }} 品項</span>
      <span>${{ Math.round(cart.subtotalCents) }}</span>
    </button>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { fetchStores, resolveUploadPath } from '@/api'
import type { MarketplaceStoreSummary } from '@/types'
import { useCartStore } from '@/stores/cart'

const router = useRouter()
const cart = useCartStore()
const stores = ref<MarketplaceStoreSummary[]>([])
const loading = ref(true)
const error = ref('')
const query = ref('')
const fulfillment = ref('')
const coords = ref<{ lat: number; lng: number } | null>(null)

function bannerStyle(s: MarketplaceStoreSummary) {
  if (s.banner_url) return { backgroundImage: `url(${resolveUploadPath(s.banner_url)})` }
  return { background: 'linear-gradient(120deg, #c45c3e, #d4a853)' }
}

function setFulfillment(f: string) {
  fulfillment.value = f
  load()
}

function goSearch() {
  router.push({ name: 'search', query: { q: query.value.trim() } })
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    const { data } = await fetchStores({
      q: query.value.trim() || undefined,
      lat: coords.value?.lat,
      lng: coords.value?.lng,
      fulfillment: fulfillment.value || undefined,
    })
    stores.value = data
  } catch {
    error.value = '載入失敗，請稍後再試'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        coords.value = { lat: pos.coords.latitude, lng: pos.coords.longitude }
        load()
      },
      () => load(),
      { timeout: 5000 },
    )
  } else {
    load()
  }
})
</script>
