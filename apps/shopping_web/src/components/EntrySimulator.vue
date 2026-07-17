<template>
  <div v-if="visible" class="entrybar">
    <div class="t">入口模擬（正式版由掃碼／連結參數決定；demo 無 store 時用示菜單）</div>
    <div class="row">
      <button :class="{ on: session.lockedDineIn }" type="button" @click="enterDinein">
        掃桌上 QR<br />內用 · A5
      </button>
      <button :class="{ on: !session.lockedDineIn }" type="button" @click="enterTakeout">
        外帶／外送入口<br />（外帶 QR／Google／官網）
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
  const slug = session.storeSlug || 'demo'
  if (session.lockedDineIn) {
    return `?store=${slug}&mode=dinein&table=${session.table || 'A5'}`
  }
  return `?store=${slug}&mode=takeout`
})

async function enterDinein() {
  session.simulateEntry('dinein')
  await router.replace({ name: 'menu', query: session.entryQuery() })
}

async function enterTakeout() {
  session.simulateEntry('takeout')
  await router.replace({ name: 'menu', query: session.entryQuery() })
}
</script>
