<template>
  <div>
    <a-page-header title="門店管理">
      <template #extra>
        <a-button type="primary" @click="openModal()">新增門店</a-button>
      </template>
    </a-page-header>

    <a-table :columns="columns" :data-source="stores" :loading="loading" row-key="id" :pagination="false">
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'online'">
          <a-tag :color="isOnlineEnabled(record) ? 'green' : 'default'">
            {{ isOnlineEnabled(record) ? '已啟用' : '關閉' }}
          </a-tag>
        </template>
        <template v-else-if="column.key === 'actions'">
          <a-space>
            <a-button size="small" @click="openModal(record)">編輯</a-button>
            <a-button
              v-if="isOnlineEnabled(record)"
              size="small"
              @click="openLinkModal(record)"
            >
              點餐連結
            </a-button>
            <a-popconfirm title="確定刪除？" @confirm="handleDelete(record.id)">
              <a-button size="small" danger>刪除</a-button>
            </a-popconfirm>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal
      v-model:open="modalOpen"
      :title="editingId ? '編輯門店' : '新增門店'"
      @ok="handleSave"
      :confirm-loading="saving"
      width="560px"
    >
      <a-form :model="form" layout="vertical">
        <a-form-item label="門店代碼">
          <a-input v-model:value="form.code" />
        </a-form-item>
        <a-form-item label="名稱">
          <a-input v-model:value="form.name" />
        </a-form-item>
        <a-form-item label="統編">
          <a-input v-model:value="form.tax_id" />
        </a-form-item>
        <a-form-item label="地址">
          <a-input v-model:value="form.address" />
        </a-form-item>
        <a-form-item label="電話">
          <a-input v-model:value="form.phone" />
        </a-form-item>

        <a-divider orientation="left">統一點餐（線上點餐）</a-divider>
        <a-alert
          type="info"
          show-icon
          style="margin-bottom: 12px"
          message="需同時在平台啟用「桌邊點餐」模組，客人才能透過 /shopping/ 看到此店。"
        />
        <a-form-item label="啟用線上點餐">
          <a-switch v-model:checked="oo.enabled" />
        </a-form-item>
        <template v-if="oo.enabled">
          <a-form-item label="支援模式">
            <a-checkbox v-model:checked="oo.supports_dine_in">內用</a-checkbox>
            <a-checkbox v-model:checked="oo.supports_pickup">外帶</a-checkbox>
            <a-checkbox v-model:checked="oo.supports_delivery">外送</a-checkbox>
          </a-form-item>
          <a-form-item label="付款方式">
            <a-checkbox v-model:checked="oo.payment_counter">櫃台付</a-checkbox>
            <a-checkbox v-model:checked="oo.payment_online" disabled>線上付（即將開放）</a-checkbox>
          </a-form-item>
          <a-form-item label="最低消費（元）">
            <a-input-number v-model:value="oo.min_order_yuan" :min="0" style="width: 100%" />
          </a-form-item>
          <a-form-item label="外送運費（元）">
            <a-input-number v-model:value="oo.delivery_fee_yuan" :min="0" style="width: 100%" />
          </a-form-item>
        </template>
      </a-form>
    </a-modal>

    <a-modal v-model:open="linkOpen" title="統一點餐連結" :footer="null" width="420px">
      <div v-if="linkTarget" style="text-align: center">
        <qrcode-vue :value="linkUrl" :size="200" level="M" />
        <div style="margin-top: 12px; word-break: break-all; font-size: 13px">{{ linkUrl }}</div>
        <a-space style="margin-top: 16px">
          <a-button type="primary" @click="copyLink">複製連結</a-button>
          <a-button @click="openLink">開啟</a-button>
        </a-space>
      </div>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import QrcodeVue from 'qrcode.vue'
import { listStores, createStore, updateStore, deleteStore } from '@/api/stores'
import { shoppingOrderUrl } from '@/lib/shoppingOrderBase'
import type { OnlineOrderingSettings, StoreRead } from '@/types'

const stores = ref<StoreRead[]>([])
const loading = ref(false)
const modalOpen = ref(false)
const saving = ref(false)
const editingId = ref<string | null>(null)
const linkOpen = ref(false)
const linkTarget = ref<StoreRead | null>(null)

const form = reactive({
  code: '',
  name: '',
  tax_id: null as string | null,
  address: null as string | null,
  phone: null as string | null,
})

const oo = reactive({
  enabled: false,
  supports_pickup: true,
  supports_dine_in: true,
  supports_delivery: false,
  payment_counter: true,
  payment_online: false,
  min_order_yuan: 0,
  delivery_fee_yuan: 0,
})

const columns = [
  { title: '代碼', dataIndex: 'code', width: 120 },
  { title: '名稱', dataIndex: 'name' },
  { title: '統編', dataIndex: 'tax_id', width: 120 },
  { title: '地址', dataIndex: 'address' },
  { title: '電話', dataIndex: 'phone', width: 140 },
  { title: '線上點餐', key: 'online', width: 100 },
  { title: '操作', key: 'actions', width: 220 },
]

const linkUrl = computed(() =>
  linkTarget.value ? shoppingOrderUrl(linkTarget.value.id) : '',
)

function isOnlineEnabled(record: StoreRead) {
  return Boolean(record.online_ordering_json?.enabled)
}

function resetOo(settings?: OnlineOrderingSettings | null) {
  oo.enabled = Boolean(settings?.enabled)
  oo.supports_pickup = settings?.supports_pickup ?? true
  oo.supports_dine_in = settings?.supports_dine_in ?? true
  oo.supports_delivery = settings?.supports_delivery ?? false
  oo.payment_counter = settings?.payment_counter ?? true
  oo.payment_online = settings?.payment_online ?? false
  oo.min_order_yuan = Math.round((settings?.min_order_cents ?? 0) / 1) // cents==TWD in this monorepo
  oo.delivery_fee_yuan = Math.round((settings?.delivery_fee_cents ?? 0) / 1)
}

function ooPayload(): OnlineOrderingSettings {
  return {
    enabled: oo.enabled,
    supports_pickup: oo.supports_pickup,
    supports_dine_in: oo.supports_dine_in,
    supports_delivery: oo.supports_delivery,
    payment_counter: oo.payment_counter,
    payment_online: false,
    min_order_cents: Math.max(0, Math.round(oo.min_order_yuan || 0)),
    delivery_fee_cents: Math.max(0, Math.round(oo.delivery_fee_yuan || 0)),
  }
}

async function fetchData() {
  loading.value = true
  try {
    const { data } = await listStores()
    stores.value = data
  } finally {
    loading.value = false
  }
}

function openModal(record?: StoreRead) {
  if (record) {
    editingId.value = record.id
    form.code = record.code
    form.name = record.name
    form.tax_id = record.tax_id
    form.address = record.address
    form.phone = record.phone
    resetOo(record.online_ordering_json)
  } else {
    editingId.value = null
    form.code = ''
    form.name = ''
    form.tax_id = null
    form.address = null
    form.phone = null
    resetOo(null)
  }
  modalOpen.value = true
}

function openLinkModal(record: StoreRead) {
  linkTarget.value = record
  linkOpen.value = true
}

async function copyLink() {
  try {
    await navigator.clipboard.writeText(linkUrl.value)
    message.success('已複製連結')
  } catch {
    message.error('複製失敗，請手動選取')
  }
}

function openLink() {
  window.open(linkUrl.value, '_blank')
}

async function handleSave() {
  saving.value = true
  try {
    const payload = {
      ...form,
      online_ordering_json: ooPayload(),
    }
    if (editingId.value) {
      await updateStore(editingId.value, payload)
      message.success('已更新')
    } else {
      await createStore(payload)
      message.success('已建立')
    }
    modalOpen.value = false
    fetchData()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  } finally {
    saving.value = false
  }
}

async function handleDelete(id: string) {
  await deleteStore(id)
  message.success('已刪除')
  fetchData()
}

onMounted(fetchData)
</script>
