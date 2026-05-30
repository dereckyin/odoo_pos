<template>
  <div>
    <a-page-header :title="`會員：${member?.name || ''}`" @back="$router.push({ name: 'members' })">
      <template #extra>
        <a-button @click="editOpen = true">編輯</a-button>
        <a-button type="primary" @click="pointsOpen = true">調整點數</a-button>
      </template>
    </a-page-header>

    <a-spin :spinning="loading">
      <a-descriptions bordered :column="2" v-if="member">
        <a-descriptions-item label="姓名">{{ member.name }}</a-descriptions-item>
        <a-descriptions-item label="電話">{{ member.phone }}</a-descriptions-item>
        <a-descriptions-item label="Email">{{ member.email || '-' }}</a-descriptions-item>
        <a-descriptions-item label="生日">{{ member.birthday || '-' }}</a-descriptions-item>
        <a-descriptions-item label="等級">{{ levelName }}</a-descriptions-item>
        <a-descriptions-item label="點數">{{ member.points }}</a-descriptions-item>
        <a-descriptions-item label="累計消費">{{ formatMoney(member.total_spent_cents) }}</a-descriptions-item>
        <a-descriptions-item label="QR">{{ member.qr_code || '-' }}</a-descriptions-item>
        <a-descriptions-item label="加入日期">{{ member.joined_at?.slice(0, 10) }}</a-descriptions-item>
        <a-descriptions-item label="最後消費">{{ member.last_visit_at?.slice(0, 10) || '-' }}</a-descriptions-item>
        <a-descriptions-item label="備註" :span="2">{{ member.note || '-' }}</a-descriptions-item>
      </a-descriptions>

      <a-divider>點數流水</a-divider>
      <a-table :columns="ptColumns" :data-source="points" row-key="id" size="small" :pagination="{ pageSize: 10 }" />

      <a-divider>訂單紀錄</a-divider>
      <a-table :columns="orderColumns" :data-source="orders" row-key="id" size="small" :pagination="false">
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'total'">{{ formatMoney(record.total_cents) }}</template>
          <template v-if="column.key === 'actions'">
            <a-button size="small" @click="$router.push({ name: 'order-detail', params: { id: record.id } })">查看</a-button>
          </template>
        </template>
      </a-table>

      <a-divider>優惠券</a-divider>
      <a-table :columns="couponColumns" :data-source="coupons" row-key="id" size="small" :pagination="false">
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'status'">
            <a-tag v-if="record.used_at" color="default">已使用</a-tag>
            <a-tag v-else-if="record.expires_at && new Date(record.expires_at) < new Date()" color="red">已過期</a-tag>
            <a-tag v-else color="green">可使用</a-tag>
          </template>
        </template>
      </a-table>
    </a-spin>

    <a-modal v-model:open="editOpen" title="編輯會員" @ok="saveEdit" :confirm-loading="saving">
      <a-form v-if="member" layout="vertical">
        <a-form-item label="姓名"><a-input v-model:value="editForm.name" /></a-form-item>
        <a-form-item label="Email"><a-input v-model:value="editForm.email" /></a-form-item>
        <a-form-item label="等級">
          <a-select v-model:value="editForm.level_id" allow-clear>
            <a-select-option v-for="l in levels" :key="l.id" :value="l.id">{{ l.name }}</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="備註"><a-textarea v-model:value="editForm.note" /></a-form-item>
      </a-form>
    </a-modal>

    <a-modal v-model:open="pointsOpen" title="調整點數" @ok="savePoints" :confirm-loading="saving">
      <a-form layout="vertical">
        <a-form-item label="增減點數（負數為扣除）">
          <a-input-number v-model:value="pointsDelta" style="width: 100%" />
        </a-form-item>
        <a-form-item label="原因"><a-input v-model:value="pointsReason" /></a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { message } from 'ant-design-vue'
import {
  getMember, updateMember, listCoupons, listMemberLevels,
  listPointTransactions, listMemberOrders, adjustPoints,
} from '@/api/members'
import { formatMoney } from '@/utils/formatMoney'
import type { MemberRead, CouponRead, MemberLevelRead, PointTransactionRead, OrderListItem } from '@/types'

const route = useRoute()
const member = ref<MemberRead | null>(null)
const coupons = ref<CouponRead[]>([])
const points = ref<PointTransactionRead[]>([])
const orders = ref<OrderListItem[]>([])
const levels = ref<MemberLevelRead[]>([])
const loading = ref(false)
const saving = ref(false)
const editOpen = ref(false)
const pointsOpen = ref(false)
const pointsDelta = ref(0)
const pointsReason = ref('手動調整')
const editForm = reactive({ name: '', email: null as string | null, level_id: null as string | null, note: null as string | null })

const levelName = computed(() => {
  if (!member.value?.level_id) return '-'
  return levels.value.find(l => l.id === member.value!.level_id)?.name || member.value.level_id
})

const ptColumns = [
  { title: '時間', dataIndex: 'created_at', customRender: ({ text }: { text: string }) => text?.slice(0, 19) },
  { title: '變動', dataIndex: 'delta' },
  { title: '原因', dataIndex: 'reason' },
]

const orderColumns = [
  { title: '時間', dataIndex: 'client_created_at', customRender: ({ text }: { text: string }) => text?.slice(0, 16) },
  { title: '金額', key: 'total' },
  { title: '狀態', dataIndex: 'status' },
  { title: '操作', key: 'actions', width: 80 },
]

const couponColumns = [
  { title: '代碼', dataIndex: 'code' },
  { title: '類型', dataIndex: 'type' },
  { title: '面額', dataIndex: 'value' },
  { title: '狀態', key: 'status' },
]

async function loadAll() {
  loading.value = true
  try {
    const id = route.params.id as string
    const [memberRes, couponRes, ptRes, orderRes, levelRes] = await Promise.all([
      getMember(id),
      listCoupons({ member_id: id }),
      listPointTransactions(id),
      listMemberOrders(id),
      listMemberLevels(),
    ])
    member.value = memberRes.data
    coupons.value = couponRes.data
    points.value = ptRes.data
    orders.value = orderRes.data.items
    levels.value = levelRes.data
    if (member.value) {
      editForm.name = member.value.name
      editForm.email = member.value.email
      editForm.level_id = member.value.level_id
      editForm.note = member.value.note
    }
  } finally {
    loading.value = false
  }
}

async function saveEdit() {
  if (!member.value) return
  saving.value = true
  try {
    await updateMember(member.value.id, { ...editForm })
    message.success('已更新')
    editOpen.value = false
    loadAll()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '更新失敗')
  } finally {
    saving.value = false
  }
}

async function savePoints() {
  if (!member.value || !pointsDelta.value) return
  saving.value = true
  try {
    await adjustPoints({ member_id: member.value.id, delta: pointsDelta.value, reason: pointsReason.value })
    message.success('已調整')
    pointsOpen.value = false
    loadAll()
  } catch (e: any) {
    message.error(e.response?.data?.detail || '調整失敗')
  } finally {
    saving.value = false
  }
}

onMounted(loadAll)
</script>
