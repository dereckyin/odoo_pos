<template>
  <div>
    <a-page-header title="租戶設定" sub-title="付款 / 發票金鑰、訂閱用量、稽核紀錄" :back-icon="false" />

    <a-tabs v-model:active-key="activeTab" type="card">
      <!-- ───── Payment gateways ───── -->
      <a-tab-pane key="payments" tab="付款金流">
        <a-alert
          message="敏感金鑰會以 Fernet 對稱加密儲存，前端只看得到 merchant_id 與遮罩狀態。"
          type="info"
          show-icon
          style="margin-bottom: 16px"
        />
        <a-table
          :columns="paymentColumns"
          :data-source="paymentRows"
          :loading="paymentLoading"
          row-key="driver"
          size="small"
          :pagination="false"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'is_enabled'">
              <a-tag :color="record.is_enabled ? 'green' : 'default'">
                {{ record.is_enabled ? '啟用中' : '停用' }}
              </a-tag>
            </template>
            <template v-else-if="column.key === 'sandbox'">
              <a-tag :color="record.is_sandbox ? 'orange' : 'red'">
                {{ record.is_sandbox ? 'sandbox' : 'production' }}
              </a-tag>
            </template>
            <template v-else-if="column.key === 'actions'">
              <a-space>
                <a-button size="small" @click="editPayment(record)">編輯</a-button>
                <a-popconfirm
                  title="刪除此驅動程式設定？"
                  ok-text="刪除"
                  ok-type="danger"
                  @confirm="removePayment(record.driver)"
                >
                  <a-button size="small" danger>刪除</a-button>
                </a-popconfirm>
              </a-space>
            </template>
          </template>
        </a-table>
        <a-button type="primary" style="margin-top: 12px" @click="newPayment">
          <template #icon><PlusOutlined /></template>
          新增 / 替換金流設定
        </a-button>
      </a-tab-pane>

      <!-- ───── Invoice gateways ───── -->
      <a-tab-pane key="invoices" tab="電子發票">
        <a-table
          :columns="invoiceColumns"
          :data-source="invoiceRows"
          :loading="invoiceLoading"
          row-key="driver"
          size="small"
          :pagination="false"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'is_enabled'">
              <a-tag :color="record.is_enabled ? 'green' : 'default'">
                {{ record.is_enabled ? '啟用中' : '停用' }}
              </a-tag>
            </template>
            <template v-else-if="column.key === 'sandbox'">
              <a-tag :color="record.is_sandbox ? 'orange' : 'red'">
                {{ record.is_sandbox ? 'sandbox' : 'production' }}
              </a-tag>
            </template>
            <template v-else-if="column.key === 'actions'">
              <a-button size="small" @click="editInvoice(record)">編輯</a-button>
            </template>
          </template>
        </a-table>
        <a-button type="primary" style="margin-top: 12px" @click="newInvoice">
          <template #icon><PlusOutlined /></template>
          新增 / 替換發票設定
        </a-button>
      </a-tab-pane>

      <!-- ───── Subscription / usage ───── -->
      <a-tab-pane key="subscription" tab="訂閱與用量">
        <a-row :gutter="16">
          <a-col :xs="24" :md="12">
            <a-card title="目前方案" :bordered="false">
              <template v-if="plan">
                <a-descriptions :column="1" size="small">
                  <a-descriptions-item label="方案代號">{{ plan.code }}</a-descriptions-item>
                  <a-descriptions-item label="名稱">{{ plan.name }}</a-descriptions-item>
                  <a-descriptions-item label="價格">
                    {{ plan.price_cents > 0 ? `$${plan.price_cents / 100} / ${plan.interval}` : '免費' }}
                  </a-descriptions-item>
                  <a-descriptions-item label="店家上限">{{ plan.max_stores }}</a-descriptions-item>
                  <a-descriptions-item label="終端機上限">{{ plan.max_terminals }}</a-descriptions-item>
                  <a-descriptions-item label="月訂單上限">{{ plan.max_orders_per_month }}</a-descriptions-item>
                  <a-descriptions-item label="商品數量上限">{{ plan.max_products }}</a-descriptions-item>
                </a-descriptions>
              </template>
              <a-empty v-else description="尚未訂閱方案" />
            </a-card>
          </a-col>
          <a-col :xs="24" :md="12">
            <a-card title="本期用量" :bordered="false">
              <a-list size="small" :data-source="usage" :loading="usageLoading">
                <template #renderItem="{ item }">
                  <a-list-item>
                    <a-list-item-meta :title="item.metric">
                      <template #description>{{ item.period }}</template>
                    </a-list-item-meta>
                    <a-typography-text strong>{{ item.value }}</a-typography-text>
                  </a-list-item>
                </template>
              </a-list>
            </a-card>
          </a-col>
        </a-row>
      </a-tab-pane>

      <!-- ───── Audit logs ───── -->
      <a-tab-pane key="audit" tab="稽核紀錄">
        <a-table
          :columns="auditColumns"
          :data-source="auditRows"
          :loading="auditLoading"
          row-key="id"
          size="small"
          :pagination="{ pageSize: 20 }"
        >
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'created_at'">
              {{ new Date(record.created_at).toLocaleString() }}
            </template>
            <template v-else-if="column.key === 'extra'">
              <a-typography-text v-if="record.extra" code copyable>
                {{ JSON.stringify(record.extra) }}
              </a-typography-text>
            </template>
          </template>
        </a-table>
      </a-tab-pane>
    </a-tabs>

    <!-- ───── Payment edit modal ───── -->
    <a-modal
      v-model:open="paymentModalOpen"
      :title="paymentForm.driver ? `編輯 ${paymentForm.driver}` : '新增金流設定'"
      :confirm-loading="paymentSaving"
      ok-text="儲存"
      @ok="savePayment"
    >
      <a-form layout="vertical">
        <a-form-item label="驅動程式" :rules="[{ required: true }]">
          <a-select v-model:value="paymentForm.driver" :disabled="!!paymentEditingExisting">
            <a-select-option value="ecpay">ECPay 綠界 (信用卡)</a-select-option>
            <a-select-option value="newebpay">NewebPay 藍新 (信用卡)</a-select-option>
            <a-select-option value="linepay">LINE Pay</a-select-option>
            <a-select-option value="cash">現金 (無金鑰)</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="商編 / merchant_id">
          <a-input v-model:value="paymentForm.merchant_id" />
        </a-form-item>
        <a-form-item label="HashKey" v-if="paymentForm.driver !== 'cash' && paymentForm.driver !== 'linepay'">
          <a-input-password v-model:value="paymentForm.hash_key" placeholder="留白表示不變更" />
        </a-form-item>
        <a-form-item label="HashIV" v-if="paymentForm.driver !== 'cash' && paymentForm.driver !== 'linepay'">
          <a-input-password v-model:value="paymentForm.hash_iv" placeholder="留白表示不變更" />
        </a-form-item>
        <a-form-item label="Channel ID" v-if="paymentForm.driver === 'linepay'">
          <a-input-password v-model:value="paymentForm.channel_id" placeholder="留白表示不變更" />
        </a-form-item>
        <a-form-item label="Channel Secret" v-if="paymentForm.driver === 'linepay'">
          <a-input-password v-model:value="paymentForm.channel_secret" placeholder="留白表示不變更" />
        </a-form-item>
        <a-form-item>
          <a-checkbox v-model:checked="paymentForm.is_sandbox">使用沙箱環境</a-checkbox>
        </a-form-item>
        <a-form-item>
          <a-checkbox v-model:checked="paymentForm.is_enabled">啟用此驅動程式</a-checkbox>
        </a-form-item>
      </a-form>
    </a-modal>

    <!-- ───── Invoice edit modal ───── -->
    <a-modal
      v-model:open="invoiceModalOpen"
      :title="invoiceForm.driver ? `編輯 ${invoiceForm.driver}` : '新增發票設定'"
      :confirm-loading="invoiceSaving"
      ok-text="儲存"
      @ok="saveInvoice"
    >
      <a-form layout="vertical">
        <a-form-item label="驅動程式">
          <a-select v-model:value="invoiceForm.driver" :disabled="!!invoiceEditingExisting">
            <a-select-option value="ecpay">ECPay 電子發票</a-select-option>
            <a-select-option value="ezpay">EzPay 電子發票</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="商編">
          <a-input v-model:value="invoiceForm.merchant_id" />
        </a-form-item>
        <a-form-item label="HashKey">
          <a-input-password v-model:value="invoiceForm.hash_key" placeholder="留白表示不變更" />
        </a-form-item>
        <a-form-item label="HashIV">
          <a-input-password v-model:value="invoiceForm.hash_iv" placeholder="留白表示不變更" />
        </a-form-item>
        <a-form-item label="本店統編 (蓋章用)">
          <a-input v-model:value="invoiceForm.company_tax_id" />
        </a-form-item>
        <a-form-item>
          <a-checkbox v-model:checked="invoiceForm.is_sandbox">使用沙箱環境</a-checkbox>
        </a-form-item>
        <a-form-item>
          <a-checkbox v-model:checked="invoiceForm.is_enabled">啟用此驅動程式</a-checkbox>
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import { PlusOutlined } from '@ant-design/icons-vue'
import * as tenantApi from '@/api/tenant'
import type { SubscriptionPlanRead } from '@/types'

const activeTab = ref<'payments' | 'invoices' | 'subscription' | 'audit'>('payments')

// ----- Payments -----
const paymentRows = ref<tenantApi.TenantPaymentSettingRead[]>([])
const paymentLoading = ref(false)
const paymentModalOpen = ref(false)
const paymentSaving = ref(false)
const paymentEditingExisting = ref(false)
const paymentForm = ref<{
  driver: 'ecpay' | 'newebpay' | 'linepay' | 'cash'
  merchant_id: string
  hash_key: string
  hash_iv: string
  channel_id: string
  channel_secret: string
  is_enabled: boolean
  is_sandbox: boolean
}>({
  driver: 'ecpay',
  merchant_id: '',
  hash_key: '',
  hash_iv: '',
  channel_id: '',
  channel_secret: '',
  is_enabled: true,
  is_sandbox: true,
})
const paymentColumns = [
  { title: '驅動程式', dataIndex: 'driver', key: 'driver' },
  { title: '商編', dataIndex: 'merchant_id', key: 'merchant_id' },
  { title: '啟用狀態', key: 'is_enabled' },
  { title: '環境', key: 'sandbox' },
  { title: '操作', key: 'actions', width: 180 },
]

async function loadPayments() {
  paymentLoading.value = true
  try {
    const { data } = await tenantApi.listPaymentSettings()
    paymentRows.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '無法載入付款設定')
  } finally {
    paymentLoading.value = false
  }
}

function newPayment() {
  paymentEditingExisting.value = false
  paymentForm.value = {
    driver: 'ecpay',
    merchant_id: '',
    hash_key: '',
    hash_iv: '',
    channel_id: '',
    channel_secret: '',
    is_enabled: true,
    is_sandbox: true,
  }
  paymentModalOpen.value = true
}

function editPayment(rec: tenantApi.TenantPaymentSettingRead) {
  paymentEditingExisting.value = true
  paymentForm.value = {
    driver: rec.driver as any,
    merchant_id: rec.merchant_id || '',
    hash_key: '',
    hash_iv: '',
    channel_id: '',
    channel_secret: '',
    is_enabled: rec.is_enabled,
    is_sandbox: rec.is_sandbox,
  }
  paymentModalOpen.value = true
}

async function savePayment() {
  paymentSaving.value = true
  try {
    const payload: tenantApi.TenantPaymentSettingUpsert = {
      driver: paymentForm.value.driver,
      is_enabled: paymentForm.value.is_enabled,
      is_sandbox: paymentForm.value.is_sandbox,
      merchant_id: paymentForm.value.merchant_id || null,
    }
    if (paymentForm.value.hash_key) payload.hash_key = paymentForm.value.hash_key
    if (paymentForm.value.hash_iv) payload.hash_iv = paymentForm.value.hash_iv
    if (paymentForm.value.channel_id) payload.channel_id = paymentForm.value.channel_id
    if (paymentForm.value.channel_secret) payload.channel_secret = paymentForm.value.channel_secret
    await tenantApi.upsertPaymentSetting(payload)
    message.success('已儲存')
    paymentModalOpen.value = false
    await loadPayments()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '儲存失敗')
  } finally {
    paymentSaving.value = false
  }
}

async function removePayment(driver: string) {
  try {
    await tenantApi.deletePaymentSetting(driver)
    message.success('已刪除')
    await loadPayments()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '刪除失敗')
  }
}

// ----- Invoices -----
const invoiceRows = ref<tenantApi.TenantInvoiceSettingRead[]>([])
const invoiceLoading = ref(false)
const invoiceModalOpen = ref(false)
const invoiceSaving = ref(false)
const invoiceEditingExisting = ref(false)
const invoiceForm = ref<{
  driver: 'ecpay' | 'ezpay'
  merchant_id: string
  hash_key: string
  hash_iv: string
  company_tax_id: string
  is_enabled: boolean
  is_sandbox: boolean
}>({
  driver: 'ecpay',
  merchant_id: '',
  hash_key: '',
  hash_iv: '',
  company_tax_id: '',
  is_enabled: true,
  is_sandbox: true,
})
const invoiceColumns = [
  { title: '驅動程式', dataIndex: 'driver', key: 'driver' },
  { title: '商編', dataIndex: 'merchant_id', key: 'merchant_id' },
  { title: '本店統編', dataIndex: 'company_tax_id', key: 'company_tax_id' },
  { title: '啟用狀態', key: 'is_enabled' },
  { title: '環境', key: 'sandbox' },
  { title: '操作', key: 'actions', width: 120 },
]

async function loadInvoices() {
  invoiceLoading.value = true
  try {
    const { data } = await tenantApi.listInvoiceSettings()
    invoiceRows.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '無法載入發票設定')
  } finally {
    invoiceLoading.value = false
  }
}

function newInvoice() {
  invoiceEditingExisting.value = false
  invoiceForm.value = {
    driver: 'ecpay',
    merchant_id: '',
    hash_key: '',
    hash_iv: '',
    company_tax_id: '',
    is_enabled: true,
    is_sandbox: true,
  }
  invoiceModalOpen.value = true
}

function editInvoice(rec: tenantApi.TenantInvoiceSettingRead) {
  invoiceEditingExisting.value = true
  invoiceForm.value = {
    driver: rec.driver as any,
    merchant_id: rec.merchant_id || '',
    hash_key: '',
    hash_iv: '',
    company_tax_id: rec.company_tax_id || '',
    is_enabled: rec.is_enabled,
    is_sandbox: rec.is_sandbox,
  }
  invoiceModalOpen.value = true
}

async function saveInvoice() {
  invoiceSaving.value = true
  try {
    const payload: tenantApi.TenantInvoiceSettingUpsert = {
      driver: invoiceForm.value.driver,
      is_enabled: invoiceForm.value.is_enabled,
      is_sandbox: invoiceForm.value.is_sandbox,
      merchant_id: invoiceForm.value.merchant_id || null,
      company_tax_id: invoiceForm.value.company_tax_id || null,
    }
    if (invoiceForm.value.hash_key) payload.hash_key = invoiceForm.value.hash_key
    if (invoiceForm.value.hash_iv) payload.hash_iv = invoiceForm.value.hash_iv
    await tenantApi.upsertInvoiceSetting(payload)
    message.success('已儲存')
    invoiceModalOpen.value = false
    await loadInvoices()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '儲存失敗')
  } finally {
    invoiceSaving.value = false
  }
}

// ----- Subscription / usage -----
const plan = ref<SubscriptionPlanRead | null>(null)
const usage = ref<tenantApi.UsageCounterRead[]>([])
const usageLoading = ref(false)

async function loadSubscription() {
  usageLoading.value = true
  try {
    const [planRes, usageRes] = await Promise.all([
      tenantApi.getMyPlan(),
      tenantApi.getMyUsage(),
    ])
    plan.value = planRes.data
    usage.value = usageRes.data
  } catch { /* swallow — might just be no plan yet */ }
  finally { usageLoading.value = false }
}

// ----- Audit logs -----
const auditRows = ref<tenantApi.AuditLogRead[]>([])
const auditLoading = ref(false)
const auditColumns = [
  { title: '時間', key: 'created_at', width: 180 },
  { title: '使用者', dataIndex: 'user_id', key: 'user_id' },
  { title: '行為', dataIndex: 'action', key: 'action' },
  { title: '資源類型', dataIndex: 'resource_type', key: 'resource_type' },
  { title: '資源 ID', dataIndex: 'resource_id', key: 'resource_id' },
  { title: 'IP', dataIndex: 'ip', key: 'ip' },
  { title: '備註', key: 'extra' },
]

async function loadAudit() {
  auditLoading.value = true
  try {
    const { data } = await tenantApi.listAuditLogs({ limit: 200 })
    auditRows.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '無法載入稽核紀錄')
  } finally {
    auditLoading.value = false
  }
}

onMounted(async () => {
  await Promise.all([loadPayments(), loadInvoices(), loadSubscription(), loadAudit()])
})
</script>
