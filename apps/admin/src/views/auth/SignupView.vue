<template>
  <div class="signup-wrapper">
    <a-card class="signup-card">
      <template #title>
        <div class="card-title">
          <ShopOutlined style="margin-right: 8px" />
          點餐趣｜店家申請開通
        </div>
      </template>

      <a-steps :current="step" size="small" style="margin-bottom: 24px">
        <a-step title="填寫資料" />
        <a-step title="信箱驗證" />
        <a-step title="等待審核" />
      </a-steps>

      <!-- Step 0: application form -->
      <template v-if="step === 0">
        <a-alert
          message="送出後，我們會寄送 6 碼驗證碼到您的聯絡信箱。完成驗證後，平台超管會在 1～2 個工作天內審核您的申請。"
          type="info"
          show-icon
          style="margin-bottom: 16px"
        />
        <a-form :model="form" layout="vertical" @finish="submit">
          <a-form-item label="公司／品牌名稱" name="company_name" :rules="[{ required: true }]">
            <a-input v-model:value="form.company_name" placeholder="例：示範餐飲股份有限公司" />
          </a-form-item>
          <a-form-item label="聯絡人" name="contact_name" :rules="[{ required: true }]">
            <a-input v-model:value="form.contact_name" />
          </a-form-item>
          <a-form-item
            label="聯絡信箱"
            name="contact_email"
            :rules="[{ required: true, type: 'email' }]"
          >
            <a-input v-model:value="form.contact_email" placeholder="您將透過此信箱收到驗證碼" />
          </a-form-item>
          <a-form-item label="聯絡電話" name="contact_phone">
            <a-input v-model:value="form.contact_phone" />
          </a-form-item>
          <a-form-item label="統一編號" name="tax_id">
            <a-input v-model:value="form.tax_id" />
          </a-form-item>
          <a-form-item label="希望的租戶代號（subdomain）" name="proposed_subdomain">
            <a-input
              v-model:value="form.proposed_subdomain"
              placeholder="只能用英數字與連字號，例：demoshop"
            />
          </a-form-item>
          <a-form-item label="訂閱方案" name="plan_code">
            <a-select v-model:value="form.plan_code" placeholder="可選">
              <a-select-option value="">尚未決定</a-select-option>
              <a-select-option v-for="p in plans" :key="p.code" :value="p.code">
                {{ p.name }} ({{ p.price_cents > 0 ? `NT$${p.price_cents}` : '免費' }})
              </a-select-option>
            </a-select>
          </a-form-item>
          <a-form-item label="地址" name="address">
            <a-input v-model:value="form.address" />
          </a-form-item>
          <a-form-item label="備註" name="note">
            <a-textarea v-model:value="form.note" :rows="3" />
          </a-form-item>
          <a-button type="primary" html-type="submit" :loading="submitting" block size="large">
            送出申請
          </a-button>
        </a-form>
      </template>

      <!-- Step 1: OTP verification -->
      <template v-else-if="step === 1">
        <a-alert
          :message="`已寄送 6 碼驗證碼到 ${form.contact_email}，請於 15 分鐘內輸入。`"
          type="success"
          show-icon
          style="margin-bottom: 16px"
        />
        <a-form layout="vertical" @finish="verify">
          <a-form-item label="驗證碼" :rules="[{ required: true }]">
            <a-input
              v-model:value="otp"
              size="large"
              placeholder="請輸入 6 碼數字"
              :maxlength="6"
            />
          </a-form-item>
          <a-button type="primary" html-type="submit" :loading="verifying" block size="large">
            驗證並提交審核
          </a-button>
          <a-button type="link" block style="margin-top: 8px" @click="step = 0">
            返回修改資料
          </a-button>
        </a-form>
      </template>

      <!-- Step 2: pending review -->
      <template v-else>
        <a-result
          status="success"
          title="您的申請已提交"
          :sub-title="`申請編號：${applicationId}`"
        >
          <template #extra>
            <a-typography-paragraph>
              我們已收到您的申請，並已通知平台管理員審核。<br />
              審核通過後，您的「<b>租戶代號</b>」與「<b>一次性密碼</b>」會寄到 <b>{{ form.contact_email }}</b>。<br />
              首次登入後請立即修改密碼。
            </a-typography-paragraph>
            <a-button type="primary" @click="goLogin">前往登入頁</a-button>
          </template>
        </a-result>
      </template>
    </a-card>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { ShopOutlined } from '@ant-design/icons-vue'
import * as authApi from '@/api/auth'
import type { SubscriptionPlanRead } from '@/types'

const router = useRouter()
const step = ref(0)
const submitting = ref(false)
const verifying = ref(false)
const applicationId = ref('')
const otp = ref('')
const plans = ref<SubscriptionPlanRead[]>([])

const form = reactive({
  company_name: '',
  contact_name: '',
  contact_email: '',
  contact_phone: '',
  tax_id: '',
  plan_code: '',
  proposed_subdomain: '',
  address: '',
  note: '',
})

async function loadPlans() {
  try {
    const { data } = await authApi.publicListPlans()
    plans.value = data
  } catch { /* not fatal — plans are optional */ }
}

async function submit() {
  submitting.value = true
  try {
    const payload = { ...form }
    // strip empty optional strings so the backend treats them as null
    ;(['contact_phone', 'tax_id', 'plan_code', 'proposed_subdomain', 'address', 'note'] as const)
      .forEach((k) => { if (!payload[k]) (payload as any)[k] = undefined })
    const { data } = await authApi.applyForTenant(payload as any)
    applicationId.value = data.application_id
    message.success('已寄送驗證碼到您的信箱')
    step.value = 1
  } catch (e: any) {
    message.error(e.response?.data?.detail || '送出失敗，請稍後再試')
  } finally {
    submitting.value = false
  }
}

async function verify() {
  if (!/^\d{6}$/.test(otp.value)) {
    message.warning('驗證碼為 6 碼數字')
    return
  }
  verifying.value = true
  try {
    await authApi.verifyApplication(applicationId.value, otp.value)
    message.success('信箱驗證成功，已送至審核佇列')
    step.value = 2
  } catch (e: any) {
    message.error(e.response?.data?.detail || '驗證碼無效或已過期')
  } finally {
    verifying.value = false
  }
}

function goLogin() {
  router.push({ name: 'login' })
}

onMounted(loadPlans)
</script>

<style scoped>
.signup-wrapper {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 24px 0;
}
.signup-card {
  width: 560px;
  max-width: 95vw;
  border-radius: 12px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.18);
}
.card-title {
  display: flex;
  align-items: center;
  font-size: 18px;
}
</style>
