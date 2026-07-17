import type { ApiMenu } from '@/api'
import { resolveUploadPath } from '@/api'
import type { MenuCategory, MenuProduct, PublicOptionGroup, ShoppingMenu, StoreInfo } from '@/types'

const EN_HINTS: Record<string, string> = {
  招牌: 'SIGNATURE',
  推薦: 'SIGNATURE',
  麵: 'NOODLES',
  飯: 'RICE',
  餃: 'DUMPLINGS',
  小菜: 'SIDES',
  青菜: 'VEGGIES',
  湯: 'SOUP',
  炸: 'FRIED',
  甜: 'DESSERT',
  飲: 'DRINKS',
}

function guessEn(name: string): string {
  for (const [k, v] of Object.entries(EN_HINTS)) {
    if (name.includes(k)) return v
  }
  return 'MENU'
}

function guessIcon(name: string, cat: string): string {
  const t = `${name}${cat}`
  if (/飲|茶|豆漿|檸檬/.test(t)) return 'cup'
  if (/餃/.test(t)) return 'dumpling'
  if (/飯/.test(t)) return 'rice'
  if (/湯/.test(t)) return 'soup'
  if (/菜|蔬|海帶|花生/.test(t)) return 'veg'
  if (/甜|豆花|湯圓|愛玉/.test(t)) return 'dessert'
  return 'bowl'
}

export function adaptApiMenu(menu: ApiMenu): ShoppingMenu {
  const store: StoreInfo = {
    slug: menu.meta.slug,
    name: menu.meta.display_name || menu.meta.store_name,
    addr: menu.meta.store_address || '',
    deliveryOn: menu.meta.supports_delivery,
    deliveryFeeCents: menu.meta.delivery_fee_cents,
    deliveryMinCents: menu.meta.min_order_cents,
    supportsPickup: menu.meta.supports_pickup,
    supportsDelivery: menu.meta.supports_delivery,
    supportsDineIn: menu.meta.supports_dine_in,
    paymentCounter: menu.meta.payment_counter,
    paymentOnline: menu.meta.payment_online,
    isOpen: menu.meta.is_open,
    prepTimeMin: 15,
  }

  const sortedCats = [...menu.categories].sort((a, b) => a.sort_order - b.sort_order)
  const categories: MenuCategory[] = sortedCats.map((c) => ({
    id: c.id,
    name: c.name,
    en: guessEn(c.name),
    sortOrder: c.sort_order,
  }))

  const catName = new Map(categories.map((c) => [c.id, c.name]))

  const products: MenuProduct[] = menu.products.map((p) => {
    const categoryId = p.category_id || sortedCats[0]?.id || 'uncat'
    const categoryName = catName.get(categoryId) || '其他'
    const optionGroups: PublicOptionGroup[] = (p.option_groups || []).map((g) => ({
      ...g,
      choices: g.choices.map((c) => ({ ...c, soldout: false })),
    }))
    return {
      id: p.id,
      categoryId,
      categoryName,
      name: p.name,
      description: p.description,
      priceCents: p.price_cents,
      imageUrl: resolveUploadPath(p.image_url) || null,
      iconKey: guessIcon(p.name, categoryName),
      soldout: false,
      noDelivery: false,
      tags: [],
      optionGroups,
    }
  })

  // Ensure categories that only appear via products are listed
  const used = new Set(products.map((p) => p.categoryId))
  const finalCats = categories.filter((c) => used.has(c.id))
  if (!finalCats.length && products.length) {
    finalCats.push({ id: 'all', name: '全部', en: 'ALL', sortOrder: 0 })
    for (const p of products) {
      p.categoryId = 'all'
      p.categoryName = '全部'
    }
  }

  return { store, categories: finalCats, products, isDemo: false }
}
