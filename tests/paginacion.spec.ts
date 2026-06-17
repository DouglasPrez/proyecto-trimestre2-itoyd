import { test, expect } from '@playwright/test'
import { login, ADMIN_EMAIL, ADMIN_PASSWORD } from './helpers'

test.describe('Paginación / navegación de agenda admin', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, ADMIN_EMAIL, ADMIN_PASSWORD)
    await page.goto('/admin')
  })

  test('la agenda muestra la tab Agenda activa por defecto', async ({ page }) => {
    const agendaTab = page.getByRole('button', { name: 'Agenda' })
    await expect(agendaTab).toBeVisible()
    await expect(agendaTab).toHaveClass(/bg-white/)
  })

  test('puede cambiar a la tab Reporte mensual', async ({ page }) => {
    await page.getByRole('button', { name: 'Reporte mensual' }).click()

    const reporteTab = page.getByRole('button', { name: 'Reporte mensual' })
    await expect(reporteTab).toHaveClass(/bg-white/)
    await expect(page.getByRole('heading', { name: /Utilización/ })).toBeVisible({ timeout: 8000 })
  })

  test('puede volver a la tab Agenda desde Reporte', async ({ page }) => {
    await page.getByRole('button', { name: 'Reporte mensual' }).click()
    await page.getByRole('button', { name: 'Agenda' }).click()

    await expect(page.getByRole('button', { name: 'Agenda' })).toHaveClass(/bg-white/)
  })

  test('botón siguiente día avanza la fecha en la agenda', async ({ page }) => {
    const tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    const tomorrowDay = String(tomorrow.getDate())

    // Los botones con clase p-2 son prevDay (nth 0) y nextDay (nth 1)
    await page.locator('button[class*="p-2"]').nth(1).click()
    await expect(page.locator('span.font-semibold').first()).toContainText(tomorrowDay)
  })

  test('botón "Hoy" devuelve a la fecha actual', async ({ page }) => {
    await page.locator('button[class*="p-2"]').nth(1).click()
    await page.getByRole('button', { name: 'Hoy' }).click()

    const today = String(new Date().getDate())
    await expect(page.locator('span.font-semibold').first()).toContainText(today)
  })

  test('la agenda tiene botones de navegación anterior y siguiente', async ({ page }) => {
    await expect(page.locator('button[class*="p-2"]').nth(0)).toBeVisible()
    await expect(page.locator('button[class*="p-2"]').nth(1)).toBeVisible()
    await expect(page.getByRole('button', { name: 'Hoy' })).toBeVisible()
  })
})
