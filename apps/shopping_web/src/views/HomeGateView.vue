<template>
  <StorePickerView v-if="!session.storeSlug" />
  <div v-else-if="session.loadError && !session.menu" class="fail">
    <p>{{ session.loadError }}</p>
    <button type="button" class="retry" @click="session.loadMenu()">重新載入</button>
    <button type="button" class="back" @click="goPicker">回店家列表</button>
  </div>
  <MenuView v-else />
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import MenuView from '@/views/MenuView.vue'
import StorePickerView from '@/views/StorePickerView.vue'
import { useSessionStore } from '@/stores/session'

const session = useSessionStore()
const router = useRouter()

function goPicker() {
  session.storeSlug = ''
  session.menu = null
  session.loadError = ''
  router.replace({ path: '/', query: {} })
}
</script>

<style scoped>
.fail {
  padding: 48px 24px;
  text-align: center;
  color: var(--red);
  font-size: 14px;
  line-height: 1.7;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}
.retry,
.back {
  border-radius: 6px;
  padding: 8px 18px;
  font-weight: 700;
  font-size: 13px;
}
.retry {
  border: 1.5px solid var(--red);
  background: var(--card);
  color: var(--red);
}
.back {
  border: 1px solid var(--line);
  background: var(--card);
  color: var(--muted);
}
</style>
