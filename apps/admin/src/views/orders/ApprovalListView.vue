<template>
  <div>
    <a-page-header title="退貨 / 作廢審核" sub-title="店長以上可核可或駁回門市送出的退貨與作廢申請" />

    <a-tabs v-model:active-key="activeTab">
      <a-tab-pane key="refunds" tab="退貨審核">
        <a-space style="margin-bottom: 12px">
          <span>狀態</span>
          <a-select v-model:value="refundStatus" style="width: 140px" @change="fetchRefunds">
            <a-select-option value="pending">待審核</a-select-option>
            <a-select-option value="approved">已核可</a-select-option>
            <a-select-option value="rejected">已駁回</a-select-option>
            <a-select-option value="">全部</a-select-option>
          </a-select>
          <a-button @click="fetchRefunds">重新整理</a-button>
        </a-space>
        <a-table :columns="refundColumns" :data-source="refunds" :loading="loadingRefunds" row-key="id" size="middle">
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'amount'">
              {{ formatMoney(record.total_amount_cents) }}
            </template>
            <template v-else-if="column.key === 'status'">
              <a-tag :color="statusColor(record.status)">{{ statusLabel(record.status) }}</a-tag>
            </template>
            <template v-else-if="column.key === 'created_at'">
              {{ formatTime(record.created_at) }}
            </template>
            <template v-else-if="column.key === 'actions'">
              <a-space v-if="record.status === 'pending'">
                <a-popconfirm title="核可此退貨？將回補庫存與點數。" @confirm="doApproveRefund(record.id)">
                  <a-button size="small" type="primary">核可</a-button>
                </a-popconfirm>
                <a-button size="small" danger @click="openReject('refund', record.id)">駁回</a-button>
              </a-space>
              <span v-else style="color: rgba(0,0,0,0.35)">—</span>
            </template>
          </template>
        </a-table>
      </a-tab-pane>

      <a-tab-pane key="voids" tab="作廢審核">
        <a-space style="margin-bottom: 12px">
          <span>狀態</span>
          <a-select v-model:value="voidStatus" style="width: 140px" @change="fetchVoids">
            <a-select-option value="pending">待審核</a-select-option>
            <a-select-option value="approved">已核可</a-select-option>
            <a-select-option value="rejected">已駁回</a-select-option>
            <a-select-option value="">全部</a-select-option>
          </a-select>
          <a-button @click="fetchVoids">重新整理</a-button>
        </a-space>
        <a-table :columns="voidColumns" :data-source="voids" :loading="loadingVoids" row-key="id" size="middle">
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'amount'">
              {{ formatMoney(record.total_cents) }}
            </template>
            <template v-else-if="column.key === 'void_status'">
              <a-tag :color="statusColor(record.void_status)">{{ statusLabel(record.void_status) }}</a-tag>
            </template>
            <template v-else-if="column.key === 'created_at'">
              {{ formatTime(record.created_at) }}
            </template>
            <template v-else-if="column.key === 'actions'">
              <a-space v-if="record.void_status === 'pending'">
                <a-popconfirm title="核可此作廢？整筆訂單將回補庫存與點數。" @confirm="doApproveVoid(record.id)">
                  <a-button size="small" type="primary">核可</a-button>
                </a-popconfirm>
                <a-button size="small" danger @click="openReject('void', record.id)">駁回</a-button>
              </a-space>
              <span v-else style="color: rgba(0,0,0,0.35)">—</span>
            </template>
          </template>
        </a-table>
      </a-tab-pane>
    </a-tabs>

    <a-modal v-model:open="rejectOpen" title="駁回原因" @ok="doReject" :confirm-loading="rejecting">
      <a-textarea v-model:value="rejectReason" :rows="3" placeholder="請填寫駁回原因（選填）" />
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import {
  listRefundApprovals, approveRefund, rejectRefund,
  listVoidApprovals, approveVoid, rejectVoid,
  type RefundApprovalItem, type VoidApprovalItem,
} from '@/api/approvals'

const activeTab = ref('refunds')

const refunds = ref<RefundApprovalItem[]>([])
const loadingRefunds = ref(false)
const refundStatus = ref('pending')

const voids = ref<VoidApprovalItem[]>([])
const loadingVoids = ref(false)
const voidStatus = ref('pending')

const rejectOpen = ref(false)
const rejecting = ref(false)
const rejectReason = ref('')
const rejectTarget = ref<{ kind: 'refund' | 'void'; id: string } | null>(null)

const refundColumns = [
  { title: '訂單', dataIndex: 'order_no', key: 'order_no' },
  { title: '門店', dataIndex: 'store_name', key: 'store_name' },
  { title: '金額', key: 'amount', width: 120 },
  { title: '方式', dataIndex: 'method', key: 'method', width: 90 },
  { title: '原因', dataIndex: 'reason', key: 'reason' },
  { title: '經手人', dataIndex: 'user_name', key: 'user_name', width: 110 },
  { title: '狀態', key: 'status', width: 90 },
  { title: '時間', key: 'created_at', width: 160 },
  { title: '操作', key: 'actions', width: 130 },
]

const voidColumns = [
  { title: '訂單', dataIndex: 'order_no', key: 'order_no' },
  { title: '門店', dataIndex: 'store_name', key: 'store_name' },
  { title: '金額', key: 'amount', width: 120 },
  { title: '原因', dataIndex: 'void_reason', key: 'void_reason' },
  { title: '狀態', key: 'void_status', width: 90 },
  { title: '時間', key: 'created_at', width: 160 },
  { title: '操作', key: 'actions', width: 130 },
]

function formatMoney(cents: number) {
  return `NT$ ${(cents / 100).toLocaleString('zh-TW', { minimumFractionDigits: 0 })}`
}
function formatTime(s: string) {
  return s ? new Date(s).toLocaleString('zh-TW') : ''
}
function statusColor(s: string | null) {
  return s === 'approved' ? 'green' : s === 'rejected' ? 'red' : 'orange'
}
function statusLabel(s: string | null) {
  return s === 'approved' ? '已核可' : s === 'rejected' ? '已駁回' : s === 'pending' ? '待審核' : (s || '—')
}

async function fetchRefunds() {
  loadingRefunds.value = true
  try {
    const { data } = await listRefundApprovals(refundStatus.value || undefined)
    refunds.value = data
  } finally {
    loadingRefunds.value = false
  }
}

async function fetchVoids() {
  loadingVoids.value = true
  try {
    const { data } = await listVoidApprovals(voidStatus.value || undefined)
    voids.value = data
  } finally {
    loadingVoids.value = false
  }
}

async function doApproveRefund(id: string) {
  try {
    await approveRefund(id)
    message.success('已核可退貨')
    fetchRefunds()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  }
}

async function doApproveVoid(id: string) {
  try {
    await approveVoid(id)
    message.success('已核可作廢')
    fetchVoids()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  }
}

function openReject(kind: 'refund' | 'void', id: string) {
  rejectTarget.value = { kind, id }
  rejectReason.value = ''
  rejectOpen.value = true
}

async function doReject() {
  if (!rejectTarget.value) return
  rejecting.value = true
  try {
    if (rejectTarget.value.kind === 'refund') {
      await rejectRefund(rejectTarget.value.id, rejectReason.value || undefined)
    } else {
      await rejectVoid(rejectTarget.value.id, rejectReason.value || undefined)
    }
    message.success('已駁回')
    rejectOpen.value = false
    rejectTarget.value.kind === 'refund' ? fetchRefunds() : fetchVoids()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  } finally {
    rejecting.value = false
  }
}

onMounted(() => {
  fetchRefunds()
  fetchVoids()
})
</script>
