<template>
  <div class="page">
    <header class="topbar">
      <button class="back" @click="$router.back()">‹</button>
      <span class="title">購物車</span>
      <span class="spacer" />
    </header>

    <main v-if="cart.lines.length" class="body">
      <p class="store-label">{{ cart.storeMeta?.display_name }}</p>
      <div v-for="line in cart.lines" :key="line.lineKey" class="line">
        <div class="line-head">
          <strong>{{ line.product.name }}</strong>
          <span>${{ Math.round(cart.unitPriceCents(line.product, line.selectedOptions)) }}</span>
        </div>
        <div class="qty-row">
          <button @click="cart.setQty(line.lineKey, line.qty - 1)">−</button>
          <span>{{ line.qty }}</span>
          <button @click="cart.setQty(line.lineKey, line.qty + 1)">+</button>
        </div>
      </div>
      <div class="total">小計 ${{ Math.round(cart.subtotalCents) }}</div>
    </main>
    <main v-else class="state-page"><p>購物車是空的</p></main>

    <button v-if="cart.lines.length" class="cart-fab" @click="$router.push({ name: 'checkout' })">
      前往結帳 · ${{ Math.round(cart.subtotalCents) }}
    </button>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useCartStore } from '@/stores/cart'

const router = useRouter()
const cart = useCartStore()
if (!cart.storeSlug) router.replace({ name: 'home' })
</script>

<style scoped>
.body { padding: 16px; }
.store-label { color: #6b5344; margin: 0 0 12px; }
.line { background: #fffcf8; border-radius: 10px; padding: 12px; margin-bottom: 10px; }
.line-head { display: flex; justify-content: space-between; }
.qty-row { display: flex; align-items: center; gap: 12px; margin-top: 8px; }
.qty-row button { width: 32px; height: 32px; border-radius: 8px; border: 1px solid #ddd; background: #fff; }
.total { text-align: right; font-weight: 700; font-size: 18px; margin-top: 16px; }
</style>
