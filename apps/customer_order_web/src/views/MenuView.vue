<template>
  <div v-if="loading" class="state-page">載入中…</div>
  <div v-else-if="error" class="state-page error">
    <p>{{ error }}</p>
    <button class="btn" @click="loadMenu">重試</button>
  </div>
  <div v-else-if="menu" class="menu-page">
    <header class="topbar">
      <div class="store-name">{{ menu.meta.store_name }}</div>
      <div class="table-tag">桌 {{ menu.meta.table_label }}</div>
    </header>

    <nav class="cat-bar">
      <button
        v-for="c in menu.categories"
        :key="c.id"
        :class="{ active: activeCat === c.id }"
        @click="scrollToCat(c.id)"
      >
        {{ c.name }}
      </button>
    </nav>

    <main class="menu-list" ref="listEl" @scroll.passive="onScroll">
      <section
        v-for="c in menu.categories"
        :key="c.id"
        :ref="(el) => setSectionRef(c.id, el)"
        class="cat-section"
      >
        <h2>{{ c.name }}</h2>
        <article
          v-for="p in productsByCat(c.id)"
          :key="p.id"
          class="product"
          @click="addOne(p)"
        >
          <div class="info">
            <div class="name">{{ p.name }}</div>
            <div class="desc" v-if="p.description">{{ p.description }}</div>
            <div class="price">${{ priceLabel(p) }}</div>
          </div>
          <img
            v-if="p.image_url && !failedImageIds.has(p.id)"
            :src="resolveImageUrl(p.image_url)"
            :data-product-id="p.id"
            @error="onImageError"
          />
          <div v-else class="img-placeholder">{{ p.name.charAt(0) }}</div>
        </article>
      </section>
    </main>

    <footer class="cart-bar" v-if="cart.itemCount > 0" @click="goCart">
      <span class="count">{{ cart.itemCount }}</span>
      <span>查看購物車</span>
      <span class="subtotal">${{ Math.round(cart.subtotalCents / 100) }}</span>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { fetchMenu } from '@/api'
import type { PublicMenu, PublicProduct } from '@/types'
import { useCartStore } from '@/stores/cart'

const router = useRouter()
const route = useRoute()
const cart = useCartStore()

const menu = ref<PublicMenu | null>(null)
const loading = ref(true)
const error = ref('')
const token = ref('')

const sectionRefs = new Map<string, HTMLElement>()
const listEl = ref<HTMLElement | null>(null)
const activeCat = ref<string>('')
const failedImageIds = ref(new Set<string>())

function setSectionRef(id: string, el: Element | null) {
  if (!(el instanceof HTMLElement)) return
  if (el) sectionRefs.set(id, el)
}

function productsByCat(catId: string) {
  if (!menu.value) return [] as PublicProduct[]
  return menu.value.products.filter((p) => p.category_id === catId)
}

function priceLabel(p: PublicProduct) {
  return Math.round(p.price_cents / 100).toString()
}

function addOne(p: PublicProduct) {
  cart.add(p, 1)
}

function resolveImageUrl(url: string) {
  // Uploaded product images are stored as `/uploads/...`. In dev this is
  // proxied by Vite; in production same-origin deployment also works.
  return url
}

function onImageError(e: Event) {
  const img = e.target as HTMLImageElement
  const id = img.dataset.productId
  if (!id) return
  const next = new Set(failedImageIds.value)
  next.add(id)
  failedImageIds.value = next
}

function goCart() {
  router.push({ path: '/cart', query: { t: token.value } })
}

function scrollToCat(catId: string) {
  const target = sectionRefs.get(catId)
  if (target && listEl.value) {
    listEl.value.scrollTo({ top: target.offsetTop - 8, behavior: 'smooth' })
  }
}

function onScroll() {
  if (!listEl.value || !menu.value) return
  const top = listEl.value.scrollTop + 24
  let current = activeCat.value
  for (const c of menu.value.categories) {
    const el = sectionRefs.get(c.id)
    if (el && el.offsetTop <= top) current = c.id
  }
  activeCat.value = current
}

async function loadMenu() {
  loading.value = true
  error.value = ''
  try {
    const t = (route.query.t as string) || ''
    if (!t) {
      router.replace({ name: 'no-token' })
      return
    }
    token.value = t
    const { data } = await fetchMenu(t)
    menu.value = data
    if (data.categories[0]) activeCat.value = data.categories[0].id
  } catch (e: any) {
    error.value = e.response?.data?.detail || '載入菜單失敗'
  } finally {
    loading.value = false
  }
}

onMounted(loadMenu)
</script>

<style scoped>
.state-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  gap: 12px;
}
.state-page.error {
  color: #c00;
}
.btn {
  padding: 10px 16px;
  background: #ff6b35;
  color: #fff;
  border: 0;
  border-radius: 8px;
  font-size: 16px;
}
.menu-page {
  display: flex;
  flex-direction: column;
  height: 100vh;
}
.topbar {
  position: sticky;
  top: 0;
  background: #fff;
  padding: 12px 16px;
  border-bottom: 1px solid #eee;
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 10;
}
.store-name {
  font-size: 16px;
  font-weight: 600;
}
.table-tag {
  background: #ff6b35;
  color: #fff;
  padding: 4px 10px;
  border-radius: 16px;
  font-size: 13px;
}
.cat-bar {
  position: sticky;
  top: 49px;
  background: #fff;
  display: flex;
  overflow-x: auto;
  padding: 8px 8px;
  border-bottom: 1px solid #eee;
  z-index: 9;
}
.cat-bar button {
  flex-shrink: 0;
  background: transparent;
  border: 0;
  padding: 8px 14px;
  font-size: 14px;
  color: #666;
  border-radius: 16px;
}
.cat-bar button.active {
  background: #ffeee6;
  color: #ff6b35;
  font-weight: 600;
}
.menu-list {
  flex: 1;
  overflow-y: auto;
  padding: 12px 12px 96px;
}
.cat-section h2 {
  font-size: 16px;
  margin: 16px 4px 8px;
  color: #333;
}
.product {
  background: #fff;
  border-radius: 10px;
  padding: 12px;
  margin-bottom: 10px;
  display: flex;
  gap: 12px;
  align-items: center;
}
.product .info {
  flex: 1;
  min-width: 0;
}
.product .name {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 4px;
}
.product .desc {
  font-size: 12px;
  color: #888;
  margin-bottom: 6px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.product .price {
  font-size: 16px;
  font-weight: 600;
  color: #ff6b35;
}
.product img,
.product .img-placeholder {
  width: 84px;
  height: 84px;
  object-fit: cover;
  border-radius: 8px;
  flex-shrink: 0;
}
.product .img-placeholder {
  background: #ffeee6;
  color: #ff6b35;
  font-size: 28px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}
.cart-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: #ff6b35;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px calc(12px + env(safe-area-inset-bottom));
  font-size: 16px;
  font-weight: 600;
}
.cart-bar .count {
  background: #fff;
  color: #ff6b35;
  border-radius: 12px;
  min-width: 28px;
  height: 28px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
}
</style>
