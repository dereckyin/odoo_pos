import { env } from '../config/env.js'

/** Absolute API URL. Playwright request baseURL + `/path` hits site root, not /api. */
export function apiUrl(path: string): string {
  const p = path.startsWith('/') ? path : `/${path}`
  return `${env.apiUrl}${p}`
}
