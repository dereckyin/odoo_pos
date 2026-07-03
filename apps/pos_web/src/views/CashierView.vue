<template>
  <div class="cashier">
    <section class="catalog">
      <div class="toolbar">
        <input v-model="catalog.searchQuery" placeholder="搜尋商品 / SKU / 條碼" />
        <div class="cats">
          <button :class="{ active: !catalog.selectedCategoryId }" @click="catalog.selectedCategoryId = null">
            全部
          </button>
          <button
            v-for="c in catalog.visibleCategories"
            :key="c.id"
            :class="{ active: catalog.selectedCategoryId === c.id }"
            @click="catalog.selectedCategoryId = c.id"
          >
            {{ c.name }}
          </button>
        </div>
      </div>
      <div v-if="catalog.loading" class="loading">載入中…</div>
      <div v-else class="grid" data-testid="product-grid">
        <button
          v-for="p in catalog.visibleProducts"
          :key="p.id"
          class="product"
          @click="onProductClick(p.id)"
        >
          <span class="name">{{ p.name }}</span>
          <span class="price">${{ (p.price_cents / 100).toFixed(0) }}</span>
        </button>
      </div>
    </section>
    <CartPanel @checkout="showCheckout = true" />

    <OptionModal
      :open="optionOpen"
      :product="optionProduct"
      @close="optionOpen = false"
      @confirm="onOptionConfirm"
    />

    <div v-if="showCheckout" class="overlay" @click.self="showCheckout = false">
      <div class="checkout-sheet">
        <h2>結帳</h2>
        <p class="amount">應收 <strong>${{ (totals.total / 100).toFixed(0) }}</strong></p>
        <label>付款方式
          <select v-model="payMethod">
            <option value="cash">現金</option>
            <option value="credit_card">信用卡</option>
            <option value="linepay">LINE Pay</option>
          </select>
        </label>
        <label v-if="payMethod === 'cash'">收款金額（元）
          <input v-model.number="tenderedYuan" type="number" min="0" />
        </label>
        <label><input v-model="issueInvoice" type="checkbox" /> 開立電子發票</label>
        <p v-if="checkoutError" class="error">{{ checkoutError }}</p>
        <div class="actions">
          <button :disabled="checkoutLoading" data-testid="checkout-confirm" @click="doCheckout">
            {{ checkoutLoading ? '處理中…' : '確認收款' }}
          </button>
          <button class="ghost" @click="showCheckout = false">取消</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import CartPanel from '@/components/CartPanel.vue'
import OptionModal from '@/components/OptionModal.vue'
import { useAuthStore } from '@/stores/auth'
import { useCartStore } from '@/stores/cart'
import { useCatalogStore } from '@/stores/catalog'
import { useShiftStore } from '@/stores/shift'
import * as ordersApi from '@/api/orders'
import { buildOrderPayload, calcTotals, enqueueCheckoutPrints } from '@/lib/printPayloads'
import { newUuid } from '@/lib/utils'
import type { ProductWithOptions, SelectedOption } from '@/types'
import type { InvoiceRead } from '@/types'

const auth = useAuthStore()
const cart = useCartStore()
const catalog = useCatalogStore()
const shift = useShiftStore()

const optionOpen = ref(false)
const optionProduct = ref<ProductWithOptions | null>(null)
const pendingProductId = ref<string | null>(null)

const showCheckout = ref(false)
const payMethod = ref('cash')
const tenderedYuan = ref(0)
const issueInvoice = ref(true)
const checkoutLoading = ref(false)
const checkoutError = ref('')

const totals = computed(() =>
  calcTotals(cart.lines, cart.discountType, cart.discountValue),
)

onMounted(() => catalog.load())

async function onProductClick(productId: string) {
  try {
    const withOpts = await catalog.loadProductOptions(productId)
    if (withOpts.option_groups.length) {
      pendingProductId.value = productId
      optionProduct.value = withOpts
      optionOpen.value = true
    } else {
      cart.add(withOpts, 1, [])
    }
  } catch {
    alert('無法載入商品選項')
  }
}

function onOptionConfirm(options: SelectedOption[]) {
  if (!optionProduct.value) return
  cart.add(optionProduct.value, 1, options)
  optionOpen.value = false
  optionProduct.value = null
}

async function doCheckout() {
  if (!auth.storeId || !auth.terminalId) {
    checkoutError.value = '缺少門市或終端資訊'
    return
  }
  checkoutLoading.value = true
  checkoutError.value = ''
  const orderId = newUuid()
  const paymentId = newUuid()
  const total = totals.value.total
  const tendered = payMethod.value === 'cash' ? Math.round((tenderedYuan.value || totals.value.total / 100) * 100) : total
  const change = Math.max(0, tendered - total)

  const orderPayload = buildOrderPayload({
    orderId,
    storeId: auth.storeId,
    terminalId: auth.terminalId,
    cashierId: auth.userId,
    shiftId: shift.current?.id ?? null,
    lines: cart.lines,
    payments: [{
      id: paymentId,
      method: payMethod.value,
      amount_cents: total,
      tendered_cents: payMethod.value === 'cash' ? tendered : undefined,
      change_due_cents: payMethod.value === 'cash' ? change : undefined,
    }],
    subtotal: totals.value.subtotal,
    discount: totals.value.discount,
    tax: totals.value.tax,
    total,
    note: cart.note || undefined,
    sourceGuestOrderId: cart.sourceGuestOrderId || undefined,
  })

  try {
    await ordersApi.uploadOrder(orderPayload)
    let invoice: InvoiceRead | null = null
    if (issueInvoice.value) {
      const invRes = await ordersApi.issueInvoice({
        order_id: orderId,
        tax_type: 1,
        gateway: 'ezpay',
      })
      invoice = invRes.data as InvoiceRead
    }

    await enqueueCheckoutPrints({
      orderPayload,
      invoice,
      cartLines: [...cart.lines],
      products: catalog.products,
      tableLabel: cart.tableLabel ?? undefined,
      needsProof: issueInvoice.value,
    })

    cart.clear()
    showCheckout.value = false
    alert('結帳成功，列印工作已送出')
  } catch (e: unknown) {
    const detail = (e as { response?: { data?: { detail?: string } } })?.response?.data?.detail
    checkoutError.value = typeof detail === 'string' ? detail : '結帳失敗'
  } finally {
    checkoutLoading.value = false
  }
}
</script>

<style scoped>
.cashier {
  display: flex;
  height: calc(100vh - 48px);
}
.catalog {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.toolbar {
  padding: 12px;
  background: #fff;
  border-bottom: 1px solid #e8e8e8;
}
.toolbar input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #d9d9d9;
  border-radius: 8px;
  margin-bottom: 8px;
}
.cats {
  display: flex;
  gap: 8px;
  overflow-x: auto;
}
.cats button {
  white-space: nowrap;
  border: 1px solid #d9d9d9;
  background: #fff;
  border-radius: 999px;
  padding: 4px 12px;
}
.cats button.active {
  background: #1677ff;
  color: #fff;
  border-color: #1677ff;
}
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 10px;
  padding: 12px;
  overflow: auto;
}
.product {
  background: #fff;
  border: 1px solid #e8e8e8;
  border-radius: 10px;
  padding: 12px;
  text-align: left;
  min-height: 72px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}
.name {
  font-weight: 600;
  font-size: 0.95rem;
}
.price {
  color: #1677ff;
  font-weight: 700;
}
.loading {
  padding: 24px;
  text-align: center;
  color: #888;
}
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  display: grid;
  place-items: center;
  z-index: 200;
}
.checkout-sheet {
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  width: min(400px, 92vw);
}
.checkout-sheet label {
  display: block;
  margin: 12px 0;
}
.checkout-sheet select,
.checkout-sheet input[type='number'] {
  display: block;
  width: 100%;
  margin-top: 6px;
  padding: 8px;
}
.actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 16px;
}
.actions button {
  padding: 12px;
  border: none;
  border-radius: 8px;
  background: #52c41a;
  color: #fff;
  font-weight: 700;
}
.actions button.ghost {
  background: #fff;
  border: 1px solid #d9d9d9;
  color: #666;
}
.error {
  color: #cf1322;
}
</style>
