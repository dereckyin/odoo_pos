<template>
  <router-link class="store-card" :to="{ name: 'store', params: { slug: store.slug } }">
    <div class="banner">
      <img v-if="bannerSrc" :src="bannerSrc" :alt="store.display_name" />
      <div v-else class="banner-ph">{{ store.display_name.charAt(0) }}</div>
      <button class="fav" :class="{ on: store.is_favorite }" @click.prevent.stop="emit('toggle-fav')">
        {{ store.is_favorite ? '♥' : '♡' }}
      </button>
      <span v-if="!store.is_open" class="closed">休息中</span>
      <img v-if="logoSrc" :src="logoSrc" class="logo" alt="" />
    </div>
    <div class="body">
      <div class="name">{{ store.display_name }}</div>
      <div class="meta">
        <span class="rating">★ {{ store.rating_avg ? store.rating_avg.toFixed(1) : '新店' }}</span>
        <span v-if="store.rating_count" class="rc">({{ store.rating_count }})</span>
        <span class="dot">·</span>
        <span class="price">{{ priceText }}</span>
        <span class="dot">·</span>
        <span>{{ store.prep_time_min }} 分</span>
        <template v-if="store.distance_km != null">
          <span class="dot">·</span>
          <span>{{ store.distance_km.toFixed(1) }} km</span>
        </template>
      </div>
      <div class="meta sub">
        <span v-if="store.supports_delivery">外送 ${{ store.delivery_fee_cents }}</span>
        <template v-if="store.min_order_cents">
          <span v-if="store.supports_delivery" class="dot">·</span>
          <span>低消 ${{ store.min_order_cents }}</span>
        </template>
      </div>
      <div v-if="store.cuisine_tags.length" class="tags">
        <span v-for="t in store.cuisine_tags.slice(0, 3)" :key="t" class="tag">{{ t }}</span>
      </div>
    </div>
  </router-link>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { resolveUploadPath } from '@/api'
import type { MarketplaceStoreSummary } from '@/types'

const props = defineProps<{ store: MarketplaceStoreSummary }>()
const emit = defineEmits<{ 'toggle-fav': [] }>()

const bannerSrc = computed(() => resolveUploadPath(props.store.banner_url))
const logoSrc = computed(() => resolveUploadPath(props.store.logo_url))
const priceText = computed(() => '$'.repeat(Math.min(3, Math.max(1, props.store.price_level || 2))))
</script>

<style scoped>
.store-card {
  display: block;
  background: var(--surface);
  border-radius: 8px;
  overflow: hidden;
  text-decoration: none;
  color: inherit;
  border: 1px solid var(--border);
  box-shadow: none;
  transition: border-color 0.15s;
}
.banner {
  position: relative;
  height: 96px;
  background: var(--accent-soft);
  border-bottom: 1px solid var(--border);
}
.banner img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.banner-ph {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent);
  font-size: 40px;
  font-weight: 700;
}
.fav {
  position: absolute;
  top: 8px;
  right: 8px;
  border: 1px solid var(--border);
  width: 32px;
  height: 32px;
  border-radius: 6px;
  background: var(--surface);
  color: var(--accent);
  font-size: 17px;
  line-height: 1;
}
.fav:not(.on) {
  color: var(--muted);
}
.closed {
  position: absolute;
  inset: 0;
  background: rgba(34, 32, 28, 0.45);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 700;
}
.logo {
  position: absolute;
  left: 12px;
  bottom: -16px;
  width: 44px;
  height: 44px;
  border-radius: 6px;
  object-fit: cover;
  border: 1px solid var(--border);
  background: var(--surface);
}
.body {
  padding: 20px 12px 12px;
}
.name {
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 0.03em;
  margin-bottom: 4px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.meta {
  font-size: 12px;
  color: var(--muted);
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}
.meta.sub {
  margin-top: 3px;
}
.rating {
  color: var(--amber);
  font-weight: 700;
}
.rc {
  color: var(--muted);
}
.price {
  color: var(--text);
  font-weight: 700;
}
.dot {
  color: var(--border);
}
.tags {
  margin-top: 8px;
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}
.tag {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.05em;
  background: transparent;
  color: var(--accent);
  border: 1px solid var(--accent);
  padding: 1px 6px;
  border-radius: 3px;
}
@media (min-width: 900px) {
  .store-card:hover {
    border-color: var(--accent);
  }
  .banner {
    height: 150px;
  }
}
</style>
