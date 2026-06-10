<template>
  <div />
</template>

<script setup lang="ts">
import { onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

function redirect() {
  const q = String(route.query.q || '').trim()
  router.replace({ name: 'stores', query: q ? { q } : {} })
}

onMounted(redirect)
watch(() => route.query.q, redirect)
</script>
