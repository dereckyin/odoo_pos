<template>
  <aside class="cart">
    <header>
      <h2>購物車</h2>
      <span v-if="cart.tableLabel" class="table">{{ cart.tableLabel }}</span>
      <span class="count">{{ cart.itemCount }} 項</span>
    </header>

    <div v-if="!cart.lines.length" class="empty">點選商品加入購物車</div>
    <ul v-else class="lines">
      <li v-for="line in cart.lines" :key="line.lineKey">
        <div class="row">
          <strong>{{ line.product.name }}</strong>
          <span>{{ formatMoney(lineTotal(line)) }}</span>
        </div>
        <p v-if="line.selectedOptions.length" class="opts">
          {{ formatOpts(line.selectedOptions) }}
        </p>
        <div class="qty">
          <button @click="cart.setQty(line.lineKey, line.qty - 1)">−</button>
          <span>{{ line.qty }}</span>
          <button @click="cart.setQty(line.lineKey, line.qty + 1)">+</button>
        </div>
      </li>
    </ul>

    <section class="discount">
      <label>折扣
        <select v-model="cart.discountType">
          <option value="none">無</option>
          <option value="percentage">百分比</option>
          <option value="amount">固定金額</option>
        </select>
      </label>
      <input
        v-if="cart.discountType !== 'none'"
        v-model.number="cart.discountValue"
        type="number"
        min="0"
        :placeholder="cart.discountType === 'percentage' ? '%' : '元'"
      />
    </section>

    <footer>
      <div class="sum-row"><span>小計</span><span>{{ formatMoney(totals.subtotal) }}</span></div>
      <div v-if="totals.discount" class="sum-row"><span>折扣</span><span>-{{ formatMoney(totals.discount) }}</span></div>
      <div class="sum-row total"><span>應收</span><span>{{ formatMoney(totals.total) }}</span></div>
      <button class="checkout" data-testid="cart-checkout-btn" :disabled="!cart.lines.length" @click="emit('checkout')">結帳</button>
      <button class="clear" :disabled="!cart.lines.length" @click="cart.clear()">清空</button>
    </footer>
  </aside>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useCartStore } from '@/stores/cart'
import { calcTotals, unitPriceCents } from '@/lib/printPayloads'
import { formatMoney } from '@/utils/formatMoney'
import type { CartLine } from '@/stores/cart'
import type { SelectedOption } from '@/types'

const cart = useCartStore()
const emit = defineEmits<{ checkout: [] }>()

const totals = computed(() =>
  calcTotals(cart.lines, cart.discountType, cart.discountValue),
)

function lineTotal(line: CartLine) {
  return unitPriceCents(line.product.price_cents, line.selectedOptions) * line.qty
}

function formatOpts(opts: SelectedOption[]) {
  return opts.map((o) => o.choice_name).join(' · ')
}
</script>

<style scoped>
.cart {
  display: flex;
  flex-direction: column;
  background: #fff;
  border-left: 1px solid #e8e8e8;
  min-width: 300px;
  max-width: 360px;
}
header {
  padding: 12px 16px;
  border-bottom: 1px solid #f0f0f0;
  display: flex;
  align-items: center;
  gap: 8px;
}
h2 {
  margin: 0;
  font-size: 1rem;
  flex: 1;
}
.table {
  background: #e6f4ff;
  color: #0958d9;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 0.8rem;
}
.count {
  color: #888;
  font-size: 0.85rem;
}
.empty {
  flex: 1;
  display: grid;
  place-items: center;
  color: #999;
  padding: 24px;
}
.lines {
  list-style: none;
  margin: 0;
  padding: 8px 0;
  flex: 1;
  overflow: auto;
}
.lines li {
  padding: 10px 16px;
  border-bottom: 1px solid #f5f5f5;
}
.row {
  display: flex;
  justify-content: space-between;
}
.opts {
  margin: 4px 0;
  font-size: 0.8rem;
  color: #666;
}
.qty {
  display: flex;
  align-items: center;
  gap: 8px;
}
.qty button {
  width: 28px;
  height: 28px;
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  background: #fff;
}
.discount {
  padding: 12px 16px;
  border-top: 1px solid #f0f0f0;
  display: flex;
  gap: 8px;
  align-items: end;
}
.discount label {
  flex: 1;
  font-size: 0.85rem;
}
.discount select,
.discount input {
  display: block;
  width: 100%;
  margin-top: 4px;
  padding: 6px;
}
footer {
  padding: 12px 16px 16px;
  border-top: 1px solid #f0f0f0;
}
.sum-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 4px;
  font-size: 0.9rem;
}
.sum-row.total {
  font-weight: 700;
  font-size: 1.1rem;
  margin: 8px 0 12px;
}
.checkout {
  width: 100%;
  padding: 12px;
  border: none;
  border-radius: 8px;
  background: #52c41a;
  color: #fff;
  font-weight: 700;
  margin-bottom: 8px;
}
.checkout:disabled {
  opacity: 0.5;
}
.clear {
  width: 100%;
  padding: 8px;
  border: 1px solid #d9d9d9;
  border-radius: 8px;
  background: #fff;
  color: #666;
}
</style>
