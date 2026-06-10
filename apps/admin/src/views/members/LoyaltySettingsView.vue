<template>
  <div>
    <a-page-header title="忠誠度設定" />

    <a-spin :spinning="loading">
      <a-card title="基本設定" style="max-width: 640px">
        <a-form layout="vertical">
          <a-form-item label="啟用累點"><a-switch v-model:checked="form.earn_enabled" /></a-form-item>
          <a-form-item label="啟用兌點"><a-switch v-model:checked="form.redeem_enabled" /></a-form-item>
          <a-form-item label="自動升級"><a-switch v-model:checked="form.auto_level" /></a-form-item>
          <a-form-item label="每點折抵金額"><a-input-number v-model:value="form.point_value_cents" :min="1" /></a-form-item>
          <a-form-item label="單筆最高兌點比例 (%)"><a-input-number v-model:value="form.max_redeem_pct" :min="0" :max="100" /></a-form-item>
          <a-form-item label="點數有效天數"><a-input-number v-model:value="form.point_expiry_days" :min="0" /></a-form-item>
          <a-form-item label="生日禮點數">
            <a-input-number v-model:value="form.birthday_bonus_points" :min="0" />
            <div style="color: #888; font-size: 12px">會員生日當天自動贈送（每年一次，0 = 不贈送）。需排程每日執行維護工作。</div>
          </a-form-item>
          <a-button type="primary" :loading="saving" @click="saveSettings">儲存設定</a-button>
        </a-form>
      </a-card>

      <a-card title="累點規則" style="margin-top: 24px">
        <template #extra>
          <a-button type="primary" size="small" @click="openRule()">新增規則</a-button>
        </template>
        <a-table :columns="ruleColumns" :data-source="rules" row-key="id" size="small" :pagination="false">
          <template #bodyCell="{ column, record }">
            <template v-if="column.key === 'rate'">每 {{ record.spend_cents }} 元 → {{ record.points_awarded }} 點</template>
            <template v-if="column.key === 'active'">
              <a-tag :color="record.is_active ? 'green' : 'default'">{{ record.is_active ? '啟用' : '停用' }}</a-tag>
            </template>
            <template v-if="column.key === 'actions'">
              <a-space>
                <a-button size="small" @click="openRule(record)">編輯</a-button>
                <a-popconfirm title="刪除規則？" @confirm="deleteRule(record.id)">
                  <a-button size="small" danger>刪除</a-button>
                </a-popconfirm>
              </a-space>
            </template>
          </template>
        </a-table>
      </a-card>
    </a-spin>

    <a-modal v-model:open="ruleOpen" :title="ruleId ? '編輯規則' : '新增規則'" @ok="saveRule" :confirm-loading="saving">
      <a-form layout="vertical">
        <a-form-item label="名稱"><a-input v-model:value="ruleForm.name" /></a-form-item>
        <a-form-item label="消費門檻 (元)"><a-input-number v-model:value="ruleForm.spend_cents" :min="1" /></a-form-item>
        <a-form-item label="贈送點數"><a-input-number v-model:value="ruleForm.points_awarded" :min="1" /></a-form-item>
        <a-form-item label="啟用"><a-switch v-model:checked="ruleForm.is_active" /></a-form-item>
      </a-form>
    </a-modal>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { message } from 'ant-design-vue'
import {
  getLoyaltySettings, updateLoyaltySettings,
  listLoyaltyRules, createLoyaltyRule, updateLoyaltyRule, deleteLoyaltyRule,
} from '@/api/members'
import type { LoyaltyRuleRead, LoyaltySettings } from '@/types'

const loading = ref(false)
const saving = ref(false)
const form = reactive<LoyaltySettings>({
  earn_enabled: true,
  redeem_enabled: true,
  point_value_cents: 1,
  max_redeem_pct: 50,
  point_expiry_days: 365,
  auto_level: true,
  birthday_bonus_points: 0,
})
const rules = ref<LoyaltyRuleRead[]>([])
const ruleOpen = ref(false)
const ruleId = ref<string | null>(null)
const ruleForm = reactive({ name: '', spend_cents: 100, points_awarded: 1, is_active: true })

const ruleColumns = [
  { title: '名稱', dataIndex: 'name' },
  { title: '規則', key: 'rate' },
  { title: '狀態', key: 'active', width: 80 },
  { title: '操作', key: 'actions', width: 140 },
]

async function load() {
  loading.value = true
  try {
    const [s, r] = await Promise.all([getLoyaltySettings(), listLoyaltyRules()])
    Object.assign(form, s.data)
    rules.value = r.data
  } finally {
    loading.value = false
  }
}

async function saveSettings() {
  saving.value = true
  try {
    await updateLoyaltySettings(form)
    message.success('已儲存')
  } catch (e: any) {
    message.error(e.response?.data?.detail || '儲存失敗')
  } finally {
    saving.value = false
  }
}

function openRule(record?: LoyaltyRuleRead) {
  ruleId.value = record?.id ?? null
  ruleForm.name = record?.name ?? ''
  ruleForm.spend_cents = record?.spend_cents ?? 100
  ruleForm.points_awarded = record?.points_awarded ?? 1
  ruleForm.is_active = record?.is_active ?? true
  ruleOpen.value = true
}

async function saveRule() {
  saving.value = true
  try {
    if (ruleId.value) {
      await updateLoyaltyRule(ruleId.value, { ...ruleForm })
    } else {
      await createLoyaltyRule({ ...ruleForm })
    }
    message.success('已儲存')
    ruleOpen.value = false
    const { data } = await listLoyaltyRules()
    rules.value = data
  } catch (e: any) {
    message.error(e.response?.data?.detail || '儲存失敗')
  } finally {
    saving.value = false
  }
}

async function deleteRule(id: string) {
  await deleteLoyaltyRule(id)
  const { data } = await listLoyaltyRules()
  rules.value = data
}

onMounted(load)
</script>
