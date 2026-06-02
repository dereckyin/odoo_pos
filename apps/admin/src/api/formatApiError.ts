/** Turn axios / FastAPI errors into a single string for message.error(). */
export function formatApiError(e: unknown): string {
  const err = e as {
    response?: { data?: unknown; status?: number }
    message?: string
  }
  const data = err?.response?.data as { detail?: unknown } | string | undefined
  const d = typeof data === 'object' && data !== null ? (data as { detail?: unknown }).detail : undefined
  if (typeof d === 'string' && d.trim()) return d
  if (d && typeof d === 'object' && !Array.isArray(d)) {
    const o = d as { message?: string; message_zh?: string }
    if (typeof o.message === 'string' && o.message.trim()) return o.message
    if (typeof o.message_zh === 'string' && o.message_zh.trim()) return o.message_zh
  }
  if (Array.isArray(d)) {
    return d
      .map((x: { msg?: string; loc?: unknown[] }) => {
        if (x && typeof x === 'object' && typeof x.msg === 'string') return x.msg
        return JSON.stringify(x)
      })
      .join('；')
  }
  if (d && typeof d === 'object') return JSON.stringify(d)
  if (typeof data === 'string' && data.trim()) {
    const t = data.trim()
    return t.length <= 400 ? t : `${t.slice(0, 300)}…`
  }
  const st = err?.response?.status
  if (st === 401) return '未登入或登入已過期，請重新登入'
  if (st === 403) return '沒有權限執行此操作'
  if (st === 404) return '找不到資源'
  if (st === 409) return '資料衝突（例如 SKU 重複）'
  if (st === 422) return '送出資料格式不正確，請檢查欄位'
  if (st === 429) return '請求過於頻繁，請稍後再試'
  if (st && st >= 500) return `伺服器錯誤 (${st})，請查看後端日誌`
  if (err?.message) return err.message
  return '操作失敗'
}
