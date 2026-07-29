<template>
  <div v-if="visible" class="entrybar">
    <div class="t">入口模擬（正式版由掃碼／連結參數決定；示範請用 ?store=demo）</div>
    <div class="row">
      <button :class="{ on: session.lockedDineIn }" type="button" @click="enterDinein">
        掃桌上 QR<br />內用 · A5
      </button>
      <button :class="{ on: !session.lockedDineIn }" type="button" @click="enterTakeout">
        外帶／外送入口<br />（外帶 QR／Google／官網）
      </button>
      <button type="button" @click="enterDemo">
        示範菜單<br />食光麵舖
      </button>
    </div>
    <div class="url">▸ {{ urlHint }}</div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore } from '@/stores/session'

const session = useSessionStore()
const router = useRouter()

const visible = import.meta.env.VITE_SHOW_ENTRY_SIMULATOR !== '0'

const urlHint = computed(() => {
  const slug = session.storeSlug || '(請選店家)'
  if (session.lockedDineIn) {
    return `?store=${slug}&mode=dinein&table=${session.table || 'A5'}`
  }
  return session.storeSlug ? `?store=${slug}&mode=takeout` : '/ （店家列表）'
})

async function enterDinein() {
  if (!session.storeSlug) session.storeSlug = 'demo'
  session.simulateEntry('dinein')
  await router.replace({ path: '/', query: session.entryQuery() })
  await session.loadMenu()
}

async function enterTakeout() {
  if (!session.storeSlug) session.storeSlug = 'demo'
  session.simulateEntry('takeout')
  await router.replace({ path: '/', query: session.entryQuery() })
  await session.loadMenu()
}

async function enterDemo() {
  session.simulateEntry('takeout')
  await router.replace({ path: '/', query: { store: 'demo', mode: 'takeout' } })
  await session.loadMenu()
}
</script>
