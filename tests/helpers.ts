import type { Page } from '@playwright/test'

export const ADMIN_EMAIL = 'admin@sportspace.com'
export const ADMIN_PASSWORD = 'password123'
export const USER_EMAIL = 'juan@email.com'
export const USER_PASSWORD = 'password123'

export async function login(page: Page, email: string, password: string) {
  await page.goto('/login')
  await page.locator('input[type="email"]').fill(email)
  await page.locator('input[type="password"]').fill(password)
  await page.getByRole('button', { name: 'Ingresar' }).click()
  await page.waitForURL(url => !url.pathname.includes('/login'))
}

export function todayISO(): string {
  const now = new Date()
  const yyyy = now.getFullYear()
  const mm = String(now.getMonth() + 1).padStart(2, '0')
  const dd = String(now.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
}
