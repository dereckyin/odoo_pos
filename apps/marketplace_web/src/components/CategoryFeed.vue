<template>
  <div class="category-feed">
    <section
      v-for="section in sections"
      :key="section.category_id"
      :ref="(el) => setSectionRef(section.category_id, el)"
      class="feed-section"
    >
      <h2 class="section-title">
        <span v-if="section.icon" class="icon">{{ section.icon }}</span>
        {{ section.category_name }}
      </h2>
      <div class="carousel">
        <ProductCard
          v-for="p in section.products"
          :key="`${p.store_slug}-${p.product_id}`"
          :card="p"
          compact
        />
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import ProductCard from '@/components/ProductCard.vue'
import type { MarketplaceProductFeedSection } from '@/types'

defineProps<{ sections: MarketplaceProductFeedSection[] }>()

const sectionRefs = new Map<string, HTMLElement>()

function setSectionRef(id: string, el: unknown) {
  const node = el instanceof HTMLElement ? el : null
  if (node) sectionRefs.set(id, node)
  else sectionRefs.delete(id)
}

function scrollToCategory(categoryId: string) {
  const el = sectionRefs.get(categoryId)
  if (el) {
    const top = el.getBoundingClientRect().top + window.scrollY - 108
    window.scrollTo({ top, behavior: 'smooth' })
  }
}

defineExpose({ scrollToCategory, sectionRefs })
</script>

<style scoped>
.feed-section {
  margin-bottom: 20px;
}
.section-title {
  margin: 0 0 10px 4px;
  font-size: 1.05rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 6px;
}
.icon {
  font-size: 1.1rem;
}
.carousel {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding-bottom: 4px;
  -webkit-overflow-scrolling: touch;
  scroll-snap-type: x mandatory;
}
.carousel :deep(.product-card) {
  flex: 0 0 160px;
  scroll-snap-align: start;
}
@media (min-width: 640px) {
  .carousel :deep(.product-card) {
    flex-basis: 180px;
  }
}
</style>
