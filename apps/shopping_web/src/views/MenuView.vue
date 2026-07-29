<template>
  <div>
    <header id="hdr" :class="{ shrink: shrunk }">
      <div class="brand-row">
        <div class="brand">
          <h1>{{ brandTitle }}</h1>
          <div class="branch">{{ brandBranch }}</div>
          <button
            v-if="session.storeSlug && session.storeSlug !== 'demo'"
            type="button"
            class="switch-store"
            @click="goPicker"
          >
            換店家
          </button>
        </div>
        <div v-if="session.mode === 'dinein'" class="table-chip">
          <span class="label">內用桌號</span>
          <span class="n num">{{ session.table || '—' }}</span>
        </div>
      </div>
      <div class="meta-row">
        <span class="badge-open">{{ session.store?.isOpen === false ? '休息中' : '營業中' }}</span>
        <span class="dot" />
        <span id="prepMeta">{{ prepText }}</span>
      </div>
      <ModeSwitch />
      <div class="powered">POWERED BY 餐飲聯盟平台</div>
    </header>

    <div class="pickstrip">
      <span v-html="stripIcon" />
      <span v-html="stripText" />
    </div>

    <div v-if="session.loading" class="loading-box">載入菜單中…</div>
    <div v-else class="layout">
      <nav class="rail">
        <button
          v-for="(c, i) in session.menu?.categories || []"
          :key="c.id"
          type="button"
          :class="{ active: activeCat === i }"
          @click="scrollToCat(i)"
        >
          {{ c.name }}
        </button>
      </nav>
      <main id="menu">
        <section
          v-for="(c, i) in session.menu?.categories || []"
          :id="`sec${i}`"
          :key="c.id"
          :ref="(el) => setSecRef(i, el)"
        >
          <div class="sec-head">
            <h2>{{ c.name }}</h2>
            <span class="en">{{ c.en }}</span>
            <span class="rule" />
          </div>
          <ProductCard
            v-for="p in productsByCat(c.id)"
            :key="p.id"
            :product="p"
            :mode="session.mode"
            :qty="qtyOf(p.id)"
            @add="openAdd(p)"
          />
        </section>
        <footer>
          {{ session.store?.name }}<br />
          線上點餐由「餐飲聯盟平台」提供
          <template v-if="session.isDemo"><br />（示範菜單）</template>
        </footer>
      </main>
    </div>

    <div class="cartbar" :class="{ show: cart.count > 0 }">
      <button
        type="button"
        class="cartbar-inner"
        :class="{ warn: cart.belowMin() }"
        @click="goCart"
      >
        <span class="cart-count num">{{ cart.count }}</span>
        <span class="cart-total">
          <small>NT$</small><span class="num">{{ moneyYuan(cart.subtotal) }}</span>
        </span>
        <span class="cart-go">
          <template v-if="cart.belowMin() && session.store">
            外送滿 {{ session.store.deliveryMinCents }}，還差 NT${{
              moneyYuan(session.store.deliveryMinCents - cart.subtotal)
            }}
          </template>
          <template v-else>
            查看訂單 <span v-html="ii('chevron', 16)" />
          </template>
        </span>
      </button>
    </div>

    <OptionSheet
      :open="sheetOpen"
      :product="sheetProduct"
      :edit-index="null"
      @close="sheetOpen = false"
      @confirm="onConfirm"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import ModeSwitch from '@/components/ModeSwitch.vue'
import OptionSheet from '@/components/OptionSheet.vue'
import ProductCard from '@/components/ProductCard.vue'
import { moneyYuan } from '@/entry'
import { ii } from '@/icons'
import { useCartStore } from '@/stores/cart'
import { useSessionStore } from '@/stores/session'
import type { MenuProduct, SelectedOption } from '@/types'

const session = useSessionStore()
const cart = useCartStore()
const router = useRouter()

const shrunk = ref(false)
const activeCat = ref(0)
const sheetOpen = ref(false)
const sheetProduct = ref<MenuProduct | null>(null)
const secEls = new Map<number, Element>()
let spy: IntersectionObserver | null = null
let railLock = false

const brandTitle = computed(() => {
  const n = session.store?.name || '點餐'
  return n.split('·')[0]?.trim() || n
})
const brandBranch = computed(() => {
  const n = session.store?.name || ''
  const parts = n.split('·')
  return parts.length > 1 ? `${parts.slice(1).join('·').trim()} · SHOPPING` : '統一點餐'
})

const prepText = computed(() =>
  session.mode === 'delivery' ? '外送約 30–40 分' : '出餐約 10–15 分',
)

const stripIcon = computed(() => {
  if (session.mode === 'dinein') return ii('dine', 15)
  if (session.mode === 'takeout') return ii('store', 15)
  return ii('moped', 15)
})

const stripText = computed(() => {
  const s = session.store
  if (session.mode === 'dinein') {
    return `內用 · 桌號 <b>${session.table}</b>　·　餐點做好送到您的桌邊／叫號`
  }
  if (session.mode === 'takeout') {
    return `到店自取　·　${s?.addr || ''}　·　備好會 <b>通知</b>`
  }
  return `<b>店家自己配送</b>　·　外送費 NT$${s?.deliveryFeeCents ?? 0}　·　滿 NT$${s?.deliveryMinCents ?? 0} 起送`
})

function productsByCat(catId: string) {
  return (session.menu?.products || []).filter((p) => p.categoryId === catId)
}

function qtyOf(productId: string) {
  return cart.lines.filter((l) => l.productId === productId).reduce((a, l) => a + l.qty, 0)
}

function openAdd(p: MenuProduct) {
  sheetProduct.value = p
  sheetOpen.value = true
}

function onConfirm(payload: { options: SelectedOption[]; qty: number; note: string }) {
  const p = sheetProduct.value
  if (!p) return
  cart.addLine({
    productId: p.id,
    name: p.name,
    baseCents: p.priceCents,
    qty: payload.qty,
    options: payload.options,
    note: payload.note,
    noDelivery: p.noDelivery,
  })
  sheetOpen.value = false
}

function goCart() {
  router.push({ name: 'cart', query: session.entryQuery() })
}

function goPicker() {
  cart.clear()
  session.menu = null
  session.loadError = ''
  session.storeSlug = ''
  router.replace({ path: '/', query: {} })
}

function setSecRef(i: number, el: unknown) {
  const node = el as Element | null
  if (node) secEls.set(i, node)
  else secEls.delete(i)
}

function markRail(i: number) {
  activeCat.value = i
}

function scrollToCat(i: number) {
  railLock = true
  markRail(i)
  document.getElementById(`sec${i}`)?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  setTimeout(() => {
    railLock = false
  }, 600)
}

function setupSpy() {
  spy?.disconnect()
  spy = new IntersectionObserver(
    (entries) => {
      if (railLock) return
      for (const e of entries) {
        if (e.isIntersecting) {
          const i = Number((e.target as HTMLElement).id.replace('sec', ''))
          if (!Number.isNaN(i)) markRail(i)
        }
      }
    },
    { rootMargin: '-130px 0px -65% 0px', threshold: 0 },
  )
  for (const [, el] of secEls) spy.observe(el)
}

/** Hysteresis: shrink changes header height and moves scrollY, so a single threshold oscillates. */
function onScroll() {
  const y = window.scrollY || document.documentElement.scrollTop || 0
  if (!shrunk.value && y > 80) shrunk.value = true
  else if (shrunk.value && y < 24) shrunk.value = false
}

onMounted(() => {
  window.addEventListener('scroll', onScroll)
  setTimeout(setupSpy, 50)
})

onUnmounted(() => {
  window.removeEventListener('scroll', onScroll)
  spy?.disconnect()
})
</script>

<style scoped>
.switch-store {
  margin-top: 6px;
  border: none;
  background: transparent;
  color: var(--muted);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.08em;
  padding: 0;
  text-decoration: underline;
  text-underline-offset: 2px;
}
</style>
