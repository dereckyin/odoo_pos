<template>
  <div>
    <a-page-header title="寄賣入庫" sub-title="掃碼或輸入條碼，向 TAAZE 查書並送入門店庫存" />
    <a-form layout="vertical" style="max-width: 560px">
      <a-form-item label="門店" required>
        <a-select v-model:value="storeId" :options="storeOptions" placeholder="選擇門店" />
      </a-form-item>
      <a-form-item label="條碼（11 碼 TAAZE 商品編號或 8 碼他社）" required>
        <a-input-search
          v-model:value="barcode"
          placeholder="掃碼或輸入後按查詢"
          enter-button="查詢書目"
          :loading="lookingUp"
          @search="onLookup"
        />
      </a-form-item>

      <a-card v-if="preview" size="small" style="margin-bottom: 16px">
        <a-descriptions :column="1" size="small" bordered>
          <a-descriptions-item label="書名">{{ preview.title }}</a-descriptions-item>
          <a-descriptions-item label="作者">{{ preview.author }}</a-descriptions-item>
          <a-descriptions-item label="出版社">{{ preview.publisher }}</a-descriptions-item>
          <a-descriptions-item label="分類">
            {{ [preview.category_main, preview.category_sub].filter(Boolean).join(' / ') || '—' }}
          </a-descriptions-item>
          <a-descriptions-item label="牌價">{{ formatMoney(preview.list_price_cents) }}</a-descriptions-item>
          <a-descriptions-item label="售價">{{ formatMoney(preview.sale_price_cents) }}</a-descriptions-item>
          <a-descriptions-item label="折扣">
            {{ preview.sale_disc != null ? `${preview.sale_disc}折` : '—' }}
          </a-descriptions-item>
        </a-descriptions>
      </a-card>

      <a-form-item label="入庫數量" required>
        <a-input-number v-model:value="qty" :min="1" style="width: 160px" />
      </a-form-item>
      <a-space>
        <a-button type="primary" :loading="saving" :disabled="!preview" @click="submit">確認入庫</a-button>
        <a-button @click="$router.push({ name: 'book-import' })">CSV 批次入庫</a-button>
      </a-space>
    </a-form>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { lookupBook, receiveBook } from '@/api/books'
import type { BookLookup } from '@/api/books'
import { listStores } from '@/api/stores'

const storeId = ref<string>()
const barcode = ref('')
const qty = ref(1)
const lookingUp = ref(false)
const saving = ref(false)
const preview = ref<BookLookup | null>(null)
const storeOptions = ref<{ label: string; value: string }[]>([])

function formatMoney(cents: number | null | undefined) {
  if (cents == null) return '—'
  return (cents / 100).toFixed(0)
}

async function onLookup() {
  const code = barcode.value.trim()
  if (!code) {
    message.warning('請輸入條碼')
    return
  }
  lookingUp.value = true
  preview.value = null
  try {
    const { data } = await lookupBook(code)
    preview.value = data
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '查無書目')
  } finally {
    lookingUp.value = false
  }
}

async function submit() {
  if (!storeId.value || !preview.value) {
    message.warning('請選擇門店並先查詢書目')
    return
  }
  saving.value = true
  try {
    const { data } = await receiveBook({
      store_id: storeId.value,
      barcode: preview.value.barcode,
      qty: qty.value,
    })
    message.success(`入庫成功：${data.name}（庫存 ${data.on_hand ?? qty.value}）`)
    barcode.value = ''
    preview.value = null
    qty.value = 1
  } catch (e: any) {
    message.error(e?.response?.data?.detail || '入庫失敗')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  const { data: stores } = await listStores()
  storeOptions.value = stores.map((s) => ({ label: s.name, value: s.id }))
})
</script>
