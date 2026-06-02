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
        <a-divider>或</a-divider>
        <a-button block size="large" :loading="resuming" @click="resumeFromFormEmail">
          已有申請？繼續驗證信箱
        </a-button>
      </template>

      <!-- Step 1: OTP verification -->
      <template v-else-if="step === 1">
        <a-alert
          :message="verifyAlertMessage"
          type="success"
          show-icon
          style="margin-bottom: 16px"
        />
        <a-form :model="verifyForm" layout="vertical" @finish="verify">
          <a-form-item
            label="驗證碼"
            name="otp"
            :rules="[
              { required: true, message: '請輸入驗證碼' },
              { pattern: /^\d{6}$/, message: '驗證碼為 6 碼數字' },
            ]"
          >
            <a-input
              v-model:value="verifyForm.otp"
              size="large"
              placeholder="請輸入 6 碼數字"
              :maxlength="6"
              inputmode="numeric"
            />
          </a-form-item>
          <a-button type="primary" html-type="submit" :loading="verifying" block size="large">
            驗證並提交審核
          </a-button>
          <a-button
            type="default"
            block
            style="margin-top: 8px"
            :loading="resending"
            @click="resendOtp"
          >
            重新寄送驗證碼
          </a-button>
          <a-button type="link" block style="margin-top: 8px" @click="step = 0">
            返回（修改資料需重新申請）
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
import { reactive, ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { ShopOutlined } from '@ant-design/icons-vue'
import * as authApi from '@/api/auth'
import { formatApiError } from '@/api/formatApiError'
import type { SubscriptionPlanRead } from '@/types'

const SIGNUP_APP_KEY = 'pos_signup_application_id'
const SIGNUP_EMAIL_KEY = 'pos_signup_contact_email'

const router = useRouter()
const step = ref(0)
const submitting = ref(false)
const verifying = ref(false)
const resuming = ref(false)
const resending = ref(false)
const applicationId = ref(sessionStorage.getItem(SIGNUP_APP_KEY) || '')
const verifyForm = reactive({ otp: '' })
const plans = ref<SubscriptionPlanRead[]>([])

const form = reactive({
  company_name: '',
  contact_name: '',
  contact_email: sessionStorage.getItem(SIGNUP_EMAIL_KEY) || '',
  contact_phone: '',
  tax_id: '',
  plan_code: '',
  proposed_subdomain: '',
  address: '',
  note: '',
})

const verifyAlertMessage = computed(() => {
  const email = form.contact_email || '您的信箱'
  return `請輸入寄送到 ${email} 的 6 碼驗證碼（15 分鐘內有效）。若未收到信，可點「重新寄送驗證碼」。`
})

function persistSession(id: string, email: string) {
  applicationId.value = id
  form.contact_email = email
  sessionStorage.setItem(SIGNUP_APP_KEY, id)
  sessionStorage.setItem(SIGNUP_EMAIL_KEY, email)
}

function clearSession() {
  sessionStorage.removeItem(SIGNUP_APP_KEY)
  sessionStorage.removeItem(SIGNUP_EMAIL_KEY)
}

function applyResume(data: authApi.TenantApplyResumeResponse) {
  persistSession(data.application_id, data.contact_email)
  form.company_name = data.company_name
  if (data.status === 'email_verified') {
    clearSession()
    step.value = 2
    message.info(data.message)
    return
  }
  step.value = 1
  message.success(data.message)
}

function conflictDetail(e: unknown): Record<string, string> | null {
  const detail = (e as { response?: { data?: { detail?: unknown } } })?.response?.data?.detail
  if (detail && typeof detail === 'object' && !Array.isArray(detail)) {
    return detail as Record<string, string>
  }
  return null
}

async function loadPlans() {
  try {
    const { data } = await authApi.publicListPlans()
    plans.value = data
  } catch { /* optional */ }
}

async function restoreFromSession() {
  const id = sessionStorage.getItem(SIGNUP_APP_KEY)
  const email = sessionStorage.getItem(SIGNUP_EMAIL_KEY)
  if (email) form.contact_email = email
  if (!id) {
    if (email) {
      try {
        const { data } = await authApi.resumeApplication(email)
        applyResume(data)
      } catch {
        /* no saved application */
      }
    }
    return
  }
  try {
    const { data } = await authApi.getApplicationStatus(id)
    persistSession(data.id, data.contact_email)
    form.company_name = data.company_name
    if (data.status === 'email_verified') {
      step.value = 2
    } else if (data.status === 'pending') {
      step.value = 1
    } else {
      clearSession()
      step.value = 0
    }
  } catch {
    if (email) {
      try {
        const { data } = await authApi.resumeApplication(email)
        applyResume(data)
      } catch {
        clearSession()
      }
    }
  }
}

async function resumeFromFormEmail() {
  const email = form.contact_email.trim()
  if (!email || !email.includes('@')) {
    message.warning('請先填寫聯絡信箱')
    return
  }
  resuming.value = true
  try {
    const { data } = await authApi.resumeApplication(email)
    applyResume(data)
  } catch (e: unknown) {
    message.error(formatApiError(e) || '找不到待驗證的申請')
  } finally {
    resuming.value = false
  }
}

async function submit() {
  submitting.value = true
  try {
    const payload = { ...form }
    ;(['contact_phone', 'tax_id', 'plan_code', 'proposed_subdomain', 'address', 'note'] as const)
      .forEach((k) => { if (!payload[k]) (payload as Record<string, unknown>)[k] = undefined })
    const { data } = await authApi.applyForTenant(payload as Parameters<typeof authApi.applyForTenant>[0])
    persistSession(data.application_id, data.contact_email)
    message.success('已寄送驗證碼到您的信箱')
    step.value = 1
  } catch (e: unknown) {
    const detail = conflictDetail(e)
    if (detail?.application_id) {
      persistSession(detail.application_id, detail.contact_email || form.contact_email)
      if (detail.company_name) form.company_name = detail.company_name
      if (detail.status === 'email_verified') {
        step.value = 2
        message.info(detail.message || '申請已驗證，請等待審核')
      } else {
        step.value = 1
        message.warning(detail.message || '請繼續完成信箱驗證')
      }
      return
    }
    message.error(formatApiError(e) || '送出失敗，請稍後再試')
  } finally {
    submitting.value = false
  }
}

async function resendOtp() {
  if (!applicationId.value) {
    message.error('申請編號遺失，請點「已有申請？繼續驗證信箱」')
    return
  }
  resending.value = true
  try {
    await authApi.resendApplicationOtp(applicationId.value)
    message.success('已重新寄送驗證碼')
  } catch (e: unknown) {
    message.error(formatApiError(e) || '無法重新寄送')
  } finally {
    resending.value = false
  }
}

async function verify() {
  if (!applicationId.value) {
    message.error('申請編號遺失，請點「已有申請？繼續驗證信箱」')
    return
  }
  const code = verifyForm.otp.trim()
  if (!/^\d{6}$/.test(code)) {
    message.warning('驗證碼為 6 碼數字')
    return
  }
  verifying.value = true
  try {
    await authApi.verifyApplication(applicationId.value, code)
    clearSession()
    message.success('信箱驗證成功，已送至審核佇列')
    step.value = 2
  } catch (e: unknown) {
    message.error(formatApiError(e) || '驗證碼無效或已過期')
  } finally {
    verifying.value = false
  }
}

function goLogin() {
  router.push({ name: 'login' })
}

onMounted(async () => {
  await loadPlans()
  await restoreFromSession()
})
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
