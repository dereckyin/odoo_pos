<template>
  <div class="page">
    <header class="topbar">
      <button class="back" @click="$router.back()">‹</button>
      <span class="title">購物車</span>
      <span class="spacer" />
    </header>

    <main v-if="cart.storeCount" class="body">
      <section v-for="sc in cart.orderedCarts" :key="sc.slug" class="store-block">
        <div class="store-head">
          <strong>{{ sc.meta.display_name }}</strong>
          <button class="link danger" @click="cart.clearStore(sc.slug)">移除</button>
        </div>
        <div v-for="line in sc.lines" :key="line.lineKey" class="line">
          <div class="line-head">
            <span class="lname">{{ line.product.name }}</span>
            <span>${{ Math.round(cart.unitPriceCents(line.product, line.selectedOptions) * line.qty) }}</span>
          </div>
          <div v-if="line.selectedOptions.length" class="opts">
            {{ line.selectedOptions.map((o) => o.choice_name).join('、') }}
          </div>
          <div class="qty-row">
            <button @click="cart.setQty(sc.slug, line.lineKey, line.qty - 1)">−</button>
            <span>{{ line.qty }}</span>
            <button @click="cart.setQty(sc.slug, line.lineKey, line.qty + 1)">+</button>
          </div>
        </div>
        <div class="store-sub">小計 ${{ Math.round(cart.storeSubtotalCents(sc.slug)) }}</div>
        <p v-if="belowMin(sc)" class="warn">
          未達最低消費 ${{ sc.meta.min_order_cents }}，還差 ${{ sc.meta.min_order_cents - Math.round(cart.storeSubtotalCents(sc.slug)) }}
        </p>
      </section>

      <div class="grand">
        <span>共 {{ cart.storeCount }} 家商店</span>
        <strong>合計 ${{ Math.round(cart.subtotalCents) }}</strong>
      </div>
    </main>
    <main v-else class="state-page"><p>購物車是空的</p></main>

    <button v-if="cart.storeCount" class="cart-fab" :disabled="anyBelowMin" @click="$router.push({ name: 'checkout' })">
      {{ anyBelowMin ? '部分商店未達低消' : `前往結帳 · $${Math.round(cart.subtotalCents)}` }}
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useCartStore } from '@/stores/cart'
import type { StoreCart } from '@/stores/cart'

const router = useRouter()
const cart = useCartStore()
if (!cart.storeCount) router.replace({ name: 'home' })

function belowMin(sc: StoreCart) {
  return cart.storeSubtotalCents(sc.slug) < (sc.meta.min_order_cents || 0)
}
const anyBelowMin = computed(() => cart.orderedCarts.some((sc) => belowMin(sc)))
</script>

<style scoped>
.body { padding: 16px; padding-bottom: 100px; }
.store-block { background: var(--surface); border-radius: 12px; padding: 14px; margin-bottom: 14px; box-shadow: 0 1px 3px rgba(15,23,42,.06); }
.store-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.line { border-top: 1px solid var(--border); padding: 10px 0; }
.line-head { display: flex; justify-content: space-between; gap: 8px; }
.lname { font-weight: 500; }
.opts { font-size: 12px; color: var(--muted); margin-top: 2px; }
.qty-row { display: flex; align-items: center; gap: 12px; margin-top: 8px; }
.qty-row button { width: 32px; height: 32px; border-radius: 8px; border: 1px solid var(--border); background: #fff; }
.store-sub { text-align: right; font-weight: 600; margin-top: 8px; }
.warn { color: #b33; font-size: 12px; margin: 6px 0 0; text-align: right; }
.grand { display: flex; justify-content: space-between; align-items: center; padding: 8px 4px; font-size: 16px; }
.link { background: none; border: none; color: var(--accent); }
.link.danger { color: #b33; }
.cart-fab:disabled { opacity: .6; }
</style>
