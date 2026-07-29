<template>
  <div>
    <div class="subhead">
      <button type="button" class="back" @click="goMenu" v-html="ii('back', 16)" />
      <h2>訂單明細</h2>
      <span class="step">1 / 2 確認餐點</span>
    </div>
    <div class="page-body">
      <div class="card">
        <div v-if="!cart.lines.length" class="empty">尚未點餐</div>
        <div v-for="(it, i) in cart.lines" :key="it.key" class="cline">
          <div class="cinfo editable" @click="editLine(i)">
            <div class="cname">{{ it.name }}</div>
            <div v-if="it.optionsLabel" class="copts">{{ it.optionsLabel }}</div>
            <div v-if="it.note" class="copts">備註：{{ it.note }}</div>
            <div class="cedit"><span v-html="ii('pencil', 14)" /> 修改內容</div>
            <div class="cprice num">NT$ {{ moneyYuan(it.unitCents * it.qty) }}</div>
          </div>
          <div class="qty">
            <button type="button" @click="cart.changeQty(i, -1)">－</button>
            <span class="n num">{{ it.qty }}</span>
            <button type="button" @click="cart.changeQty(i, 1)">＋</button>
          </div>
        </div>
      </div>

      <div v-if="cart.belowMin() && session.store" class="card">
        <div class="minwarn">
          <span v-html="ii('moped', 14)" />
          外送需滿 <b>NT${{ session.store.deliveryMinCents }}</b>，目前 NT${{
            moneyYuan(cart.subtotal)
          }}，還差
          <b>NT${{ moneyYuan(session.store.deliveryMinCents - cart.subtotal) }}</b
          >，請再加點。
        </div>
      </div>

      <div class="card">
        <div class="card-title">整單備註<span class="hint">選填</span></div>
        <div class="fieldwrap">
          <textarea
            v-model="session.orderNote"
            class="note-input"
            rows="2"
            placeholder="例：餐點分兩批出、不要香菜"
          />
        </div>
      </div>

      <div class="card">
        <OrderSummary
          :mode="session.mode"
          :subtotal="cart.subtotal"
          :delivery-fee="session.deliveryFee"
          :discount="session.discount"
          :total="cart.grandTotal()"
        />
      </div>
    </div>

    <div class="footbtn">
      <div class="foothint">{{ hint }}</div>
      <button type="button" class="btn-red" :disabled="blocked" @click="goCheckout">
        前往結帳<span> NT$ {{ moneyYuan(cart.grandTotal()) }}</span>
      </button>
    </div>

    <OptionSheet
      :open="sheetOpen"
      :product="sheetProduct"
      :edit-index="editIndex"
      :initial-options="editOptions"
      :initial-qty="editQty"
      :initial-note="editNote"
      @close="sheetOpen = false"
      @confirm="onConfirm"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import OptionSheet from '@/components/OptionSheet.vue'
import OrderSummary from '@/components/OrderSummary.vue'
import { moneyYuan } from '@/entry'
import { ii } from '@/icons'
import { useCartStore } from '@/stores/cart'
import { useSessionStore } from '@/stores/session'
import type { MenuProduct, SelectedOption } from '@/types'

const session = useSessionStore()
const cart = useCartStore()
const router = useRouter()

const sheetOpen = ref(false)
const sheetProduct = ref<MenuProduct | null>(null)
const editIndex = ref<number | null>(null)
const editOptions = ref<SelectedOption[]>([])
const editQty = ref(1)
const editNote = ref('')

const blocked = computed(() => !cart.lines.length || cart.belowMin())
const hint = computed(() => {
  if (!cart.lines.length) return '請先點餐'
  if (cart.belowMin() && session.store) {
    return `還差 NT$${moneyYuan(session.store.deliveryMinCents - cart.subtotal)} 才能結帳`
  }
  return ''
})

function goMenu() {
  if (!cart.lines.length) router.replace({ name: 'home', query: session.entryQuery() })
  else router.push({ name: 'home', query: session.entryQuery() })
}

function goCheckout() {
  if (blocked.value) return
  router.push({ name: 'checkout', query: session.entryQuery() })
}

function editLine(i: number) {
  const line = cart.lines[i]
  const p = session.menu?.products.find((x) => x.id === line.productId)
  if (!p) return
  sheetProduct.value = p
  editIndex.value = i
  editOptions.value = line.options
  editQty.value = line.qty
  editNote.value = line.note
  sheetOpen.value = true
}

function onConfirm(payload: { options: SelectedOption[]; qty: number; note: string }) {
  const p = sheetProduct.value
  const idx = editIndex.value
  if (!p || idx == null) return
  cart.replaceLine(idx, {
    productId: p.id,
    name: p.name,
    baseCents: p.priceCents,
    qty: payload.qty,
    options: payload.options,
    note: payload.note,
    noDelivery: p.noDelivery,
  })
  sheetOpen.value = false
  editIndex.value = null
}
</script>
