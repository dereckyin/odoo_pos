<template>
  <EntrySimulator />
  <div v-if="session.loadError" class="error-banner">{{ session.loadError }}</div>
  <div class="app">
    <RouterView />
  </div>
</template>

<script setup lang="ts">
import { watch } from 'vue'
import { useRoute } from 'vue-router'
import EntrySimulator from '@/components/EntrySimulator.vue'
import { parseEntryFromSearch } from '@/entry'
import { useSessionStore } from '@/stores/session'

const session = useSessionStore()
const route = useRoute()

watch(
  () => ({
    store: route.query.store,
    mode: route.query.mode,
    table: route.query.table,
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
    if (!session.menu || prevSlug !== session.storeSlug) {
      await session.loadMenu()
    }
  },
  { immediate: true },
)
</script>
