<template>
  <a-modal
    v-model:open="visible"
    title="選擇要代管的商家"
    ok-text="進入商家後台"
    cancel-text="取消"
    :confirm-loading="loading"
    @ok="confirm"
  >
    <a-input
      v-model:value="query"
      placeholder="搜尋商家名稱或代號…"
      allow-clear
      style="margin-bottom: 12px"
      @pressEnter="load"
    />
    <a-spin :spinning="loading">
      <a-list
        :data-source="filtered"
        :locale="{ emptyText: '找不到商家' }"
        size="small"
        style="max-height: 320px; overflow-y: auto"
      >
        <template #renderItem="{ item }">
          <a-list-item
            class="tenant-row"
            :class="{ selected: selectedId === item.id }"
            @click="selectedId = item.id"
          >
            <a-list-item-meta :title="item.name" :description="`代號：${item.code} · ${item.status}`" />
          </a-list-item>
        </template>
      </a-list>
    </a-spin>
  </a-modal>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { listTenants } from '@/api/platform'
import { useAuthStore } from '@/stores/auth'
import type { TenantRead } from '@/types'

const props = defineProps<{ open: boolean }>()
const emit = defineEmits<{ 'update:open': [boolean] }>()

const router = useRouter()
const auth = useAuthStore()
const loading = ref(false)
const query = ref('')
const tenants = ref<TenantRead[]>([])
const selectedId = ref('')

const visible = computed({
  get: () => props.open,
  set: (v: boolean) => emit('update:open', v),
})

const filtered = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return tenants.value
  return tenants.value.filter(
    (t) => t.name.toLowerCase().includes(q) || t.code.toLowerCase().includes(q),
  )
})

async function load() {
  loading.value = true
  try {
    const { data } = await listTenants()
    tenants.value = data.filter((t) => t.status !== 'closed')
  } catch {
    message.error('載入租戶列表失敗')
  } finally {
    loading.value = false
  }
}

function confirm() {
  const tenant = tenants.value.find((t) => t.id === selectedId.value)
  if (!tenant) {
    message.warning('請選擇商家')
    return
  }
  auth.enterTenantMode({ id: tenant.id, name: tenant.name })
  visible.value = false
  router.push({ name: 'dashboard' })
}

watch(
  () => props.open,
  (open) => {
    if (open) {
      selectedId.value = auth.actingTenantId || ''
      void load()
    }
  },
)
</script>

<style scoped>
.tenant-row {
  cursor: pointer;
  border-radius: 6px;
  padding-inline: 8px !important;
}
.tenant-row.selected {
  background: #f0f5ff;
}
</style>
