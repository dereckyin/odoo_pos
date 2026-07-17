import type { MenuCategory, MenuProduct, PublicOptionGroup, ShoppingMenu, StoreInfo } from '@/types'

const store: StoreInfo = {
  slug: 'demo',
  name: '食光麵舖 · 民生店',
  addr: '台北市民生東路三段 107 巷',
  deliveryOn: true,
  deliveryFeeCents: 30,
  deliveryMinCents: 150,
  supportsPickup: true,
  supportsDelivery: true,
  supportsDineIn: true,
  paymentCounter: true,
  paymentOnline: true,
  isOpen: true,
  prepTimeMin: 15,
}

const CAT_META: Array<{ id: string; name: string; en: string }> = [
  { id: 'c1', name: '招牌推薦', en: 'SIGNATURE' },
  { id: 'c2', name: '麵食', en: 'NOODLES' },
  { id: 'c3', name: '飯食', en: 'RICE' },
  { id: 'c4', name: '水餃煎餃', en: 'DUMPLINGS' },
  { id: 'c5', name: '小菜', en: 'SIDES' },
  { id: 'c6', name: '燙青菜', en: 'VEGGIES' },
  { id: 'c7', name: '湯品', en: 'SOUP' },
  { id: 'c8', name: '炸物', en: 'FRIED' },
  { id: 'c9', name: '甜點', en: 'DESSERT' },
  { id: 'c10', name: '飲料', en: 'DRINKS' },
]

type RawOpt = [string, number, boolean?]
type RawGroup = { t: string; req: number; multi: number; max?: number; list: RawOpt[] }

function toGroups(key: string, groups: RawGroup[]): PublicOptionGroup[] {
  return groups.map((g, gi) => {
    let defaultIdx = -1
    if (g.req && !g.multi) {
      defaultIdx = g.list.findIndex((o) => o[1] === 0 && !o[2])
      if (defaultIdx < 0) defaultIdx = g.list.findIndex((o) => !o[2])
    }
    return {
      id: `${key}-g${gi}`,
      name: g.t,
      selection_type: g.multi ? ('multi' as const) : ('single' as const),
      is_required: !!g.req,
      min_selections: g.req ? 1 : 0,
      max_selections: g.multi ? g.max ?? null : 1,
      sort_order: gi,
      choices: g.list.map((o, oi) => ({
        id: `${key}-g${gi}-c${oi}`,
        name: o[0],
        price_delta_cents: o[1],
        is_default: oi === defaultIdx,
        soldout: !!o[2],
      })),
    }
  })
}

const OPTS: Record<string, PublicOptionGroup[]> = {
  noodle: toGroups('noodle', [
    { t: '份量', req: 1, multi: 0, list: [['小份', -20], ['中份', 0], ['大份', 30]] },
    { t: '麵條', req: 1, multi: 0, list: [['細麵', 0], ['粗麵', 0], ['寬麵', 0], ['冬粉', 0]] },
    { t: '辣度', req: 0, multi: 0, list: [['不辣', 0], ['小辣', 0], ['中辣', 0], ['大辣', 0]] },
    {
      t: '加點',
      req: 0,
      multi: 1,
      max: 4,
      list: [['加麵', 20], ['加牛肉', 60], ['加青菜', 15], ['加滷蛋', 15]],
    },
  ]),
  rice: toGroups('rice', [
    { t: '份量', req: 1, multi: 0, list: [['小碗', -10], ['正常', 0], ['大碗', 15]] },
    {
      t: '加點',
      req: 0,
      multi: 1,
      max: 3,
      list: [['加滷蛋', 15], ['加半熟蛋', 20], ['加青菜', 20], ['加肉燥', 25]],
    },
  ]),
  dumpling: toGroups('dumpling', [
    { t: '份量', req: 1, multi: 0, list: [['原份（10 顆）', 0], ['加量（15 顆）', 35]] },
    { t: '沾醬', req: 0, multi: 1, max: 3, list: [['醬油', 0], ['辣油', 0], ['烏醋', 0], ['蒜泥', 0]] },
  ]),
  fried: toGroups('fried', [
    { t: '份量', req: 1, multi: 0, list: [['小份', -15], ['中份', 0], ['大份', 25]] },
    { t: '辣度', req: 1, multi: 0, list: [['不辣', 0], ['小辣', 0], ['中辣', 0], ['大辣', 0]] },
    { t: '加點', req: 0, multi: 1, max: 2, list: [['加起司粉', 15], ['加梅粉', 10]] },
  ]),
  side: toGroups('side', [
    { t: '醬料', req: 0, multi: 0, list: [['原味', 0], ['醬油', 0], ['辣醬', 0]] },
  ]),
  drink: toGroups('drink', [
    { t: '容量', req: 1, multi: 0, list: [['中杯', 0], ['大杯', 10]] },
    {
      t: '甜度',
      req: 1,
      multi: 0,
      list: [['正常糖', 0], ['少糖', 0], ['半糖', 0], ['微糖', 0], ['無糖', 0]],
    },
    {
      t: '冰塊',
      req: 1,
      multi: 0,
      list: [['正常冰', 0], ['少冰', 0], ['微冰', 0], ['去冰', 0], ['熱飲', 0]],
    },
    {
      t: '加料',
      req: 0,
      multi: 1,
      max: 3,
      list: [['珍珠', 10], ['椰果', 10], ['仙草凍', 15], ['布丁', 15, true]],
    },
  ]),
}

type RawItem = {
  id: number
  cat: string
  ic: string
  n: string
  d: string
  p: number
  tags?: Array<'rec' | 'hot' | 'veg'>
  soldout?: boolean
  noDelivery?: boolean
  custom?: string
}

const RAW: RawItem[] = [
  { id: 1, cat: '招牌推薦', ic: 'bowl', n: '招牌牛肉麵', d: '燉煮 8 小時、半筋半肉', p: 180, tags: ['rec', 'hot'], custom: 'noodle' },
  { id: 2, cat: '招牌推薦', ic: 'bowl', n: '紅燒牛肉麵', d: '濃郁湯頭、大塊牛腱', p: 200, tags: ['hot'], custom: 'noodle' },
  { id: 3, cat: '招牌推薦', ic: 'bowl', n: '招牌乾拌麵', d: '招牌醬汁、彈牙麵條', p: 85, tags: ['rec'], custom: 'noodle' },
  { id: 4, cat: '招牌推薦', ic: 'rice', n: '古早味滷肉飯', d: '手切滷肉、油亮噴香', p: 45, tags: ['rec'], custom: 'rice' },
  { id: 5, cat: '麵食', ic: 'bowl', n: '麻醬乾麵', d: '濃香芝麻醬、附青菜', p: 75, custom: 'noodle' },
  { id: 6, cat: '麵食', ic: 'soup', n: '酸辣湯麵', d: '酸香開胃、料多實在', p: 85, custom: 'noodle' },
  { id: 7, cat: '麵食', ic: 'bowl', n: '榨菜肉絲麵', d: '家常好味、湯頭清爽', p: 90, custom: 'noodle' },
  { id: 8, cat: '麵食', ic: 'bowl', n: '陽春麵', d: '簡單純粹、蔥花提味', p: 55, custom: 'noodle' },
  { id: 9, cat: '麵食', ic: 'bowl', n: '麻辣牛筋麵', d: '麻辣過癮、牛筋軟Q', p: 210, tags: ['hot'], custom: 'noodle' },
  { id: 10, cat: '飯食', ic: 'rice', n: '雞肉飯', d: '嫩雞絲淋雞油', p: 55, tags: ['rec'], custom: 'rice' },
  { id: 11, cat: '飯食', ic: 'rice', n: '排骨飯', d: '酥炸排骨、附三樣配菜', p: 95, custom: 'rice' },
  { id: 12, cat: '飯食', ic: 'rice', n: '咖哩雞飯', d: '日式咖哩、微辣順口', p: 100, custom: 'rice' },
  { id: 13, cat: '飯食', ic: 'rice', n: '三寶飯', d: '叉燒・油雞・燒肉', p: 120, tags: ['hot'], custom: 'rice' },
  { id: 14, cat: '水餃煎餃', ic: 'dumpling', n: '手工鮮肉煎餃（8 顆）', d: '現包現煎、外酥內多汁', p: 90, tags: ['hot'], custom: 'dumpling' },
  { id: 15, cat: '水餃煎餃', ic: 'dumpling', n: '韭菜水餃（10 顆）', d: '皮薄餡多', p: 80, custom: 'dumpling' },
  { id: 16, cat: '水餃煎餃', ic: 'dumpling', n: '高麗菜水餃（10 顆）', d: '清甜爽口', p: 80, tags: ['veg'], custom: 'dumpling' },
  { id: 17, cat: '水餃煎餃', ic: 'dumpling', n: '玉米水餃（10 顆）', d: '小朋友最愛', p: 85, custom: 'dumpling' },
  { id: 18, cat: '小菜', ic: 'dessert', n: '滷味拼盤', d: '滷蛋・豆干・海帶', p: 60, custom: 'side' },
  { id: 19, cat: '小菜', ic: 'dessert', n: '招牌滷蛋', d: '', p: 15, custom: 'side' },
  { id: 20, cat: '小菜', ic: 'dessert', n: '滷豆干', d: '', p: 25, custom: 'side' },
  { id: 21, cat: '小菜', ic: 'veg', n: '涼拌海帶絲', d: '', p: 25, tags: ['veg'], custom: 'side' },
  { id: 22, cat: '小菜', ic: 'veg', n: '蒜味花生', d: '', p: 20, tags: ['veg'] },
  { id: 23, cat: '燙青菜', ic: 'veg', n: '燙青菜', d: '當季時蔬、附油蔥', p: 40, tags: ['veg'], custom: 'side' },
  { id: 24, cat: '燙青菜', ic: 'veg', n: '燙地瓜葉', d: '', p: 45, tags: ['veg'], custom: 'side' },
  { id: 25, cat: '燙青菜', ic: 'veg', n: '燙秋葵', d: '', p: 50, tags: ['veg'], custom: 'side' },
  { id: 26, cat: '湯品', ic: 'soup', n: '貢丸湯', d: '手打貢丸、清甜', p: 35, noDelivery: true },
  { id: 27, cat: '湯品', ic: 'soup', n: '紫菜蛋花湯', d: '', p: 30, soldout: true },
  { id: 28, cat: '湯品', ic: 'soup', n: '酸辣湯', d: '料多實在', p: 45, noDelivery: true },
  { id: 29, cat: '湯品', ic: 'soup', n: '味噌湯', d: '', p: 30, noDelivery: true },
  { id: 30, cat: '炸物', ic: 'dessert', n: '鹽酥雞', d: '現炸酥脆、九層塔香', p: 70, tags: ['hot'], custom: 'fried' },
  { id: 31, cat: '炸物', ic: 'dessert', n: '炸雞排', d: '大片多汁', p: 80, tags: ['hot'], custom: 'fried' },
  { id: 32, cat: '炸物', ic: 'dessert', n: '黃金薯條', d: '', p: 45, custom: 'fried' },
  { id: 33, cat: '炸物', ic: 'dessert', n: '炸花枝丸', d: '', p: 55, custom: 'fried' },
  { id: 34, cat: '甜點', ic: 'dessert', n: '紅豆湯圓', d: '綿密紅豆、手工湯圓', p: 45, noDelivery: true },
  { id: 35, cat: '甜點', ic: 'dessert', n: '傳統豆花', d: '綿滑豆花、多種配料', p: 40, noDelivery: true },
  { id: 36, cat: '甜點', ic: 'dessert', n: '愛玉檸檬', d: '', p: 40, soldout: true },
  { id: 37, cat: '飲料', ic: 'cup', n: '古早味紅茶', d: '回甘不澀', p: 25, custom: 'drink' },
  { id: 38, cat: '飲料', ic: 'cup', n: '冬瓜檸檬', d: '古法冬瓜露＋新鮮檸檬', p: 45, custom: 'drink' },
  { id: 39, cat: '飲料', ic: 'cup', n: '翠玉綠茶', d: '', p: 25, custom: 'drink' },
  { id: 40, cat: '飲料', ic: 'cup', n: '檸檬愛玉冰茶', d: '消暑首選', p: 50, tags: ['rec'], custom: 'drink' },
  { id: 41, cat: '飲料', ic: 'cup', n: '古早味豆漿', d: '', p: 30, custom: 'drink' },
]

const catByName = new Map(CAT_META.map((c) => [c.name, c]))

export const PICKUP_TIMES: Array<[string, string]> = [
  ['盡快', '約15分'],
  ['12:30', ''],
  ['12:45', ''],
  ['13:00', ''],
  ['13:15', ''],
  ['13:30', ''],
]

export const MEMBER_DISCOUNT_CENTS = 10

export function buildDemoMenu(): ShoppingMenu {
  const categories: MenuCategory[] = CAT_META.map((c, i) => ({
    id: c.id,
    name: c.name,
    en: c.en,
    sortOrder: i,
  }))

  const products: MenuProduct[] = RAW.map((m) => {
    const cat = catByName.get(m.cat)!
    return {
      id: `demo-${m.id}`,
      categoryId: cat.id,
      categoryName: cat.name,
      name: m.n,
      description: m.d || null,
      priceCents: m.p,
      imageUrl: null,
      iconKey: m.ic,
      soldout: !!m.soldout,
      noDelivery: !!m.noDelivery,
      tags: m.tags || [],
      optionGroups: m.custom ? structuredClone(OPTS[m.custom] || []) : [],
    }
  })

  return { store: { ...store }, categories, products, isDemo: true }
}
