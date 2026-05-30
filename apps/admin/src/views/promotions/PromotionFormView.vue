<template>
  <div>
    <a-page-header :title="isEdit ? '編輯促銷活動' : '新增促銷活動'" @back="$router.push({ name: 'promotions' })" />

    <a-spin :spinning="loading">
      <a-form :model="form" :label-col="{ span: 4 }" :wrapper-col="{ span: 16 }" @finish="handleSubmit">
        <a-divider>基本資訊</a-divider>

        <a-form-item label="活動名稱" :rules="[{ required: true, message: '請輸入名稱' }]">
          <a-input v-model:value="form.name" />
        </a-form-item>

        <a-form-item label="描述">
          <a-textarea v-model:value="form.description" :rows="2" />
        </a-form-item>

        <a-form-item label="優先順序">
          <a-input-number v-model:value="form.priority" :min="0" style="width: 120px" />
          <span style="margin-left: 8px; color: #888">數字越大優先越高</span>
        </a-form-item>

        <a-form-item label="可疊加">
          <a-switch v-model:checked="form.stackable" />
        </a-form-item>

        <a-form-item label="啟用">
          <a-switch v-model:checked="form.is_active" />
        </a-form-item>

        <a-divider>時間排程</a-divider>

        <a-form-item label="活動期間">
          <a-range-picker v-model:value="dateRange" show-time />
        </a-form-item>

        <a-divider>促銷策略</a-divider>

        <a-form-item label="策略類型" :rules="[{ required: true, message: '請選擇策略' }]">
          <a-select v-model:value="form.strategy" style="width: 280px" @change="onStrategyChange">
            <a-select-option value="thresholdAmountOff">滿額折扣（固定金額）</a-select-option>
            <a-select-option value="thresholdPercentOff">滿額折扣（百分比）</a-select-option>
            <a-select-option value="nthItemDiscount">第 N 件折扣</a-select-option>
            <a-select-option value="buyXGetY">買 X 送 Y</a-select-option>
            <a-select-option value="bundlePrice">組合價</a-select-option>
          </a-select>
        </a-form-item>

        <!-- Dynamic config fields -->
        <template v-if="form.strategy === 'thresholdAmountOff'">
          <a-form-item label="門檻金額 (元)">
            <a-input-number v-model:value="form.config.threshold_amount" :min="0" style="width: 200px" />
          </a-form-item>
          <a-form-item label="折扣金額 (元)">
            <a-input-number v-model:value="form.config.off_amount" :min="0" style="width: 200px" />
          </a-form-item>
        </template>

        <template v-if="form.strategy === 'thresholdPercentOff'">
          <a-form-item label="門檻金額 (元)">
            <a-input-number v-model:value="form.config.threshold_amount" :min="0" style="width: 200px" />
          </a-form-item>
          <a-form-item label="折扣百分比 (%)">
            <a-input-number v-model:value="form.config.off_pct" :min="0" :max="100" style="width: 200px" />
          </a-form-item>
        </template>

        <template v-if="form.strategy === 'nthItemDiscount'">
          <a-form-item label="第 N 件">
            <a-input-number v-model:value="form.config.nth" :min="2" style="width: 200px" />
          </a-form-item>
          <a-form-item label="折扣百分比 (%)">
            <a-input-number v-model:value="form.config.nth_discount_pct" :min="0" :max="100" style="width: 200px" />
          </a-form-item>
        </template>

        <template v-if="form.strategy === 'buyXGetY'">
          <a-form-item label="買 N 件">
            <a-input-number v-model:value="form.config.buy_n" :min="1" style="width: 200px" />
          </a-form-item>
          <a-form-item label="送 N 件">
            <a-input-number v-model:value="form.config.get_n" :min="1" style="width: 200px" />
          </a-form-item>
          <a-form-item label="贈品折扣 (%)">
            <a-input-number v-model:value="form.config.get_discount_pct" :min="0" :max="100" style="width: 200px" />
            <span style="margin-left: 8px; color: #888">100 = 免費</span>
          </a-form-item>
        </template>

        <template v-if="form.strategy === 'bundlePrice'">
          <a-form-item label="組合商品">
            <a-select v-model:value="form.config.bundle_product_ids" mode="multiple" placeholder="搜尋商品" show-search
              :filter-option="filterOption" style="width: 100%">
              <a-select-option v-for="p in allProducts" :key="p.id" :value="p.id" :label="p.name">
                {{ p.name }} ({{ p.sku }})
              </a-select-option>
            </a-select>
          </a-form-item>
          <a-form-item label="組合價 (元)">
            <a-input-number v-model:value="form.config.bundle_price" :min="0" style="width: 200px" />
          </a-form-item>
        </template>

        <a-divider>適用範圍</a-divider>

        <a-form-item label="指定商品">
          <a-select v-model:value="form.applicable_product_ids" mode="multiple" placeholder="留空 = 適用全部商品" show-search
            :filter-option="filterOption" style="width: 100%">
            <a-select-option v-for="p in allProducts" :key="p.id" :value="p.id" :label="p.name">
              {{ p.name }} ({{ p.sku }})
            </a-select-option>
          </a-select>
        </a-form-item>

        <a-form-item label="指定分類">
          <a-tree-select
            v-model:value="form.applicable_category_ids"
            tree-checkable
            multiple
            placeholder="留空 = 適用全部分類（選父分類含子孫商品）"
            tree-default-expand-all
            :tree-data="categoryTreeOptions"
            :field-names="{ label: 'path_label', value: 'id', children: 'children' }"
            style="width: 100%"
          />
        </a-form-item>

        <a-form-item label="會員等級">
          <a-select v-model:value="form.member_level_ids" mode="multiple" placeholder="留空 = 不限等級" style="width: 100%">
            <a-select-option v-for="l in allLevels" :key="l.id" :value="l.id">{{ l.name }}</a-select-option>
          </a-select>
        </a-form-item>

        <a-form-item :wrapper-col="{ offset: 4 }">
          <a-space>
            <a-button type="primary" html-type="submit" :loading="submitting">{{ isEdit ? '儲存' : '建立' }}</a-button>
            <a-button @click="$router.push({ name: 'promotions' })">取消</a-button>
          </a-space>
        </a-form-item>
      </a-form>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import dayjs, { type Dayjs } from 'dayjs'
import { message } from 'ant-design-vue'
import { getPromotion, createPromotion, updatePromotion } from '@/api/promotions'
import { listProducts, listCategoriesTree } from '@/api/products'
import { listMemberLevels } from '@/api/members'
import type { ProductRead, CategoryTreeNode, MemberLevelRead } from '@/types'

const route = useRoute()
const router = useRouter()
const isEdit = computed(() => !!route.params.id)
const loading = ref(false)
const submitting = ref(false)

const allProducts = ref<ProductRead[]>([])
const categoryTreeOptions = ref<CategoryTreeNode[]>([])
const allLevels = ref<MemberLevelRead[]>([])

function decorateTree(nodes: CategoryTreeNode[]): CategoryTreeNode[] {
  return nodes.map((n) => ({
    ...n,
    path_label: n.path_label || n.name,
    children: n.children?.length ? decorateTree(n.children) : [],
  }))
}

const dateRange = ref<[Dayjs, Dayjs] | null>(null)

const form = reactive({
  name: '',
  description: null as string | null,
  priority: 0,
  stackable: false,
  is_active: true,
  strategy: '' as string,
  config: {} as Record<string, any>,
  applicable_product_ids: [] as string[],
  applicable_category_ids: [] as string[],
  member_level_ids: [] as string[],
})

function onStrategyChange() {
  form.config = {}
  if (form.strategy === 'thresholdAmountOff') {
    form.config = { threshold_amount: 0, off_amount: 0 }
  } else if (form.strategy === 'thresholdPercentOff') {
    form.config = { threshold_amount: 0, off_pct: 0 }
  } else if (form.strategy === 'nthItemDiscount') {
    form.config = { nth: 2, nth_discount_pct: 50 }
  } else if (form.strategy === 'buyXGetY') {
    form.config = { buy_n: 2, get_n: 1, get_discount_pct: 100 }
  } else if (form.strategy === 'bundlePrice') {
    form.config = { bundle_product_ids: [], bundle_price: 0 }
  }
}

function filterOption(input: string, option: any) {
  return (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
}

async function handleSubmit() {
  submitting.value = true
  try {
    const payload = {
      ...form,
      starts_at: dateRange.value?.[0]?.toISOString() ?? null,
      ends_at: dateRange.value?.[1]?.toISOString() ?? null,
    }
    if (isEdit.value) {
      await updatePromotion(route.params.id as string, payload)
      message.success('已更新')
    } else {
      await createPromotion(payload)
      message.success('已建立')
    }
    router.push({ name: 'promotions' })
  } catch (e: any) {
    message.error(e.response?.data?.detail || '操作失敗')
  } finally {
    submitting.value = false
  }
}

async function loadDropdownData() {
  const [prods, cats, levels] = await Promise.allSettled([
    listProducts({ limit: 200 }),
    listCategoriesTree(),
    listMemberLevels(),
  ])
  if (prods.status === 'fulfilled') allProducts.value = prods.value.data
  if (cats.status === 'fulfilled') categoryTreeOptions.value = decorateTree(cats.value.data)
  if (levels.status === 'fulfilled') allLevels.value = levels.value.data
}

async function loadPromotion(id: string) {
  loading.value = true
  try {
    const { data: promo } = await getPromotion(id)
    form.name = promo.name
    form.description = promo.description
    form.priority = promo.priority
    form.stackable = promo.stackable
    form.is_active = promo.is_active
    form.strategy = promo.strategy
    form.config = { ...promo.config }
    form.applicable_product_ids = [...(promo.applicable_product_ids || [])]
    form.applicable_category_ids = [...(promo.applicable_category_ids || [])]
    form.member_level_ids = [...(promo.member_level_ids || [])]
    if (promo.starts_at || promo.ends_at) {
      dateRange.value = [
        promo.starts_at ? dayjs(promo.starts_at) : dayjs(),
        promo.ends_at ? dayjs(promo.ends_at) : dayjs().add(1, 'year'),
      ]
    }
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await Promise.all([
    loadDropdownData(),
    isEdit.value ? loadPromotion(route.params.id as string) : Promise.resolve(),
  ])
})
</script>
