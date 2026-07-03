<template>
  <div>
    <a-page-header :title="isEdit ? '編輯商品' : '新增商品'" @back="$router.push({ name: 'products' })" />

    <a-spin :spinning="loading">
      <a-form :model="form" :label-col="{ span: 4 }" :wrapper-col="{ span: 16 }" @finish="handleSubmit">
        <a-form-item label="商品名稱" name="name" :rules="[{ required: true, message: '請輸入名稱' }]">
          <a-input v-model:value="form.name" />
        </a-form-item>

        <a-form-item label="SKU" name="sku" :rules="[{ required: true, message: '請輸入 SKU' }]">
          <a-input v-model:value="form.sku" />
        </a-form-item>

        <a-form-item label="售價 (元)" name="price_cents" :rules="[{ required: true, message: '請輸入售價' }]">
          <a-input-number v-model:value="form.price_cents" :min="0" :precision="0" style="width: 200px" />
        </a-form-item>

        <a-form-item label="成本 (元)" name="cost_cents">
          <a-input-number v-model:value="form.cost_cents" :min="0" :precision="0" style="width: 200px" />
        </a-form-item>

        <a-form-item label="稅率">
          <a-input-number v-model:value="form.tax_rate" :min="0" :max="1" :step="0.01" style="width: 200px" />
        </a-form-item>

        <a-form-item label="分類">
          <a-tree-select
            v-model:value="form.category_id"
            allow-clear
            placeholder="選擇分類"
            tree-default-expand-all
            :tree-data="categoryTreeOptions"
            :field-names="{ label: 'path_label', value: 'id', children: 'children' }"
            style="width: 100%"
          />
        </a-form-item>

        <a-form-item label="市集分類">
          <a-select
            v-model:value="marketplaceCategoryId"
            allow-clear
            placeholder="自動（依商品分類對應）"
            style="width: 100%"
            :options="feedCategoryOptions"
          />
          <div style="color: #888; font-size: 12px">跨店市集首頁的分類區塊；留空則依上方「分類」名稱自動對應。</div>
        </a-form-item>

        <a-form-item label="計重商品">
          <a-switch v-model:checked="form.is_weighted" />
        </a-form-item>

        <a-form-item label="單位">
          <a-input v-model:value="form.unit" style="width: 120px" />
        </a-form-item>

        <a-form-item label="上架">
          <a-switch v-model:checked="form.is_active" />
        </a-form-item>

        <a-form-item label="不顯示於 QR／桌邊點餐菜單">
          <a-switch v-model:checked="form.hide_from_public_ordering" />
          <div style="color: #888; font-size: 12px">勾選後顧客掃碼點餐看不到此商品（仍可在 POS 結帳）。</div>
        </a-form-item>

        <a-form-item label="不顯示於 POS「全部」瀏覽">
          <a-switch v-model:checked="form.hide_from_pos_browse" />
          <div style="color: #888; font-size: 12px">勾選後收銀「全部」網格不列出；條碼／搜尋與所屬分類內仍可點選。</div>
        </a-form-item>

        <a-form-item label="管理庫存">
          <a-switch v-model:checked="form.track_inventory" :disabled="isConsignmentBook" />
          <div style="color: #888; font-size: 12px">
            關閉後 POS 銷售不扣庫存（適用現泡飲品等無庫存概念品項）。寄賣書籍一律追蹤庫存。
          </div>
        </a-form-item>

        <a-form-item label="列印杯上標籤">
          <a-switch v-model:checked="form.print_label" />
          <div style="color: #888; font-size: 12px">勾選後 POS 接單／結帳會為此品項逐杯列印飲料標籤。</div>
        </a-form-item>

        <a-form-item label="可享會員折扣">
          <a-select v-model:value="form.member_discount_eligible" :options="eligibilityOptions" style="width: 200px" />
          <div style="color: #888; font-size: 12px">特價／簽名書等可設「不適用」；留「繼承分類」則依分類設定。</div>
        </a-form-item>
        <a-form-item label="可累積點數">
          <a-select v-model:value="form.points_earn_eligible" :options="eligibilityOptions" style="width: 200px" />
        </a-form-item>
        <a-form-item label="可使用點數折抵">
          <a-select v-model:value="form.points_redeem_eligible" :options="eligibilityOptions" style="width: 200px" />
        </a-form-item>

        <a-form-item label="商品圖片">
          <a-upload
            :before-upload="handleUpload"
            :show-upload-list="false"
            accept="image/*"
          >
            <a-button :loading="uploading">上傳圖片</a-button>
          </a-upload>
          <div v-if="form.image_url" style="margin-top: 8px; display: flex; align-items: flex-start; gap: 12px">
            <a-image :src="form.image_url" :width="120" />
            <a-button danger @click="removeImage">刪除圖片</a-button>
          </div>
        </a-form-item>

        <a-form-item label="條碼">
          <div v-for="(bc, idx) in barcodes" :key="idx" style="display: flex; gap: 8px; margin-bottom: 8px">
            <a-input v-model:value="barcodes[idx]" style="width: 260px" />
            <a-button danger @click="barcodes.splice(idx, 1)">移除</a-button>
          </div>
          <a-button type="dashed" @click="barcodes.push('')">+ 新增條碼</a-button>
        </a-form-item>

        <a-form-item label="品項選項">
          <a-select
            v-model:value="selectedOptionGroupIds"
            mode="multiple"
            placeholder="從選項庫選擇（甜度、冰塊、加料…）"
            style="width: 100%"
            :options="optionGroupOptions"
          />
          <div style="color: #888; font-size: 12px; margin-top: 4px">
            先在「選項庫」建立選項群組，再綁定到此商品。POS／QR 點餐時會跳出選項面板。
            <router-link :to="{ name: 'option-groups' }">管理選項庫</router-link>
          </div>
        </a-form-item>

        <a-form-item label="描述">
          <a-textarea v-model:value="form.description" :rows="3" />
        </a-form-item>

        <a-form-item :wrapper-col="{ offset: 4 }">
          <a-space>
            <a-button type="primary" html-type="submit" :loading="submitting">{{ isEdit ? '儲存' : '建立' }}</a-button>
            <a-button @click="$router.push({ name: 'products' })">取消</a-button>
          </a-space>
        </a-form-item>
      </a-form>
    </a-spin>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { message } from 'ant-design-vue'
import { formatApiError } from '@/api/formatApiError'
import { getProduct, createProduct, updateProduct, listCategoriesTree, uploadImage } from '@/api/products'
import { listOptionGroups, getProductOptionGroups, setProductOptionGroups } from '@/api/options'
import { listFeedCategories } from '@/api/marketplace'
import type { CategoryTreeNode, ProductCreate, ProductUpdate, OptionGroupRead } from '@/types'

const route = useRoute()
const router = useRouter()
const isEdit = computed(() => !!route.params.id)
const productKind = ref('regular')
const isConsignmentBook = computed(() => productKind.value === 'consignment_book')
const loading = ref(false)
const submitting = ref(false)
const uploading = ref(false)
const categoryTreeOptions = ref<CategoryTreeNode[]>([])

function decorateTree(nodes: CategoryTreeNode[]): CategoryTreeNode[] {
  return nodes.map((n) => ({
    ...n,
    path_label: n.path_label || n.name,
    children: n.children?.length ? decorateTree(n.children) : [],
  }))
}
const barcodes = ref<string[]>([])
const optionGroups = ref<OptionGroupRead[]>([])
const selectedOptionGroupIds = ref<string[]>([])
const feedCategories = ref<{ id: string; name: string; icon: string | null }[]>([])
const marketplaceCategoryId = ref<string | undefined>(undefined)

const feedCategoryOptions = computed(() =>
  feedCategories.value.map((c) => ({
    label: `${c.icon ? c.icon + ' ' : ''}${c.name}`,
    value: c.id,
  })),
)

const optionGroupOptions = computed(() =>
  optionGroups.value.map((g) => ({ label: g.name, value: g.id })),
)

const eligibilityOptions = [
  { label: '繼承分類', value: null },
  { label: '適用', value: true },
  { label: '不適用', value: false },
]

const form = reactive({
  name: '',
  sku: '',
  tax_rate: 0.05,
  category_id: undefined as string | undefined,
  is_weighted: false,
  unit: '個',
  is_active: true,
  hide_from_public_ordering: false,
  hide_from_pos_browse: false,
  member_discount_eligible: null as boolean | null,
  points_earn_eligible: null as boolean | null,
  points_redeem_eligible: null as boolean | null,
  track_inventory: true,
  print_label: false,
  image_url: '' as string | null,
  description: '' as string | null,
  price_cents: 0,
  cost_cents: null as number | null,
})

async function handleUpload(file: File) {
  uploading.value = true
  try {
    const { data } = await uploadImage(file)
    form.image_url = data.url
    message.success('圖片上傳成功')
  } catch {
    message.error('圖片上傳失敗')
  } finally {
    uploading.value = false
  }
  return false
}

function removeImage() {
  form.image_url = null
  message.success('已移除圖片，請記得按儲存')
}

async function handleSubmit() {
  submitting.value = true
  try {
    const rawPrice = form.price_cents
    const priceCents = typeof rawPrice === 'number' ? Math.round(rawPrice) : Math.round(Number(rawPrice))
    if (!Number.isFinite(priceCents) || priceCents < 0) {
      message.error('請輸入有效售價（元）')
      return
    }
    const costRaw = form.cost_cents
    const costCents =
      costRaw === null || costRaw === undefined
        ? null
        : Math.round(typeof costRaw === 'number' ? costRaw : Number(costRaw))
    if (costCents !== null && (!Number.isFinite(costCents) || costCents < 0)) {
      message.error('請輸入有效成本（元）')
      return
    }

    const base = {
      sku: form.sku.trim(),
      name: form.name.trim(),
      price_cents: priceCents,
      cost_cents: costCents,
      category_id: form.category_id ?? null,
      image_url: form.image_url?.trim() ? form.image_url.trim() : null,
      tax_rate: form.tax_rate,
      is_weighted: form.is_weighted,
      unit: (form.unit || '個').trim(),
      is_active: form.is_active,
      description: form.description?.trim() ? form.description.trim() : null,
      hide_from_public_ordering: form.hide_from_public_ordering,
      hide_from_pos_browse: form.hide_from_pos_browse,
      member_discount_eligible: form.member_discount_eligible,
      points_earn_eligible: form.points_earn_eligible,
      points_redeem_eligible: form.points_redeem_eligible,
      track_inventory: isConsignmentBook.value ? true : form.track_inventory,
      print_label: form.print_label,
      marketplace_category_id: marketplaceCategoryId.value ?? null,
      barcodes: barcodes.value.map((b) => b.trim()).filter(Boolean),
    }

    if (isEdit.value) {
      const payload: ProductUpdate = { ...base }
      const productId = route.params.id as string
      await updateProduct(productId, payload)
      await setProductOptionGroups(productId, {
        groups: selectedOptionGroupIds.value.map((id, idx) => ({
          option_group_id: id,
          sort_order: idx,
        })),
      })
      message.success('已更新')
    } else {
      const payload: ProductCreate = { ...base }
      const { data: created } = await createProduct(payload)
      if (selectedOptionGroupIds.value.length) {
        await setProductOptionGroups(created.id, {
          groups: selectedOptionGroupIds.value.map((id, idx) => ({
            option_group_id: id,
            sort_order: idx,
          })),
        })
      }
      message.success('已建立')
    }
    router.push({ name: 'products' })
  } catch (e: unknown) {
    message.error(formatApiError(e))
  } finally {
    submitting.value = false
  }
}

async function loadProduct(productId: string) {
  loading.value = true
  try {
    const [productRes, linksRes] = await Promise.allSettled([
      getProduct(productId),
      getProductOptionGroups(productId),
    ])
    if (productRes.status !== 'fulfilled') {
      throw productRes.reason
    }
    const { data } = productRes.value
    form.name = data.name
    form.sku = data.sku
    form.tax_rate = data.tax_rate
    form.category_id = data.category_id ?? undefined
    form.is_weighted = data.is_weighted
    form.unit = data.unit
    form.is_active = data.is_active
    form.hide_from_public_ordering = data.hide_from_public_ordering ?? false
    form.hide_from_pos_browse = data.hide_from_pos_browse ?? false
    form.member_discount_eligible = data.member_discount_eligible ?? null
    form.points_earn_eligible = data.points_earn_eligible ?? null
    form.points_redeem_eligible = data.points_redeem_eligible ?? null
    form.track_inventory = data.track_inventory ?? true
    form.print_label = data.print_label ?? false
    productKind.value = data.product_kind ?? 'regular'
    form.image_url = data.image_url
    form.description = data.description
    marketplaceCategoryId.value = data.marketplace_category_id ?? undefined
    form.price_cents = data.price_cents
    form.cost_cents = data.cost_cents
    barcodes.value = [...data.barcodes]
    if (linksRes.status === 'fulfilled') {
      selectedOptionGroupIds.value = linksRes.value.data
        .sort((a, b) => a.sort_order - b.sort_order)
        .map((l) => l.option_group_id)
    }
  } catch (e: unknown) {
    message.error(formatApiError(e))
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  const [treeRes, ogsRes, feedRes] = await Promise.allSettled([
    listCategoriesTree(),
    listOptionGroups(),
    listFeedCategories(),
  ])
  if (treeRes.status === 'fulfilled') {
    categoryTreeOptions.value = decorateTree(treeRes.value.data)
  }
  if (ogsRes.status === 'fulfilled') {
    optionGroups.value = ogsRes.value.data
  }
  if (feedRes.status === 'fulfilled') {
    feedCategories.value = feedRes.value.data
  }

  if (isEdit.value) {
    await loadProduct(route.params.id as string)
  }
})
</script>
