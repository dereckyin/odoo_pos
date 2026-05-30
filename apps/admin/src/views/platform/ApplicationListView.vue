<template>
  <div>
    <a-page-header title="店家申請審核" sub-title="平台超管專用" :back-icon="false">
      <template #extra>
        <a-radio-group v-model:value="statusFilter" button-style="solid" @change="reload">
          <a-radio-button value="">全部</a-radio-button>
          <a-radio-button value="pending">待驗證信箱</a-radio-button>
          <a-radio-button value="email_verified">已驗證待審核</a-radio-button>
          <a-radio-button value="provisioned">已開通</a-radio-button>
          <a-radio-button value="rejected">已拒絕</a-radio-button>
        </a-radio-group>
      </template>
    </a-page-header>

    <a-table
      :columns="columns"
      :data-source="rows"
      :loading="loading"
      row-key="id"
      :pagination="{ pageSize: 20 }"
      size="middle"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.key === 'status'">
          <a-tag :color="statusColor(record.status)">{{ statusLabel(record.status) }}</a-tag>
        </template>
        <template v-else-if="column.key === 'contact'">
          <div>{{ record.contact_name }}</div>
          <div class="muted">{{ record.contact_email }}</div>
          <div v-if="record.contact_phone" class="muted">{{ record.contact_phone }}</div>
        </template>
        <template v-else-if="column.key === 'verified'">
          <span v-if="record.email_verified_at">
            {{ formatTs(record.email_verified_at) }}
          </span>
          <a-tag v-else color="orange">未驗證</a-tag>
        </template>
        <template v-else-if="column.key === 'actions'">
          <a-space size="small">
            <a-button size="small" @click="openDetail(record)">詳細</a-button>
            <a-button
              v-if="record.status === 'email_verified'"
              size="small"
              type="primary"
              @click="openApprove(record)"
            >
              核准
            </a-button>
            <a-button
              v-if="record.status === 'email_verified' || record.status === 'pending'"
              size="small"
              danger
              @click="openReject(record)"
            >
              拒絕
            </a-button>
          </a-space>
        </template>
      </template>
    </a-table>

    <!-- Detail modal --------------------------------------------------- -->
    <a-modal v-model:open="detailVisible" title="申請詳細" :footer="null" width="640px">
      <template v-if="current">
        <a-descriptions :column="1" bordered size="small">
          <a-descriptions-item label="公司名稱">{{ current.company_name }}</a-descriptions-item>
          <a-descriptions-item label="申請編號">{{ current.id }}</a-descriptions-item>
          <a-descriptions-item label="聯絡人">
            {{ current.contact_name }} &lt;{{ current.contact_email }}&gt;
          </a-descriptions-item>
          <a-descriptions-item v-if="current.contact_phone" label="電話">
            {{ current.contact_phone }}
          </a-descriptions-item>
          <a-descriptions-item v-if="current.tax_id" label="統編">
            {{ current.tax_id }}
          </a-descriptions-item>
          <a-descriptions-item v-if="current.proposed_subdomain" label="希望的租戶代號">
            {{ current.proposed_subdomain }}
          </a-descriptions-item>
          <a-descriptions-item v-if="current.plan_code" label="申請方案">
            {{ current.plan_code }}
          </a-descriptions-item>
          <a-descriptions-item v-if="current.address" label="地址">
            {{ current.address }}
          </a-descriptions-item>
          <a-descriptions-item v-if="current.note" label="備註">
            {{ current.note }}
          </a-descriptions-item>
          <a-descriptions-item label="狀態">
            <a-tag :color="statusColor(current.status)">{{ statusLabel(current.status) }}</a-tag>
          </a-descriptions-item>
          <a-descriptions-item v-if="current.email_verified_at" label="驗證時間">
            {{ formatTs(current.email_verified_at) }}
          </a-descriptions-item>
          <a-descriptions-item v-if="current.reviewed_at" label="審核時間">
            {{ formatTs(current.reviewed_at) }}
          </a-descriptions-item>
          <a-descriptions-item v-if="current.reject_reason" label="拒絕原因">
            {{ current.reject_reason }}
          </a-descriptions-item>
          <a-descriptions-item v-if="current.provisioned_tenant_id" label="開通的 Tenant">
            {{ current.provisioned_tenant_id }}
          </a-descriptions-item>
        </a-descriptions>
      </template>
    </a-modal>

    <!-- Approve modal -------------------------------------------------- -->
    <a-modal
      v-model:open="approveVisible"
      title="核准申請並開通租戶"
      :confirm-loading="approveLoading"
      ok-text="核准開通"
      @ok="submitApprove"
    >
      <a-alert
        message="核准後系統會自動建立 Tenant、預設 Store (MAIN)、Owner 帳號，並寄送一次性密碼到聯絡信箱。"
        type="info"
        show-icon
        style="margin-bottom: 16px"
      />
      <a-form :model="approveForm" layout="vertical">
        <a-form-item label="租戶代號 (tenant_code)">
          <a-input
            v-model:value="approveForm.tenant_code"
            :placeholder="current?.proposed_subdomain || '系統會自動生成'"
          />
        </a-form-item>
        <a-form-item label="訂閱方案" :rules="[{ required: true }]">
          <a-select v-model:value="approveForm.plan_code" placeholder="請選擇方案">
            <a-select-option v-for="p in plans" :key="p.code" :value="p.code">
              {{ p.name }} — {{ p.code }} ({{ p.price_cents > 0 ? `NT$${p.price_cents}` : '免費' }})
            </a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="管理員帳號" :rules="[{ required: true }]">
          <a-input v-model:value="approveForm.owner_username" placeholder="例：admin" />
        </a-form-item>
      </a-form>
    </a-modal>

    <!-- Reject modal --------------------------------------------------- -->
    <a-modal
      v-model:open="rejectVisible"
      title="拒絕申請"
      :confirm-loading="rejectLoading"
      ok-text="拒絕並通知"
      ok-type="danger"
      @ok="submitReject"
    >
      <a-form layout="vertical">
        <a-form-item label="拒絕原因（會寄送給申請人）" :rules="[{ required: true }]">
          <a-textarea v-model:value="rejectReason" :rows="3" />
        </a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import * as platformApi from '@/api/platform'
import type { TenantApplicationRead, SubscriptionPlanRead } from '@/types'

const rows = ref<TenantApplicationRead[]>([])
const plans = ref<SubscriptionPlanRead[]>([])
const loading = ref(false)
const statusFilter = ref<string>('')
const current = ref<TenantApplicationRead | null>(null)

const detailVisible = ref(false)
const approveVisible = ref(false)
const approveLoading = ref(false)
const approveForm = ref<{ tenant_code: string; plan_code: string; owner_username: string }>({
  tenant_code: '',
  plan_code: '',
  owner_username: 'admin',
})

const rejectVisible = ref(false)
const rejectLoading = ref(false)
const rejectReason = ref('')

const columns = [
  { title: '公司', dataIndex: 'company_name', key: 'company_name' },
  { title: '聯絡人', key: 'contact' },
  { title: '統編', dataIndex: 'tax_id', key: 'tax_id' },
  { title: '方案', dataIndex: 'plan_code', key: 'plan_code' },
  { title: '信箱驗證', key: 'verified' },
  { title: '狀態', key: 'status' },
  { title: '操作', key: 'actions', width: 200 },
]

function statusLabel(s: string) {
  return ({
    pending: '待驗證',
    email_verified: '待審核',
    provisioned: '已開通',
    rejected: '已拒絕',
  } as Record<string, string>)[s] || s
}

function statusColor(s: string) {
  return ({
    pending: 'orange',
    email_verified: 'blue',
    provisioned: 'green',
    rejected: 'red',
  } as Record<string, string>)[s] || 'default'
}

function formatTs(epoch: number | null | undefined) {
  if (!epoch) return ''
  return new Date(epoch * 1000).toLocaleString()
}

async function reload() {
  loading.value = true
  try {
    const { data } = await platformApi.listApplications(statusFilter.value || undefined)
    rows.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '無法載入申請列表')
  } finally {
    loading.value = false
  }
}

async function loadPlans() {
  try {
    const { data } = await platformApi.listPlans()
    plans.value = data
  } catch { /* swallow — error already shown by list endpoint */ }
}

function openDetail(rec: TenantApplicationRead) {
  current.value = rec
  detailVisible.value = true
}

function openApprove(rec: TenantApplicationRead) {
  current.value = rec
  approveForm.value = {
    tenant_code: rec.proposed_subdomain || '',
    plan_code: rec.plan_code || (plans.value[0]?.code || ''),
    owner_username: 'admin',
  }
  approveVisible.value = true
}

function openReject(rec: TenantApplicationRead) {
  current.value = rec
  rejectReason.value = ''
  rejectVisible.value = true
}

async function submitApprove() {
  if (!current.value) return
  if (!approveForm.value.plan_code || !approveForm.value.owner_username) {
    message.warning('請填寫方案與管理員帳號')
    return
  }
  approveLoading.value = true
  try {
    const payload: platformApi.ApplicationApprovePayload = {
      plan_code: approveForm.value.plan_code,
      owner_username: approveForm.value.owner_username,
    }
    if (approveForm.value.tenant_code) {
      payload.tenant_code = approveForm.value.tenant_code
    }
    await platformApi.approveApplication(current.value.id, payload)
    message.success('已開通並寄送一次性密碼')
    approveVisible.value = false
    await reload()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '核准失敗')
  } finally {
    approveLoading.value = false
  }
}

async function submitReject() {
  if (!current.value) return
  if (!rejectReason.value.trim()) {
    message.warning('請填寫拒絕原因')
    return
  }
  rejectLoading.value = true
  try {
    await platformApi.rejectApplication(current.value.id, rejectReason.value.trim())
    message.success('已拒絕並通知申請人')
    rejectVisible.value = false
    await reload()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '拒絕失敗')
  } finally {
    rejectLoading.value = false
  }
}

onMounted(async () => {
  await Promise.all([reload(), loadPlans()])
})
</script>

<style scoped>
.muted { color: rgba(0, 0, 0, 0.5); font-size: 12px; }
</style>
