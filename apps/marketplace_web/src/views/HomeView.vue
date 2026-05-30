<template>
  <div class="page">
    <header class="hero">
      <h1>點餐趣美食市集</h1>
      <p>依分類瀏覽精選餐點，外帶、外送、內用一站搞定</p>
      <div class="search-bar">
        <input v-model="query" placeholder="搜尋餐點或商家…" />
      </div>
    </header>

    <div class="chips">
      <button :class="['chip', !fulfillment ? 'active' : '']" type="button" @click="setFulfillment('')">全部</button>
      <button :class="['chip', fulfillment === 'pickup' ? 'active' : '']" type="button" @click="setFulfillment('pickup')">外帶</button>
      <button :class="['chip', fulfillment === 'delivery' ? 'active' : '']" type="button" @click="setFulfillment('delivery')">外送</button>
      <button :class="['chip', fulfillment === 'dine_in' ? 'active' : '']" type="button" @click="setFulfillment('dine_in')">內用</button>
      <button
        v-for="tag in cuisineTags"
        :key="tag"
        :class="['chip', cuisine === tag ? 'active' : '']"
        type="button"
        @click="setCuisine(cuisine === tag ? '' : tag)"
      >
        {{ tag }}
      </button>
    </div>

    <div v-if="!isSearchMode && feedCategories.length" class="cat-tabs-wrap">
      <div class="cat-tabs">
        <button
          v-for="cat in feedCategories"
          :key="cat.id"
          :class="['cat-tab', activeCategoryId === cat.id ? 'active' : '']"
          type="button"
          @click="scrollToCategory(cat.id)"
        >
          <span v-if="cat.icon" class="tab-icon">{{ cat.icon }}</span>
          {{ cat.name }}
        </button>
      </div>
    </div>

    <section v-if="stores.length" class="stores-section">
      <h2 class="section-title">熱門商家</h2>
      <div class="stores-scroll">
        <router-link
          v-for="s in stores"
          :key="s.slug"
          :to="{ name: 'store', params: { slug: s.slug } }"
          class="store-chip"
        >
          <img v-if="s.logo_url" :src="resolveUploadPath(s.logo_url)" class="store-chip-logo" alt="" />
          <div v-else class="store-chip-logo ph">{{ s.display_name.charAt(0) }}</div>
          <span class="store-chip-name">{{ s.display_name }}</span>
        </router-link>
      </div>
    </section>

    <section class="products-section">
      <h2 v-if="isSearchMode" class="section-title">「{{ query.trim() }}」搜尋結果</h2>
      <div v-if="loading" class="state-page">載入中…</div>
      <div v-else-if="error" class="state-page">{{ error }}</div>
      <template v-else-if="isSearchMode">
        <div v-if="searchProducts.length" class="product-grid">
          <ProductCard v-for="p in searchProducts" :key="`${p.store_slug}-${p.product_id}`" :card="p" />
        </div>
        <p v-else class="state-page">找不到相關餐點</p>
      </template>
      <template v-else>
        <CategoryFeed v-if="feedSections.length" ref="feedRef" :sections="feedSections" />
        <p v-else class="state-page">目前沒有上架餐點，請調整篩選條件</p>
      </template>
    </section>

    <button v-if="cart.itemCount > 0" class="cart-fab" type="button" @click="$router.push({ name: 'cart' })">
      <span>購物車 {{ cart.itemCount }} 品項</span>
      <span>${{ Math.round(cart.subtotalCents) }}</span>
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  fetchFeedCategories,
  fetchProducts,
  fetchProductsFeed,
  fetchStores,
  resolveUploadPath,
} from '@/api'
import CategoryFeed from '@/components/CategoryFeed.vue'
import ProductCard from '@/components/ProductCard.vue'
import type {
  MarketplaceFeedCategory,
  MarketplaceProductCard,
  MarketplaceProductFeedSection,
  MarketplaceStoreSummary,
} from '@/types'
import { useCartStore } from '@/stores/cart'

const route = useRoute()
const router = useRouter()
const cart = useCartStore()

const feedSections = ref<MarketplaceProductFeedSection[]>([])
const feedCategories = ref<MarketplaceFeedCategory[]>([])
const searchProducts = ref<MarketplaceProductCard[]>([])
const stores = ref<MarketplaceStoreSummary[]>([])
const loading = ref(true)
const error = ref('')
const query = ref(String(route.query.q || ''))
const fulfillment = ref('')
const cuisine = ref('')
const coords = ref<{ lat: number; lng: number } | null>(null)
const activeCategoryId = ref('')
const feedRef = ref<InstanceType<typeof CategoryFeed> | null>(null)

let debounceTimer: ReturnType<typeof setTimeout> | null = null
let scrollObserver: IntersectionObserver | null = null

const isSearchMode = computed(() => query.value.trim().length > 0)

const cuisineTags = computed(() => {
  const tags = new Set<string>()
  for (const s of stores.value) {
    for (const t of s.cuisine_tags ?? []) tags.add(t)
  }
  return [...tags].slice(0, 8)
})

function setFulfillment(f: string) {
  fulfillment.value = f
  loadAll()
}

function setCuisine(c: string) {
  cuisine.value = c
  loadAll()
}

function scrollToCategory(categoryId: string) {
  activeCategoryId.value = categoryId
  feedRef.value?.scrollToCategory(categoryId)
}

function setupSectionObserver() {
  scrollObserver?.disconnect()
  if (isSearchMode.value || !feedRef.value) return
  const sections = feedRef.value.sectionRefs
  if (!sections.size) return
  scrollObserver = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          for (const [id, el] of sections.entries()) {
            if (el === entry.target) activeCategoryId.value = id
          }
        }
      }
    },
    { rootMargin: '-120px 0px -60% 0px', threshold: 0.1 },
  )
  for (const el of sections.values()) scrollObserver.observe(el)
}

async function loadStores() {
  try {
    const { data } = await fetchStores({
      lat: coords.value?.lat,
      lng: coords.value?.lng,
      fulfillment: fulfillment.value || undefined,
    })
    stores.value = data.slice(0, 12)
  } catch {
    stores.value = []
  }
}

async function loadFeed() {
  const params = {
    fulfillment: fulfillment.value || undefined,
    cuisine: cuisine.value || undefined,
  }
  const [{ data: feed }, { data: cats }] = await Promise.all([
    fetchProductsFeed(params),
    fetchFeedCategories(params),
  ])
  feedSections.value = feed.sections
  feedCategories.value = cats
  if (cats.length && !activeCategoryId.value) activeCategoryId.value = cats[0].id
}

async function loadSearchProducts() {
  const { data } = await fetchProducts({
    q: query.value.trim(),
    fulfillment: fulfillment.value || undefined,
    cuisine: cuisine.value || undefined,
  })
  searchProducts.value = data
}

async function loadContent() {
  if (isSearchMode.value) {
    await loadSearchProducts()
  } else {
    await loadFeed()
  }
}

async function loadAll() {
  loading.value = true
  error.value = ''
  try {
    await Promise.all([loadStores(), loadContent()])
  } catch {
    error.value = '載入失敗，請稍後再試'
  } finally {
    loading.value = false
    if (!isSearchMode.value) {
      setTimeout(() => setupSectionObserver(), 50)
    }
  }
}

watch(query, () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    const q = query.value.trim()
    const nextQuery = q ? { q } : {}
    if (String(route.query.q || '') !== q) {
      router.replace({ name: 'home', query: nextQuery })
    }
    loadAll()
  }, 300)
})

watch(
  () => route.query.q,
  (v) => {
    const next = String(v || '')
    if (next !== query.value) query.value = next
  },
)

onMounted(() => {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        coords.value = { lat: pos.coords.latitude, lng: pos.coords.longitude }
        loadAll()
      },
      () => loadAll(),
      { timeout: 5000 },
    )
  } else {
    loadAll()
  }
})

onBeforeUnmount(() => scrollObserver?.disconnect())
</script>

<style scoped>
.cat-tabs-wrap {
  position: sticky;
  top: 0;
  z-index: 20;
  background: var(--surface);
  border-bottom: 1px solid var(--border);
  box-shadow: 0 2px 8px rgba(51, 51, 51, 0.06);
}
.cat-tabs {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding: 10px 12px;
  -webkit-overflow-scrolling: touch;
}
.cat-tab {
  flex-shrink: 0;
  border: 1px solid var(--border);
  background: var(--surface);
  border-radius: 20px;
  padding: 8px 14px;
  font-size: 14px;
  color: var(--text);
  display: inline-flex;
  align-items: center;
  gap: 4px;
}
.cat-tab.active {
  border-color: var(--accent);
  color: var(--accent);
  background: var(--accent-soft);
  font-weight: 600;
}
.tab-icon {
  font-size: 1rem;
}
.stores-section,
.products-section {
  padding: 0 12px 16px;
}
.section-title {
  margin: 8px 4px 10px;
  font-size: 1rem;
  font-weight: 700;
}
.stores-scroll {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  padding-bottom: 4px;
  -webkit-overflow-scrolling: touch;
}
.store-chip {
  flex-shrink: 0;
  width: 72px;
  text-decoration: none;
  color: inherit;
  text-align: center;
}
.store-chip-logo {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  object-fit: cover;
  margin: 0 auto 6px;
  background: var(--accent-soft);
  box-shadow: 0 1px 3px rgba(51, 51, 51, 0.08);
}
.store-chip-logo.ph {
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  color: var(--accent);
}
.store-chip-name {
  display: block;
  font-size: 11px;
  line-height: 1.25;
  color: var(--muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.product-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}
@media (min-width: 640px) {
  .product-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}
</style>
