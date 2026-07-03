import { defineConfig, devices } from '@playwright/test'
import { existsSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { env } from './config/env.js'

const isCI = !!process.env.CI
const root = resolve(dirname(fileURLToPath(import.meta.url)))
const cashierState = resolve(root, '.auth', 'cashier-pos.json')

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  workers: isCI ? 1 : 1,
  forbidOnly: isCI,
  retries: isCI ? 1 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  timeout: 30_000,
  expect: { timeout: 10_000 },
  globalSetup: './global-setup.ts',
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    locale: 'zh-TW',
  },
  projects: [
    {
      name: 'setup',
      testMatch: /.*\.setup\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        baseURL: env.posBaseUrl,
      },
    },
    {
      name: 'pos',
      testDir: './tests/pos',
      testMatch: '**/*.spec.ts',
      dependencies: ['setup'],
      use: {
        ...devices['Desktop Chrome'],
        baseURL: env.posBaseUrl,
        storageState: cashierState,
      },
    },
    {
      name: 'flows',
      testDir: './tests/flows',
      testMatch: '**/*.spec.ts',
      dependencies: ['setup'],
      use: {
        ...devices['Desktop Chrome'],
        baseURL: env.posBaseUrl,
        storageState: cashierState,
      },
    },
    {
      name: 'admin',
      testDir: './tests/admin',
      testMatch: '**/*.spec.ts',
      use: {
        ...devices['Desktop Chrome'],
        baseURL: env.adminBaseUrl,
      },
    },
  ],
})
