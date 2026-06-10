<template>
  <div>
    <a-page-header title="市集上架設定" sub-title="申請加入 pos.myvnc.com/market 跨店市集（正式推出前為內部預覽）">
      <template #extra>
        <a-select
          v-model:value="selectedStoreId"
          style="width: 220px"
          placeholder="選擇門店"
          :options="storeOptions"
          @change="loadListing"
        />
      </template>
    </a-page-header>

    <a-spin :spinning="loading">
      <a-empty v-if="!selectedStoreId" description="請先選擇門店" />
      <template v-else-if="!listing">
        <a-card>
          <p>此門店尚未建立市集資料。建立後可編輯 Logo、取餐方式並提交平台審核。</p>
          <a-form layout="vertical" style="max-width: 400px">
            <a-form-item label="市集顯示名稱" required>
              <a-input v-model:value="createName" placeholder="例如：老王便當店" />
            </a-form-item>
            <a-button type="primary" :loading="creating" @click="handleCreate">建立市集資料</a-button>
          </a-form>
        </a-card>
      </template>
      <a-form v-else layout="vertical" style="max-width: 720px">
        <a-alert
          :type="statusAlertType"
          :message="`狀態：${statusLabel(listing.status)}`"
          show-icon
          style="margin-bottom: 16px"
        />
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="顯示名稱">
              <a-input v-model:value="form.display_name" :disabled="!editable" />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="網址代稱 (slug)">
              <a-input :value="listing.slug" disabled />
            </a-form-item>
          </a-col>
        </a-row>
        <a-form-item label="一句話描述">
          <a-input v-model:value="form.tagline" :disabled="!editable" />
        </a-form-item>
        <a-row :gutter="16">
          <a-col :span="12">
            <a-form-item label="Logo URL">
              <a-input v-model:value="form.logo_url" :disabled="!editable" />
            </a-form-item>
          </a-col>
          <a-col :span="12">
            <a-form-item label="橫幅 URL">
              <a-input v-model:value="form.banner_url" :disabled="!editable" />
            </a-form-item>
          </a-col>
        </a-row>
        <a-form-item label="餐種標籤（逗號分隔）">
          <a-input v-model:value="cuisineInput" :disabled="!editable" placeholder="中式, 便當, 飲料" />
        </a-form-item>
        <a-row :gutter="16">
          <a-col :span="8">
            <a-form-item label="最低消費 (元)">
              <a-input-number v-model:value="minOrderYuan" :min="0" style="width: 100%" :disabled="!editable" />
            </a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="外送費 (元)">
              <a-input-number v-model:value="deliveryFeeYuan" :min="0" style="width: 100%" :disabled="!editable" />
            </a-form-item>
          </a-col>
          <a-col :span="8">
            <a-form-item label="外送半徑 (km)">
              <a-input-number v-model:value="form.delivery_radius_km" :min="0" style="width: 100%" :disabled="!editable" />
            </a-form-item>
          </a-col>
        </a-row>
        <a-row :gutter="16">
          <a-col :span="8">
            <a-form-item label="預估出餐時間 (分鐘)">
              <a-input-number v-model:value="form.prep_time_min" :min="0" :max="240" style="width: 100%" :disabled="!editable" />
            </a-form-item>
          </a-col>
          <a-col v-if="listing.rating_count > 0" :span="8">
            <a-form-item label="顧客評分">
              <span>★ {{ listing.rating_avg.toFixed(1) }}（{{ listing.rating_count }} 則評價）</span>
            </a-form-item>
          </a-col>
        </a-row>
        <a-form-item label="支援的取餐方式">
          <a-checkbox v-model:checked="form.supports_pickup" :disabled="!editable">外帶自取</a-checkbox>
          <a-checkbox v-model:checked="form.supports_delivery" :disabled="!editable">外送</a-checkbox>
          <a-checkbox v-model:checked="form.supports_dine_in" :disabled="!editable">內用</a-checkbox>
        </a-form-item>
        <a-form-item label="支援的付款方式">
          <a-checkbox v-model:checked="form.payment_counter" :disabled="!editable">櫃台付款</a-checkbox>
          <a-checkbox v-model:checked="form.payment_online" :disabled="!editable">線上付款</a-checkbox>
        </a-form-item>
        <a-form-item label="營業時間（未勾選的日期視為休息）">
          <div v-for="day in weekdays" :key="day.key" class="hours-row">
            <a-checkbox v-model:checked="hours[day.key].enabled" :disabled="!editable">{{ day.label }}</a-checkbox>
            <a-time-picker
              v-model:value="hours[day.key].open"
              format="HH:mm"
              value-format="HH:mm"
              :disabled="!editable || !hours[day.key].enabled"
              placeholder="開"
            />
            <span>—</span>
            <a-time-picker
              v-model:value="hours[day.key].close"
              format="HH:mm"
              value-format="HH:mm"
              :disabled="!editable || !hours[day.key].enabled"
              placeholder="關"
            />
          </div>
        </a-form-item>
        <a-space>
          <a-button v-if="editable" type="primary" :loading="saving" @click="handleSave">儲存</a-button>
          <a-button
            v-if="listing.status === 'draft' || listing.status === 'suspended'"
            type="primary"
            ghost
            :loading="submitting"
            @click="handleSubmit"
          >
            提交審核
          </a-button>
        </a-space>
      </a-form>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { message } from 'ant-design-vue'
import * as marketplaceApi from '@/api/marketplace'
import type { MarketplaceListing } from '@/api/marketplace'
import { listStores } from '@/api/stores'

const loading = ref(false)
const saving = ref(false)
const submitting = ref(false)
const creating = ref(false)
const selectedStoreId = ref<string>()
const storeOptions = ref<{ label: string; value: string }[]>([])
const listing = ref<MarketplaceListing | null>(null)
const createName = ref('')

const form = reactive({
  display_name: '',
  tagline: '',
  logo_url: '',
  banner_url: '',
  delivery_radius_km: null as number | null,
  prep_time_min: 15,
  supports_pickup: true,
  supports_delivery: false,
  supports_dine_in: false,
  payment_counter: true,
  payment_online: false,
})

const weekdays = [
  { key: 'mon', label: '週一' },
  { key: 'tue', label: '週二' },
  { key: 'wed', label: '週三' },
  { key: 'thu', label: '週四' },
  { key: 'fri', label: '週五' },
  { key: 'sat', label: '週六' },
  { key: 'sun', label: '週日' },
] as const

interface DayHours {
  enabled: boolean
  open: string
  close: string
}
const hours = reactive<Record<string, DayHours>>(
  Object.fromEntries(weekdays.map((d) => [d.key, { enabled: false, open: '09:00', close: '21:00' }])),
)

const cuisineInput = ref('')
const minOrderYuan = ref(0)
const deliveryFeeYuan = ref(0)

function buildBusinessHours(): Record<string, { open: string; close: string }[]> | null {
  const out: Record<string, { open: string; close: string }[]> = {}
  for (const d of weekdays) {
    const h = hours[d.key]
    if (h.enabled && h.open && h.close) out[d.key] = [{ open: h.open, close: h.close }]
  }
  return Object.keys(out).length ? out : null
}

const editable = computed(() => listing.value && ['draft', 'suspended'].includes(listing.value.status))
const statusAlertType = computed(() => {
  const s = listing.value?.status
  if (s === 'approved') return 'success'
  if (s === 'pending') return 'info'
  if (s === 'suspended') return 'warning'
  return 'info'
})

function statusLabel(s: string) {
  const map: Record<string, string> = {
    draft: '草稿',
    pending: '待審核',
    approved: '已上架',
    suspended: '已下架',
  }
  return map[s] ?? s
}

function fillForm(row: MarketplaceListing) {
  form.display_name = row.display_name
  form.tagline = row.tagline ?? ''
  form.logo_url = row.logo_url ?? ''
  form.banner_url = row.banner_url ?? ''
  form.delivery_radius_km = row.delivery_radius_km
  form.prep_time_min = row.prep_time_min ?? 15
  form.supports_pickup = row.supports_pickup
  form.supports_delivery = row.supports_delivery
  form.supports_dine_in = row.supports_dine_in
  form.payment_counter = row.payment_counter
  form.payment_online = row.payment_online
  cuisineInput.value = (row.cuisine_tags ?? []).join(', ')
  minOrderYuan.value = Math.round(row.min_order_cents / 100)
  deliveryFeeYuan.value = Math.round(row.delivery_fee_cents / 100)
  for (const d of weekdays) {
    const slots = row.business_hours?.[d.key]
    if (slots && slots.length) {
      hours[d.key] = { enabled: true, open: slots[0].open, close: slots[0].close }
    } else {
      hours[d.key] = { enabled: false, open: '09:00', close: '21:00' }
    }
  }
}

async function loadStores() {
  const { data } = await listStores()
  storeOptions.value = data.map((s) => ({ label: s.name, value: s.id }))
  if (data.length === 1) {
    selectedStoreId.value = data[0].id
    await loadListing()
  }
}

async function loadListing() {
  if (!selectedStoreId.value) return
  loading.value = true
  try {
    const { data } = await marketplaceApi.getListing(selectedStoreId.value)
    listing.value = data
    if (data) fillForm(data)
  } finally {
    loading.value = false
  }
}

async function handleCreate() {
  if (!selectedStoreId.value || !createName.value.trim()) {
    message.warning('請填寫顯示名稱')
    return
  }
  creating.value = true
  try {
    const { data } = await marketplaceApi.createListing(selectedStoreId.value, createName.value.trim())
    listing.value = data
    fillForm(data)
    message.success('已建立')
  } finally {
    creating.value = false
  }
}

async function handleSave() {
  if (!listing.value) return
  saving.value = true
  try {
    const { data } = await marketplaceApi.updateListing(listing.value.id, {
      display_name: form.display_name,
      tagline: form.tagline || null,
      logo_url: form.logo_url || null,
      banner_url: form.banner_url || null,
      cuisine_tags: cuisineInput.value.split(/[,，]/).map((s) => s.trim()).filter(Boolean),
      min_order_cents: minOrderYuan.value * 100,
      delivery_fee_cents: deliveryFeeYuan.value * 100,
      delivery_radius_km: form.delivery_radius_km,
      prep_time_min: form.prep_time_min,
      supports_pickup: form.supports_pickup,
      supports_delivery: form.supports_delivery,
      supports_dine_in: form.supports_dine_in,
      payment_counter: form.payment_counter,
      payment_online: form.payment_online,
      business_hours: buildBusinessHours(),
    })
    listing.value = data
    message.success('已儲存')
  } finally {
    saving.value = false
  }
}

async function handleSubmit() {
  if (!listing.value) return
  await handleSave()
  submitting.value = true
  try {
    const { data } = await marketplaceApi.submitListing(listing.value!.id)
    listing.value = data
    message.success('已提交審核')
  } finally {
    submitting.value = false
  }
}

onMounted(loadStores)
watch(selectedStoreId, () => {
  listing.value = null
})
</script>

<style scoped>
.hours-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}
.hours-row > .ant-checkbox-wrapper {
  width: 72px;
}
</style>
