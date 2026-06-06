<template>
  <div>
    <a-page-header title="租戶管理" sub-title="平台超管專用" :back-icon="false">
      <template #extra>
        <a-button type="primary" @click="openCreate">新增商家</a-button>
        <a-radio-group v-model:value="statusFilter" button-style="solid" @change="reload">
          <a-radio-button value="">全部</a-radio-button>
          <a-radio-button value="active">啟用</a-radio-button>
          <a-radio-button value="suspended">停權</a-radio-button>
          <a-radio-button value="cancelled">已取消</a-radio-button>
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
          <a-tag :color="statusColor(record.status)">{{ record.status }}</a-tag>
        </template>
        <template v-else-if="column.key === 'created_at'">
          {{ new Date(record.created_at).toLocaleString() }}
        </template>
        <template v-else-if="column.key === 'actions'">
          <a-space size="small">
            <a-button size="small" @click="openEdit(record)">編輯</a-button>
            <a-button
              v-if="record.status === 'active'"
              size="small"
              danger
              @click="quickStatus(record, 'suspended')"
            >
              停權
            </a-button>
            <a-button
              v-else-if="record.status === 'suspended'"
              size="small"
              type="primary"
              @click="quickStatus(record, 'active')"
            >
              恢復
            </a-button>
          </a-space>
        </template>
      </template>
    </a-table>

    <a-modal
      v-model:open="editVisible"
      title="編輯租戶"
      :confirm-loading="editLoading"
      @ok="submitEdit"
    >
      <a-form v-if="current" :model="editForm" layout="vertical">
        <a-form-item label="名稱">
          <a-input v-model:value="editForm.name" />
        </a-form-item>
        <a-form-item label="聯絡信箱">
          <a-input v-model:value="editForm.contact_email" />
        </a-form-item>
        <a-form-item label="聯絡電話">
          <a-input v-model:value="editForm.contact_phone" />
        </a-form-item>
        <a-form-item label="狀態">
          <a-select v-model:value="editForm.status">
            <a-select-option value="active">active</a-select-option>
            <a-select-option value="suspended">suspended</a-select-option>
            <a-select-option value="cancelled">cancelled</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="方案代號">
          <a-input v-model:value="editForm.plan_code" placeholder="例：starter" />
        </a-form-item>
        <a-divider>功能模組</a-divider>
        <a-form-item label="桌邊點餐">
          <a-switch
            v-model:checked="editForm.online_ordering"
            checked-children="啟用"
            un-checked-children="停用"
          />
          <div class="field-hint">桌邊 QR 點餐、桌位管理、桌邊訂單</div>
        </a-form-item>
        <a-form-item label="市集上架">
          <a-switch
            v-model:checked="editForm.marketplace"
            checked-children="啟用"
            un-checked-children="停用"
          />
          <div class="field-hint">市集設定、網路點餐與外送訂單</div>
        </a-form-item>
        <a-form-item label="商業智慧">
          <a-switch
            v-model:checked="editForm.business_intelligence"
            checked-children="啟用"
            un-checked-children="停用"
          />
          <div class="field-hint">銷售分析、門店績效、環境洞察、會員分析</div>
        </a-form-item>
        <a-form-item label="寄賣書籍">
          <a-switch
            v-model:checked="editForm.consignment_books"
            checked-children="啟用"
            un-checked-children="停用"
          />
          <div class="field-hint">餐飲門店寄賣二手書、分帳結算</div>
        </a-form-item>
      </a-form>
    </a-modal>

    <a-modal
      v-model:open="createVisible"
      title="平台直接新增商家"
      :confirm-loading="createLoading"
      ok-text="建立商家"
      @ok="submitCreate"
    >
      <a-form :model="createForm" layout="vertical">
        <a-form-item label="公司／品牌名稱" required>
          <a-input v-model:value="createForm.company_name" />
        </a-form-item>
        <a-form-item label="聯絡人" required>
          <a-input v-model:value="createForm.contact_name" />
        </a-form-item>
        <a-form-item label="聯絡信箱" required>
          <a-input v-model:value="createForm.contact_email" />
        </a-form-item>
        <a-form-item label="聯絡電話">
          <a-input v-model:value="createForm.contact_phone" />
        </a-form-item>
        <a-form-item label="統編">
          <a-input v-model:value="createForm.tax_id" />
        </a-form-item>
        <a-form-item label="方案" required>
          <a-select v-model:value="createForm.plan_code">
            <a-select-option v-for="p in plans" :key="p.code" :value="p.code">
              {{ p.name }} ({{ p.code }})
            </a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="租戶代號 tenant_code" required>
          <a-input v-model:value="createForm.tenant_code" placeholder="例如：ohmygod" />
        </a-form-item>
        <a-form-item label="管理員帳號" required>
          <a-input v-model:value="createForm.owner_username" placeholder="例如：admin" />
        </a-form-item>
        <a-form-item label="地址">
          <a-input v-model:value="createForm.address" />
        </a-form-item>
        <a-form-item label="建立後自動初始化">
          <a-space direction="vertical">
            <a-checkbox v-model:checked="createForm.seed_default_products">自動塞入預設商品</a-checkbox>
            <a-checkbox v-model:checked="createForm.seed_default_promotions">自動塞入預設行銷方案</a-checkbox>
          </a-space>
        </a-form-item>
      </a-form>
    </a-modal>

    <a-modal v-model:open="createdVisible" title="商家已建立" :footer="null">
      <a-descriptions bordered size="small" :column="1">
        <a-descriptions-item label="租戶代號">{{ createdInfo.tenant_code }}</a-descriptions-item>
        <a-descriptions-item label="管理員帳號">{{ createdInfo.owner_username }}</a-descriptions-item>
        <a-descriptions-item label="一次性密碼">{{ createdInfo.one_time_password }}</a-descriptions-item>
      </a-descriptions>
      <a-alert
        type="warning"
        show-icon
        style="margin-top: 12px"
        message="請立即把一次性密碼交給商家，並提醒首次登入後修改密碼。"
      />
      <a-button type="primary" block style="margin-top: 12px" @click="copyLoginInfo">
        一鍵複製登入資訊
      </a-button>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import * as platformApi from '@/api/platform'
import type { TenantRead } from '@/types'
import type { SubscriptionPlanRead } from '@/types'

const rows = ref<TenantRead[]>([])
const loading = ref(false)
const statusFilter = ref<string>('')

const editVisible = ref(false)
const editLoading = ref(false)
const current = ref<TenantRead | null>(null)
const plans = ref<SubscriptionPlanRead[]>([])
const createVisible = ref(false)
const createLoading = ref(false)
const createdVisible = ref(false)
const createdInfo = ref({
  tenant_code: '',
  owner_username: '',
  one_time_password: '',
})
const editForm = ref<{
  name: string
  contact_email: string
  contact_phone: string
  status: string
  plan_code: string
  online_ordering: boolean
  marketplace: boolean
  business_intelligence: boolean
  consignment_books: boolean
}>({
  name: '',
  contact_email: '',
  contact_phone: '',
  status: '',
  plan_code: '',
  online_ordering: false,
  marketplace: false,
  business_intelligence: false,
  consignment_books: true,
})
const createForm = ref({
  company_name: '',
  contact_name: '',
  contact_email: '',
  contact_phone: '',
  tax_id: '',
  plan_code: 'starter',
  tenant_code: '',
  owner_username: 'admin',
  address: '',
  seed_default_products: true,
  seed_default_promotions: true,
})

const columns = [
  { title: '代號', dataIndex: 'code', key: 'code' },
  { title: '名稱', dataIndex: 'name', key: 'name' },
  { title: '聯絡信箱', dataIndex: 'contact_email', key: 'contact_email' },
  { title: '統編', dataIndex: 'tax_id', key: 'tax_id' },
  { title: '方案', dataIndex: 'plan_code', key: 'plan_code' },
  { title: '狀態', key: 'status' },
  { title: '建立時間', key: 'created_at' },
  { title: '操作', key: 'actions', width: 180 },
]

function statusColor(s: string) {
  return ({
    active: 'green',
    suspended: 'orange',
    cancelled: 'red',
    trial: 'blue',
  } as Record<string, string>)[s] || 'default'
}

async function reload() {
  loading.value = true
  try {
    const { data } = await platformApi.listTenants(statusFilter.value || undefined)
    rows.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '無法載入租戶列表')
  } finally {
    loading.value = false
  }
}

async function loadPlans() {
  try {
    const { data } = await platformApi.listPlans()
    plans.value = data
    if (!createForm.value.plan_code && data.length) {
      createForm.value.plan_code = data[0].code
    }
  } catch {
    // non-blocking
  }
}

function openCreate() {
  createVisible.value = true
}

function openEdit(rec: TenantRead) {
  current.value = rec
  editForm.value = {
    name: rec.name,
    contact_email: rec.contact_email,
    contact_phone: rec.contact_phone || '',
    status: rec.status,
    plan_code: rec.plan_code || '',
    online_ordering: false,
    marketplace: false,
    business_intelligence: false,
    consignment_books: true,
  }
  editVisible.value = true
  platformApi.getTenantModules(rec.id).then(({ data }) => {
    if (current.value?.id === rec.id) {
      editForm.value.online_ordering = data.online_ordering
      editForm.value.marketplace = data.marketplace
      editForm.value.business_intelligence = data.business_intelligence
      editForm.value.consignment_books = data.consignment_books
    }
  }).catch(() => {
    message.warning('無法載入模組設定，將使用預設值')
  })
}

async function submitEdit() {
  if (!current.value) return
  editLoading.value = true
  try {
    await platformApi.updateTenant(current.value.id, {
      name: editForm.value.name,
      contact_email: editForm.value.contact_email,
      contact_phone: editForm.value.contact_phone || null,
      status: editForm.value.status,
      plan_code: editForm.value.plan_code || null,
    })
    await platformApi.updateTenantModules(current.value.id, {
      online_ordering: editForm.value.online_ordering,
      marketplace: editForm.value.marketplace,
      business_intelligence: editForm.value.business_intelligence,
      consignment_books: editForm.value.consignment_books,
    })
    message.success('已更新')
    editVisible.value = false
    await reload()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '更新失敗')
  } finally {
    editLoading.value = false
  }
}

async function quickStatus(rec: TenantRead, s: string) {
  try {
    await platformApi.updateTenant(rec.id, { status: s })
    message.success(`已切換至 ${s}`)
    await reload()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '更新失敗')
  }
}

async function submitCreate() {
  if (!createForm.value.company_name || !createForm.value.contact_name || !createForm.value.contact_email) {
    message.warning('請填寫公司名稱、聯絡人、聯絡信箱')
    return
  }
  if (!createForm.value.plan_code || !createForm.value.tenant_code || !createForm.value.owner_username) {
    message.warning('請填寫方案、租戶代號、管理員帳號')
    return
  }
  createLoading.value = true
  try {
    const { data } = await platformApi.directCreateTenant({
      company_name: createForm.value.company_name.trim(),
      contact_name: createForm.value.contact_name.trim(),
      contact_email: createForm.value.contact_email.trim(),
      contact_phone: createForm.value.contact_phone.trim() || null,
      tax_id: createForm.value.tax_id.trim() || null,
      plan_code: createForm.value.plan_code,
      tenant_code: createForm.value.tenant_code.trim().toLowerCase(),
      owner_username: createForm.value.owner_username.trim(),
      address: createForm.value.address.trim() || null,
      seed_default_products: createForm.value.seed_default_products,
      seed_default_promotions: createForm.value.seed_default_promotions,
    })
    createdInfo.value = {
      tenant_code: data.tenant_code,
      owner_username: data.owner_username,
      one_time_password: data.one_time_password,
    }
    createVisible.value = false
    createdVisible.value = true
    message.success('商家已建立')
    await reload()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '建立失敗')
  } finally {
    createLoading.value = false
  }
}

async function copyLoginInfo() {
  const text = [
    `租戶代號: ${createdInfo.value.tenant_code}`,
    `管理員帳號: ${createdInfo.value.owner_username}`,
    `一次性密碼: ${createdInfo.value.one_time_password}`,
    '登入網址: https://pos.myvnc.com/login',
  ].join('\n')
  try {
    await navigator.clipboard.writeText(text)
    message.success('已複製登入資訊')
  } catch {
    message.error('複製失敗，請手動複製')
  }
}

onMounted(async () => {
  await Promise.all([reload(), loadPlans()])
})
</script>

<style scoped>
.field-hint {
  margin-top: 4px;
  font-size: 12px;
  color: rgba(0, 0, 0, 0.45);
}
</style>
