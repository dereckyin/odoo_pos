<template>
  <EntrySimulator />
  <div v-if="session.loadError && !session.needsStorePick" class="error-banner">
    {{ session.loadError }}
    <button type="button" class="retry-inline" @click="session.loadMenu()">重試</button>
  </div>
  <div class="app">
    <RouterView />
  </div>
</template>

<script setup lang="ts">
import { watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import EntrySimulator from '@/components/EntrySimulator.vue'
import { parseEntryFromSearch } from '@/entry'
import { useSessionStore } from '@/stores/session'

const session = useSessionStore()
const route = useRoute()
const router = useRouter()

watch(
  () => ({
    store: route.query.store,
    mode: route.query.mode,
    table: route.query.table,
    path: route.path,
  }),
  async (q) => {
    const prevSlug = session.storeSlug
    const search = new URLSearchParams()
    if (typeof q.store === 'string') search.set('store', q.store)
    if (typeof q.mode === 'string') search.set('mode', q.mode)
    if (typeof q.table === 'string') search.set('table', q.table)
    const parsed = parseEntryFromSearch(search.toString())
    session.storeSlug = parsed.store
    session.mode = parsed.mode
    session.table = parsed.table
    session.lockedDineIn = parsed.lockedDineIn

    // No store → stay on / as picker (MenuView will render picker when no slug).
    if (!parsed.store) {
      session.menu = null
      session.loadError = ''
      session.loading = false
      if (q.path !== '/' && q.path !== '/picker') {
        await router.replace({ path: '/', query: {} })
      }
      return
    }

    if (!session.menu || prevSlug !== session.storeSlug) {
      await session.loadMenu()
    }
  },
  { immediate: true },
)
</script>

<style scoped>
.error-banner {
  max-width: 480px;
  margin: 0 auto;
  background: #fff1f0;
  color: #b5342a;
  border-bottom: 1px solid #f0c2bd;
  padding: 10px 16px;
  font-size: 13px;
  display: flex;
  align-items: center;
  gap: 10px;
  justify-content: space-between;
}
.retry-inline {
  flex-shrink: 0;
  border: 1px solid #b5342a;
  background: #fff;
  color: #b5342a;
  border-radius: 5px;
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 700;
}
</style>
