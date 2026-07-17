<template>
  <div v-if="loading" class="state-page">載入中…</div>
  <div v-else-if="error" class="state-page">{{ error }}</div>
  <div v-else-if="menu" class="menu-page">
    <header class="store-header">
      <button class="back" @click="$router.push({ name: 'home' })">‹</button>
      <div class="store-head-info">
        <div class="store-name">{{ menu.meta.display_name }}</div>
        <div class="store-meta">
          <span v-if="detail" class="rating">★ {{ detail.rating_avg ? detail.rating_avg.toFixed(1) : '新店' }}<span v-if="detail.rating_count" class="rc">({{ detail.rating_count }})</span></span>
          <span v-if="detail">· {{ detail.prep_time_min }} 分</span>
          <span v-if="detail && detail.distance_km != null">· {{ detail.distance_km.toFixed(1) }} km</span>
          <span v-if="menu.meta.supports_delivery">· 外送 ${{ menu.meta.delivery_fee_cents }}</span>
          <span v-if="menu.meta.min_order_cents">· 低消 ${{ menu.meta.min_order_cents }}</span>
        </div>
        <div v-if="!menu.meta.is_open" class="closed">休息中</div>
      </div>
      <button class="fav" :class="{ on: detail?.is_favorite }" @click="toggleFav">
        {{ detail?.is_favorite ? '♥' : '♡' }}
      </button>
      <button class="member" type="button" @click="onMemberClick">
        <span class="ic">👤</span>
        <span>{{ memberStore.isLoggedIn ? `${memberStore.points}` : '登入' }}</span>
      </button>
    </header>

    <nav class="cat-bar">
      <button
        v-for="rootId in rootCategoryIds"
        :key="rootId"
        :class="{ active: activeCat === rootId }"
        @click="scrollToCat(rootId)"
      >
        {{ categoryById[rootId]?.name }}
      </button>
    </nav>

    <main class="menu-list" ref="listEl" @scroll.passive="onScroll">
      <section
        v-for="rootId in rootCategoryIds"
        :key="rootId"
        :ref="(el) => setSectionRef(rootId, el)"
        class="cat-section"
      >
        <h2>{{ categoryById[rootId]?.name }}</h2>
        <template v-for="cat in categoriesUnderRoot(rootId)" :key="cat.id">
          <h3 v-if="cat.depth === 1" class="sub-heading">{{ cat.name }}</h3>
          <div class="product-grid">
            <article v-for="p in productsByCat(cat.id)" :key="p.id" class="product" @click="addOne(p)">
              <div class="thumb">
                <img v-if="p.image_url" :src="resolveUploadPath(p.image_url)" alt="" />
                <div v-else class="img-placeholder">{{ p.name.charAt(0) }}</div>
                <button class="add" type="button" @click.stop="addOne(p)">＋</button>
              </div>
              <div class="info">
                <div class="name">{{ p.name }}</div>
                <div class="desc" v-if="p.description">{{ p.description }}</div>
                <div class="price">${{ Math.round(p.price_cents) }}</div>
              </div>
            </article>
          </div>
        </template>
      </section>
    </main>

    <button v-if="cart.itemCount > 0" class="cart-fab" @click="$router.push({ name: 'cart' })">
      <span>查看購物車 {{ cart.itemCount }}</span>
      <span>${{ Math.round(cart.subtotalCents) }}</span>
    </button>

    <OptionModal :open="optionProduct != null" :product="optionProduct" @close="optionProduct = null" @confirm="onOptionsConfirmed" />
    <MemberLoginModal :open="loginOpen" :store-slug="slug" @close="loginOpen = false" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { fetchStore, fetchStoreMenu, resolveUploadPath, toggleFavorite } from '@/api'
import type { MarketplaceMenu, MarketplaceStoreDetail, PublicProduct, PublicCategory, SelectedOption } from '@/types'
import { useCartStore } from '@/stores/cart'
import { useMemberStore } from '@/stores/member'
import OptionModal from '@/components/OptionModal.vue'
import MemberLoginModal from '@/components/MemberLoginModal.vue'

const route = useRoute()
const router = useRouter()
const cart = useCartStore()
const memberStore = useMemberStore()
const slug = computed(() => String(route.params.slug))
const loginOpen = ref(false)

function onMemberClick() {
  if (memberStore.isLoggedIn) router.push({ name: 'member' })
  else loginOpen.value = true
}

const menu = ref<MarketplaceMenu | null>(null)
const detail = ref<MarketplaceStoreDetail | null>(null)
const loading = ref(true)
const error = ref('')
const optionProduct = ref<PublicProduct | null>(null)
const sectionRefs = new Map<string, HTMLElement>()
const listEl = ref<HTMLElement | null>(null)
const activeCat = ref('')

const categoryById = computed(() => {
  const map: Record<string, PublicCategory> = {}
  for (const c of menu.value?.categories ?? []) map[c.id] = c
  return map
})

const rootCategoryIds = computed(() => {
  if (!menu.value) return [] as string[]
  if (menu.value.root_category_ids?.length) return menu.value.root_category_ids
  return menu.value.categories.filter((c) => c.depth === 0).map((c) => c.id)
})

function setSectionRef(id: string, el: unknown) {
  const node = el instanceof HTMLElement ? el : null
  if (node) sectionRefs.set(id, node)
}

function productsByCat(catId: string) {
  return menu.value?.products.filter((p) => p.category_id === catId) ?? []
}

function categoriesUnderRoot(rootId: string) {
  if (!menu.value) return [] as PublicCategory[]
  const byId = categoryById.value
  const isUnderRoot = (catId: string) => {
    let cur: PublicCategory | undefined = byId[catId]
    while (cur) {
      if (cur.id === rootId) return true
      cur = cur.parent_id ? byId[cur.parent_id] : undefined
    }
    return false
  }
  return menu.value.categories
    .filter((c) => isUnderRoot(c.id) && productsByCat(c.id).length > 0)
    .sort((a, b) => a.sort_order - b.sort_order)
}

function addOne(p: PublicProduct) {
  if (!menu.value) return
  if (p.option_groups?.length) optionProduct.value = p
  else cart.add(menu.value.meta, p, 1)
}

function onOptionsConfirmed(options: SelectedOption[]) {
  if (optionProduct.value && menu.value) {
    cart.add(menu.value.meta, optionProduct.value, 1, options)
    optionProduct.value = null
  }
}

function scrollToCat(catId: string) {
  const target = sectionRefs.get(catId)
  if (target && listEl.value) listEl.value.scrollTo({ top: target.offsetTop - 8, behavior: 'smooth' })
}

function onScroll() {
  if (!listEl.value) return
  const top = listEl.value.scrollTop + 24
  let current = activeCat.value
  for (const rootId of rootCategoryIds.value) {
    const el = sectionRefs.get(rootId)
    if (el && el.offsetTop <= top) current = rootId
  }
  activeCat.value = current
}

async function loadMenu() {
  loading.value = true
  error.value = ''
  try {
    const [{ data }, detailRes] = await Promise.all([
      fetchStoreMenu(slug.value),
      fetchStore(slug.value).catch(() => null),
    ])
    menu.value = data
    detail.value = detailRes?.data ?? null
    if (rootCategoryIds.value[0]) activeCat.value = rootCategoryIds.value[0]
  } catch (e: unknown) {
    const err = e as { response?: { data?: { detail?: string } } }
    error.value = err.response?.data?.detail || '載入菜單失敗'
  } finally {
    loading.value = false
  }
}

async function toggleFav() {
  if (!memberStore.isLoggedIn) {
    alert('請先登入會員')
    return
  }
  if (!detail.value) return
  const next = !detail.value.is_favorite
  detail.value.is_favorite = next
  try {
    await toggleFavorite(slug.value, next)
  } catch {
    if (detail.value) detail.value.is_favorite = !next
  }
}

watch(slug, () => void loadMenu(), { immediate: true })
</script>

<style scoped>
.menu-page { display: flex; flex-direction: column; height: 100dvh; background: var(--paper); }
.store-header {
  display: flex; align-items: center; gap: 6px;
  padding: 8px 10px; background: var(--paper); border-bottom: 1px solid var(--border);
}
.store-head-info { flex: 1; min-width: 0; }
.back { border: 0; background: transparent; font-size: 22px; padding: 0 4px; line-height: 1; }
.store-name { font-weight: 700; font-size: 15px; letter-spacing: 0.03em; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.store-meta { font-size: 11px; color: var(--muted); margin-top: 1px; display: flex; gap: 4px; flex-wrap: wrap; }
.store-meta .rating { color: var(--amber); font-weight: 700; }
.store-meta .rc { color: var(--muted); font-weight: 400; }
.fav { border: 1px solid var(--border); background: var(--surface); border-radius: 6px; width: 32px; height: 32px; font-size: 16px; color: var(--accent); }
.fav.on { color: var(--accent); }
.member {
  flex-shrink: 0; display: inline-flex; align-items: center; gap: 3px;
  border: 1px solid var(--border); background: var(--surface); color: var(--ink);
  border-radius: 6px; padding: 5px 8px; font-size: 12px; font-weight: 700;
}
.member .ic { font-size: 13px; }
.closed { color: var(--accent); font-size: 11px; font-weight: 700; }
.cat-bar {
  display: flex; overflow-x: auto; gap: 4px;
  padding: 6px 8px; background: var(--paper); border-bottom: 1px solid var(--border);
}
.cat-bar button {
  flex-shrink: 0; border: 1px solid var(--border); background: var(--surface);
  padding: 5px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; color: var(--muted);
}
.cat-bar button.active {
  border-color: var(--accent); border-width: 1.5px; color: var(--accent); background: var(--surface);
}
.menu-list { flex: 1; overflow-y: auto; padding: 10px 10px 72px; }
.cat-section h2 { font-size: 14px; font-weight: 700; letter-spacing: 0.06em; margin: 10px 2px 6px; }
.sub-heading { font-size: 12px; margin: 6px 2px; color: var(--muted); }
.product-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; margin-bottom: 10px; }
.product {
  background: var(--surface); border-radius: 8px; overflow: hidden;
  display: flex; flex-direction: column; cursor: pointer;
  border: 1px solid var(--border); box-shadow: none;
}
.product .thumb { position: relative; aspect-ratio: 4 / 3; background: var(--accent-soft); border-bottom: 1px solid var(--border); }
.product .thumb img, .product .img-placeholder { width: 100%; height: 100%; object-fit: cover; }
.product .img-placeholder { display: flex; align-items: center; justify-content: center; color: var(--accent); font-weight: 700; font-size: 28px; }
.product .add {
  position: absolute; right: 6px; bottom: 6px; min-width: 28px; height: 28px;
  border-radius: 6px; border: 0; background: var(--accent); color: #fff;
  font-size: 16px; line-height: 1; box-shadow: none;
}
.product .info { padding: 8px 9px 10px; display: flex; flex-direction: column; gap: 2px; }
.product .name { font-weight: 700; font-size: 13px; }
.product .desc { font-size: 11px; color: var(--muted); display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.product .price { color: var(--accent); font-weight: 700; margin-top: 2px; font-size: 13px; }
@media (min-width: 900px) {
  .store-header, .cat-bar, .cat-section { max-width: var(--container-max); margin-left: auto; margin-right: auto; width: 100%; }
  .product-grid { grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); }
  .product:hover { border-color: var(--accent); }
}
</style>
