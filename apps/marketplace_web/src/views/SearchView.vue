<template>
  <div class="page">
    <header class="topbar">
      <button class="back" @click="$router.back()">‹</button>
      <span class="title">搜尋「{{ q }}」</span>
      <span class="spacer" />
    </header>

    <div v-if="loading" class="state-page">搜尋中…</div>
    <div v-else class="store-list" style="padding-top: 12px">
      <router-link
        v-for="hit in hits"
        :key="`${hit.store_slug}-${hit.product_id}`"
        :to="{ name: 'store', params: { slug: hit.store_slug } }"
        class="store-card"
      >
        <div class="store-body">
          <img v-if="hit.logo_url" :src="resolveUploadPath(hit.logo_url)" class="store-logo" alt="" />
          <div v-else class="store-logo-ph">{{ hit.store_name.charAt(0) }}</div>
          <div class="store-meta">
            <h2>{{ hit.product_name }}</h2>
            <p>{{ hit.store_name }} · ${{ Math.round(hit.price_cents) }}</p>
          </div>
        </div>
      </router-link>
      <p v-if="!hits.length" class="state-page">找不到相關餐點</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { searchProducts, resolveUploadPath } from '@/api'
import type { MarketplaceProductSearchHit } from '@/types'

const route = useRoute()
const q = ref(String(route.query.q || ''))
const hits = ref<MarketplaceProductSearchHit[]>([])
const loading = ref(false)

async function load() {
  if (!q.value.trim()) return
  loading.value = true
  try {
    const { data } = await searchProducts(q.value.trim())
    hits.value = data
  } finally {
    loading.value = false
  }
}

watch(() => route.query.q, (v) => {
  q.value = String(v || '')
  load()
})

onMounted(load)
</script>
