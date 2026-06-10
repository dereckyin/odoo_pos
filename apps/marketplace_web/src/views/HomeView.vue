<template>
  <div class="page">
    <header class="disco-head">
      <div class="container">
        <div class="head-top">
          <h1>點餐趣美食市集</h1>
          <button class="member-btn" type="button" @click="onMemberClick">
            <span class="ic">👤</span>
            <span>{{ memberStore.isLoggedIn ? `${memberStore.points} 點` : '登入 / 註冊' }}</span>
          </button>
        </div>

        <div class="tabs-wrap">
          <FulfillmentTabs v-model="fulfillment" />
        </div>

        <div class="search-bar">
          <span class="search-ic">🔍</span>
          <input v-model="query" placeholder="搜尋商家或餐點…" />
          <button v-if="query" class="clear" type="button" @click="query = ''">✕</button>
        </div>

        <div v-if="!isSearchMode" class="cuisine-row">
          <button :class="['cuisine', cuisine === '' ? 'active' : '']" type="button" @click="setCuisine('')">
            <span class="cuisine-ic">🍽️</span>
            <span>全部</span>
          </button>
          <button
            v-for="c in cuisineList"
            :key="c"
            :class="['cuisine', cuisine === c ? 'active' : '']"
            type="button"
            @click="setCuisine(cuisine === c ? '' : c)"
          >
            <span class="cuisine-ic">{{ cuisineIcon(c) }}</span>
            <span>{{ c }}</span>
          </button>
        </div>

        <div v-if="!isSearchMode" class="filter-row hide-desktop">
          <button class="filter-btn" type="button" @click="filterOpen = true">
            <span>篩選 / 排序</span>
            <span v-if="activeFilterCount" class="count">{{ activeFilterCount }}</span>
          </button>
          <span class="sort-tag">{{ sortLabel }}</span>
        </div>
      </div>
    </header>

    <main class="container body">
      <div class="layout">
        <aside v-if="!isSearchMode" class="filter-sidebar">
          <h3>排序與篩選</h3>
          <FilterControls v-model:sort="sort" v-model:prices="prices" v-model:open-now="openNow" />
        </aside>

        <div class="content">
          <div v-if="loading" class="state-page">載入中…</div>
          <div v-else-if="error" class="state-page">{{ error }}</div>

          <template v-else-if="isSearchMode">
            <div v-if="searchProducts.length" class="product-grid">
              <ProductCard v-for="p in searchProducts" :key="`${p.store_slug}-${p.product_id}`" :card="p" />
            </div>
            <p v-else class="state-page">找不到「{{ query.trim() }}」相關餐點</p>
          </template>

          <template v-else>
            <template v-if="showDiscovery">
              <BannerCarousel :banners="banners" @select="onBannerClick" />

              <section v-if="popularStores.length" class="rail">
                <h2>🔥 熱門商家</h2>
                <div class="rail-track">
                  <div v-for="s in popularStores" :key="s.slug" class="rail-item store">
                    <StoreCard :store="s" @toggle-fav="toggleFav(s)" />
                  </div>
                </div>
              </section>

              <section v-if="popularItems.length" class="rail">
                <h2>⭐ 熱門品項</h2>
                <div class="rail-track">
                  <div v-for="p in popularItems" :key="`${p.store_slug}-${p.product_id}`" class="rail-item product">
                    <ProductCard :card="p" />
                  </div>
                </div>
              </section>

              <h2 class="grid-title">探索全部商家</h2>
            </template>

            <div v-if="stores.length" class="store-grid">
              <StoreCard v-for="s in stores" :key="s.slug" :store="s" @toggle-fav="toggleFav(s)" />
            </div>
            <p v-else class="state-page">找不到符合條件的商家，試試調整篩選</p>
          </template>
        </div>
      </div>
    </main>

    <button v-if="cart.itemCount > 0" class="cart-fab" type="button" @click="$router.push({ name: 'cart' })">
      <span>購物車 {{ cart.itemCount }} 品項</span>
      <span>${{ Math.round(cart.subtotalCents) }}</span>
    </button>

    <FilterSheet
      :open="filterOpen"
      v-model:sort="sort"
      v-model:prices="prices"
      v-model:open-now="openNow"
      @close="filterOpen = false"
    />

    <MemberLoginModal :open="authOpen" :store-slug="''" :initial-mode="authMode" @close="authOpen = false" />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { fetchBanners, fetchPopularProducts, fetchProducts, fetchStores, toggleFavorite } from '@/api'
import ProductCard from '@/components/ProductCard.vue'
import StoreCard from '@/components/StoreCard.vue'
import FulfillmentTabs from '@/components/FulfillmentTabs.vue'
import FilterSheet from '@/components/FilterSheet.vue'
import FilterControls from '@/components/FilterControls.vue'
import BannerCarousel from '@/components/BannerCarousel.vue'
import MemberLoginModal from '@/components/MemberLoginModal.vue'
import type { MarketplaceBanner, MarketplaceProductCard, MarketplaceStoreSummary } from '@/types'
import { useCartStore } from '@/stores/cart'
import { useMemberStore } from '@/stores/member'

const route = useRoute()
const router = useRouter()
const cart = useCartStore()
const memberStore = useMemberStore()

const stores = ref<MarketplaceStoreSummary[]>([])
const searchProducts = ref<MarketplaceProductCard[]>([])
const banners = ref<MarketplaceBanner[]>([])
const popularStores = ref<MarketplaceStoreSummary[]>([])
const popularItems = ref<MarketplaceProductCard[]>([])
const loading = ref(true)
const error = ref('')

const query = ref(String(route.query.q || ''))
const fulfillment = ref<'delivery' | 'pickup'>('pickup')
const cuisine = ref('')
const sort = ref('recommended')
const prices = ref<number[]>([])
const openNow = ref(false)
const coords = ref<{ lat: number; lng: number } | null>(null)
const filterOpen = ref(false)
const authOpen = ref(false)
const authMode = ref<'login' | 'register'>('login')

function onMemberClick() {
  if (memberStore.isLoggedIn) {
    router.push({ name: 'member' })
  } else {
    authMode.value = 'login'
    authOpen.value = true
  }
}

const knownCuisines = ref<string[]>([])

const isSearchMode = computed(() => query.value.trim().length > 0)
const cuisineList = computed(() => knownCuisines.value)
const activeFilterCount = computed(
  () => prices.value.length + (openNow.value ? 1 : 0) + (sort.value !== 'recommended' ? 1 : 0),
)
const showDiscovery = computed(
  () => !isSearchMode.value && cuisine.value === '' && activeFilterCount.value === 0,
)
const sortLabel = computed(
  () =>
    ({
      recommended: '推薦排序',
      popular: '熱門',
      rating: '評分最高',
      distance: '距離最近',
      prep: '出餐最快',
    })[sort.value] || '推薦排序',
)

const CUISINE_ICONS: Record<string, string> = {
  飲料: '🥤',
  手搖: '🧋',
  咖啡: '☕',
  早餐: '🍳',
  便當: '🍱',
  日式: '🍣',
  韓式: '🍜',
  美式: '🍔',
  披薩: '🍕',
  甜點: '🍰',
  炸雞: '🍗',
  火鍋: '🍲',
  素食: '🥗',
  麵食: '🍜',
}
function cuisineIcon(c: string) {
  return CUISINE_ICONS[c] || '🍴'
}

function setCuisine(c: string) {
  cuisine.value = c
  loadStores()
}

async function loadStores() {
  loading.value = true
  error.value = ''
  try {
    const { data } = await fetchStores({
      fulfillment: fulfillment.value,
      sort: sort.value,
      cuisine: cuisine.value || undefined,
      price_level: prices.value.length ? prices.value.join(',') : undefined,
      open_now: openNow.value || undefined,
      lat: coords.value?.lat,
      lng: coords.value?.lng,
    })
    stores.value = data
    const set = new Set(knownCuisines.value)
    for (const s of data) for (const t of s.cuisine_tags ?? []) set.add(t)
    knownCuisines.value = [...set].slice(0, 12)
  } catch {
    error.value = '載入失敗，請稍後再試'
  } finally {
    loading.value = false
  }
}

async function loadSearch() {
  loading.value = true
  error.value = ''
  try {
    const { data } = await fetchProducts({
      q: query.value.trim(),
      fulfillment: fulfillment.value,
    })
    searchProducts.value = data
  } catch {
    error.value = '載入失敗，請稍後再試'
  } finally {
    loading.value = false
  }
}

async function loadDiscovery() {
  const [bn, ps, pi] = await Promise.all([
    fetchBanners().catch(() => ({ data: [] as MarketplaceBanner[] })),
    fetchStores({
      fulfillment: fulfillment.value,
      sort: 'popular',
      lat: coords.value?.lat,
      lng: coords.value?.lng,
    }).catch(() => ({ data: [] as MarketplaceStoreSummary[] })),
    fetchPopularProducts({ fulfillment: fulfillment.value, limit: 12 }).catch(
      () => ({ data: [] as MarketplaceProductCard[] }),
    ),
  ])
  banners.value = bn.data
  popularStores.value = ps.data.slice(0, 10)
  popularItems.value = pi.data
}

function reload() {
  if (isSearchMode.value) loadSearch()
  else loadStores()
}

function onBannerClick(b: MarketplaceBanner) {
  if (b.link_type === 'store' && b.link_target) {
    router.push({ name: 'store', params: { slug: b.link_target } })
  } else if (b.link_type === 'cuisine' && b.link_target) {
    query.value = ''
    setCuisine(b.link_target)
  } else if (b.link_type === 'external' && b.link_target) {
    window.open(b.link_target, '_blank', 'noopener')
  }
}

async function toggleFav(s: MarketplaceStoreSummary) {
  if (!memberStore.isLoggedIn) {
    router.push({ name: 'member' })
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

let debounceTimer: ReturnType<typeof setTimeout> | null = null
watch(query, () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    const q = query.value.trim()
    if (String(route.query.q || '') !== q) {
      router.replace({ name: 'home', query: q ? { q } : {} })
    }
    reload()
  }, 300)
})

watch(fulfillment, () => {
  reload()
  loadDiscovery()
})
watch([sort, prices, openNow], reload, { deep: true })

onMounted(() => {
  const start = () => {
    reload()
    loadDiscovery()
  }
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        coords.value = { lat: pos.coords.latitude, lng: pos.coords.longitude }
        start()
      },
      () => start(),
      { timeout: 5000 },
    )
  } else {
    start()
  }
})
</script>

<style scoped>
.disco-head {
  position: sticky;
  top: 0;
  z-index: 20;
  background: linear-gradient(180deg, #fff5f9 0%, var(--surface) 100%);
  border-bottom: 1px solid var(--border);
  padding: 16px 0 10px;
}
.head-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 0 16px;
}
.head-top h1 {
  margin: 0;
  font-size: 1.3rem;
}
.member-btn {
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  border: 0;
  background: #fff;
  color: var(--accent);
  border-radius: 18px;
  padding: 7px 14px;
  font-size: 13px;
  font-weight: 700;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.12);
}
.member-btn .ic {
  font-size: 15px;
}
.tabs-wrap {
  padding: 12px 16px 0;
}
.search-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 24px;
  padding: 0 14px;
  margin: 12px 16px 0;
  overflow: hidden;
}
.search-bar:focus-within {
  border-color: var(--accent);
}
.search-bar input,
.search-bar input:focus {
  flex: 1;
  min-width: 0;
  border: 0;
  outline: none;
  box-shadow: none;
  -webkit-appearance: none;
  appearance: none;
  -webkit-tap-highlight-color: transparent;
  border-radius: 0;
  padding: 12px 0;
  font-size: 16px;
  line-height: 1.4;
  background: transparent;
}
.search-ic,
.clear {
  flex-shrink: 0;
}
.search-ic {
  color: var(--muted);
}
.clear {
  border: 0;
  background: none;
  color: var(--muted);
  font-size: 14px;
}
.cuisine-row {
  display: flex;
  gap: 14px;
  overflow-x: auto;
  padding: 12px 16px 2px;
  -webkit-overflow-scrolling: touch;
}
.cuisine {
  flex-shrink: 0;
  border: 0;
  background: none;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: var(--muted);
  width: 56px;
}
.cuisine-ic {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: var(--surface);
  border: 1px solid var(--border);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
}
.cuisine.active {
  color: var(--accent);
  font-weight: 700;
}
.cuisine.active .cuisine-ic {
  border-color: var(--accent);
  background: var(--accent-soft);
}
.filter-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 4px 16px 0;
}
.filter-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border: 1px solid var(--accent);
  background: var(--surface);
  color: var(--accent);
  border-radius: 18px;
  padding: 7px 14px;
  font-size: 13px;
  font-weight: 600;
}
.filter-btn .count {
  background: var(--accent);
  color: #fff;
  border-radius: 9px;
  min-width: 18px;
  height: 18px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  padding: 0 5px;
}
.sort-tag {
  font-size: 12px;
  color: var(--muted);
}
.body {
  padding: 14px 16px 40px;
}
.layout {
  display: block;
}
.filter-sidebar {
  display: none;
}
.content {
  min-width: 0;
}
.rail {
  margin-bottom: 22px;
}
.rail h2,
.grid-title {
  font-size: 1.05rem;
  margin: 14px 0 10px;
}
.rail-track {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
  padding-bottom: 4px;
}
.rail-track::-webkit-scrollbar {
  display: none;
}
.rail-item.store {
  flex: 0 0 260px;
}
.rail-item.product {
  flex: 0 0 160px;
}
.store-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 14px;
}
.product-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}
@media (min-width: 900px) {
  .disco-head {
    position: static;
  }
  .head-top h1 {
    font-size: 1.6rem;
  }
  .hide-desktop {
    display: none;
  }
  .layout {
    display: grid;
    grid-template-columns: 240px 1fr;
    gap: 24px;
    align-items: start;
  }
  .filter-sidebar {
    display: block;
    position: sticky;
    top: 16px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 14px;
    padding: 16px;
  }
  .filter-sidebar h3 {
    margin: 0 0 14px;
    font-size: 1rem;
  }
  .store-grid {
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  }
  .product-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}
</style>
