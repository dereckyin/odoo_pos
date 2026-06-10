<template>
  <div class="page">
    <header class="topbar">
      <button class="back" @click="$router.push({ name: 'home' })">‹</button>
      <span class="title">探索店家</span>
      <span class="spacer" />
    </header>

    <div class="controls">
      <input v-model="q" class="search" placeholder="搜尋店家或餐點" @input="debouncedReload" />
      <div class="chips">
        <button :class="{ active: fulfillment === '' }" @click="setFulfillment('')">全部</button>
        <button :class="{ active: fulfillment === 'delivery' }" @click="setFulfillment('delivery')">外送</button>
        <button :class="{ active: fulfillment === 'pickup' }" @click="setFulfillment('pickup')">外帶</button>
        <button :class="{ active: fulfillment === 'dine_in' }" @click="setFulfillment('dine_in')">內用</button>
      </div>
      <div class="chips">
        <span class="sort-label">排序</span>
        <button :class="{ active: sort === 'distance' }" @click="setSort('distance')">距離</button>
        <button :class="{ active: sort === 'rating' }" @click="setSort('rating')">評分</button>
        <button :class="{ active: sort === 'prep' }" @click="setSort('prep')">出餐快</button>
      </div>
    </div>

    <main class="body">
      <div v-if="loading" class="state-page">載入中…</div>
      <div v-else-if="!stores.length" class="state-page">找不到符合的店家</div>
      <article
        v-for="s in stores"
        :key="s.slug"
        class="store"
        @click="$router.push({ name: 'store', params: { slug: s.slug } })"
      >
        <div class="thumb">
          <img v-if="s.logo_url" :src="resolveUploadPath(s.logo_url)" :alt="s.display_name" />
          <div v-else class="thumb-ph">{{ s.display_name.charAt(0) }}</div>
          <span v-if="!s.is_open" class="closed-badge">休息中</span>
        </div>
        <div class="info">
          <div class="name-row">
            <strong>{{ s.display_name }}</strong>
            <button class="fav" :class="{ on: s.is_favorite }" @click.stop="toggleFav(s)">
              {{ s.is_favorite ? '♥' : '♡' }}
            </button>
          </div>
          <div v-if="s.tagline" class="tagline">{{ s.tagline }}</div>
          <div class="meta">
            <span class="rating">★ {{ s.rating_avg ? s.rating_avg.toFixed(1) : '新店' }}<span v-if="s.rating_count" class="rc">({{ s.rating_count }})</span></span>
            <span>· {{ s.prep_time_min }} 分</span>
            <span v-if="s.distance_km != null">· {{ s.distance_km.toFixed(1) }} km</span>
            <span v-if="s.supports_delivery">· 外送 ${{ s.delivery_fee_cents }}</span>
          </div>
          <div class="tags">
            <span v-for="t in s.cuisine_tags.slice(0, 3)" :key="t" class="tag">{{ t }}</span>
          </div>
        </div>
      </article>
    </main>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { fetchStores, resolveUploadPath, toggleFavorite } from '@/api'
import { useMemberStore } from '@/stores/member'
import type { MarketplaceStoreSummary } from '@/types'

const route = useRoute()
const memberStore = useMemberStore()
const stores = ref<MarketplaceStoreSummary[]>([])
const loading = ref(true)
const q = ref(String(route.query.q || ''))
const fulfillment = ref('')
const sort = ref<'distance' | 'rating' | 'prep'>('rating')
const coords = ref<{ lat: number; lng: number } | null>(null)

let timer: number | null = null
function debouncedReload() {
  if (timer) window.clearTimeout(timer)
  timer = window.setTimeout(reload, 300)
}

function setFulfillment(f: string) {
  fulfillment.value = f
  reload()
}
function setSort(s: 'distance' | 'rating' | 'prep') {
  sort.value = s
  reload()
}

async function reload() {
  loading.value = true
  try {
    const { data } = await fetchStores({
      q: q.value || undefined,
      fulfillment: fulfillment.value || undefined,
      sort: sort.value,
      lat: coords.value?.lat,
      lng: coords.value?.lng,
    })
    stores.value = data
  } finally {
    loading.value = false
  }
}

async function toggleFav(s: MarketplaceStoreSummary) {
  if (!memberStore.isLoggedIn) {
    alert('請先登入會員')
    return
  }
  const next = !s.is_favorite
  s.is_favorite = next
  try {
    await toggleFavorite(s.slug, next)
  } catch {
    s.is_favorite = !next
  }
}

onMounted(() => {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        coords.value = { lat: pos.coords.latitude, lng: pos.coords.longitude }
        reload()
      },
      () => reload(),
      { timeout: 5000 },
    )
  } else {
    reload()
  }
})
</script>

<style scoped>
.controls { padding: 12px 16px; background: var(--surface); position: sticky; top: 0; z-index: 5; border-bottom: 1px solid var(--border); }
.search { width: 100%; padding: 10px 14px; border: 1px solid var(--border); border-radius: 20px; margin-bottom: 8px; }
.chips { display: flex; gap: 8px; overflow-x: auto; align-items: center; padding-bottom: 4px; }
.chips button { flex-shrink: 0; border: 1px solid var(--border); background: #fff; padding: 6px 14px; border-radius: 16px; font-size: 13px; }
.chips button.active { background: var(--accent); color: #fff; border-color: var(--accent); }
.sort-label { font-size: 12px; color: var(--muted); flex-shrink: 0; }
.body { padding: 12px 16px 40px; }
.store { display: flex; gap: 12px; background: var(--surface); border-radius: 12px; padding: 12px; margin-bottom: 12px; box-shadow: 0 1px 3px rgba(15,23,42,.06); cursor: pointer; }
.thumb { position: relative; width: 88px; height: 88px; flex-shrink: 0; border-radius: 10px; overflow: hidden; background: var(--accent-soft); }
.thumb img { width: 100%; height: 100%; object-fit: cover; }
.thumb-ph { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; color: var(--accent); font-size: 28px; font-weight: 700; }
.closed-badge { position: absolute; inset: 0; background: rgba(0,0,0,.5); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 12px; }
.info { flex: 1; min-width: 0; }
.name-row { display: flex; justify-content: space-between; align-items: center; }
.fav { border: 0; background: none; font-size: 20px; color: var(--accent); }
.fav.on { color: #e0245e; }
.tagline { font-size: 12px; color: var(--muted); margin-top: 2px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.meta { font-size: 12px; color: var(--muted); margin-top: 6px; display: flex; gap: 4px; flex-wrap: wrap; }
.rating { color: #e6a700; font-weight: 600; }
.rc { color: var(--muted); font-weight: 400; }
.tags { margin-top: 6px; display: flex; gap: 6px; }
.tag { font-size: 11px; background: var(--accent-soft); color: var(--accent); padding: 2px 8px; border-radius: 10px; }
</style>
