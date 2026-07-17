<template>
  <div v-if="!session.lockedDineIn && session.mode !== 'dinein'" class="modeswitch">
    <button
      type="button"
      :class="{ on: session.mode === 'takeout' }"
      @click="session.switchMode('takeout')"
    >
      <span class="ms-row"><span v-html="ii('bag', 16)" /> 外帶自取</span>
      <small>到店取餐</small>
    </button>
    <button
      v-if="session.store?.deliveryOn"
      type="button"
      :class="{ on: session.mode === 'delivery' }"
      @click="session.switchMode('delivery')"
    >
      <span class="ms-row"><span v-html="ii('moped', 16)" /> 外送</span>
      <small>店家配送 · 滿 {{ session.store.deliveryMinCents }} 起送</small>
    </button>
  </div>
</template>

<script setup lang="ts">
import { ii } from '@/icons'
import { useSessionStore } from '@/stores/session'

const session = useSessionStore()
</script>
