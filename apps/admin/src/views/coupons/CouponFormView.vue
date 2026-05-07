<template>
  <div>
    <a-page-header title="新增優惠券" @back="$router.push({ name: 'coupons' })" />

    <a-form :model="form" :label-col="{ span: 4 }" :wrapper-col="{ span: 12 }" @finish="handleSubmit">
      <a-form-item label="代碼" :rules="[{ required: true, message: '請輸入代碼' }]">
        <a-input v-model:value="form.code" />
      </a-form-item>

      <a-form-item label="類型" :rules="[{ required: true }]">
        <a-select v-model:value="form.type" style="width: 200px">
          <a-select-option value="percentage">百分比折扣</a-select-option>
          <a-select-option value="amount">固定金額</a-select-option>
          <a-select-option value="freeItem">免費商品</a-select-option>
        </a-select>
      </a-form-item>

      <a-form-item :label="form.type === 'percentage' ? '折扣 (%)' : '面額'">
        <a-input-number v-model:value="form.value" :min="0" style="width: 200px" />
      </a-form-item>

      <a-form-item label="最低消費 (元)">
        <a-input-number v-model:value="minSpendDisplay" :min="0" style="width: 200px" />
      </a-form-item>

      <a-form-item label="到期日">
        <a-date-picker v-model:value="expiresDate" />
      </a-form-item>

      <a-form-item label="綁定會員">
        <a-input v-model:value="form.member_id" placeholder="選填，留空不限" />
      </a-form-item>

      <a-form-item :wrapper-col="{ offset: 4 }">
        <a-space>
          <a-button type="primary" html-type="submit" :loading="submitting">建立</a-button>
          <a-button @click="$router.push({ name: 'coupons' })">取消</a-button>
        </a-space>
      </a-form-item>
    </a-form>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import dayjs, { type Dayjs } from 'dayjs'
import { createCoupon } from '@/api/members'

const router = useRouter()
const submitting = ref(false)
const expiresDate = ref<Dayjs | null>(null)
const minSpendDisplay = ref(0)

const form = reactive({
  code: '',
  type: 'amount',
  value: 0,
  member_id: null as string | null,
})

async function handleSubmit() {
  submitting.value = true
  try {
    await createCoupon({
      ...form,
      min_spend_cents: Math.round(minSpendDisplay.value * 100),
      expires_at: expiresDate.value?.toISOString() ?? undefined,
    })
    message.success('已建立')
    router.push({ name: 'coupons' })
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  } finally {
    submitting.value = false
  }
}
</script>
