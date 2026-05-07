<template>
  <div>
    <a-page-header :title="`會員：${member?.name || ''}`" @back="$router.push({ name: 'members' })" />

    <a-spin :spinning="loading">
      <a-descriptions bordered :column="2" v-if="member">
        <a-descriptions-item label="姓名">{{ member.name }}</a-descriptions-item>
        <a-descriptions-item label="電話">{{ member.phone }}</a-descriptions-item>
        <a-descriptions-item label="Email">{{ member.email || '-' }}</a-descriptions-item>
        <a-descriptions-item label="生日">{{ member.birthday || '-' }}</a-descriptions-item>
        <a-descriptions-item label="等級">{{ member.level_id || '-' }}</a-descriptions-item>
        <a-descriptions-item label="點數">{{ member.points }}</a-descriptions-item>
        <a-descriptions-item label="累計消費">${{ (member.total_spent_cents / 100).toFixed(0) }}</a-descriptions-item>
        <a-descriptions-item label="加入日期">{{ member.joined_at?.slice(0, 10) }}</a-descriptions-item>
        <a-descriptions-item label="最後消費">{{ member.last_visit_at?.slice(0, 10) || '-' }}</a-descriptions-item>
        <a-descriptions-item label="備註">{{ member.note || '-' }}</a-descriptions-item>
      </a-descriptions>

      <a-divider>優惠券</a-divider>
      <a-table :columns="couponColumns" :data-source="coupons" row-key="id" size="small" :pagination="false">
        <template #bodyCell="{ column, record }">
          <template v-if="column.key === 'status'">
            <a-tag v-if="record.used_at" color="default">已使用</a-tag>
            <a-tag v-else color="green">可使用</a-tag>
          </template>
        </template>
      </a-table>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { getMember, listCoupons } from '@/api/members'
import type { MemberRead, CouponRead } from '@/types'

const route = useRoute()
const member = ref<MemberRead | null>(null)
const coupons = ref<CouponRead[]>([])
const loading = ref(false)

const couponColumns = [
  { title: '代碼', dataIndex: 'code' },
  { title: '類型', dataIndex: 'type' },
  { title: '面額', dataIndex: 'value' },
  { title: '狀態', key: 'status' },
]

onMounted(async () => {
  loading.value = true
  try {
    const id = route.params.id as string
    const [memberRes, couponRes] = await Promise.all([
      getMember(id),
      listCoupons({ member_id: id }),
    ])
    member.value = memberRes.data
    coupons.value = couponRes.data
  } finally {
    loading.value = false
  }
})
</script>
