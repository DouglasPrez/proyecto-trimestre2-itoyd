import { test, expect } from '@playwright/test'
import { login, ADMIN_EMAIL, ADMIN_PASSWORD } from './helpers'

test.describe('Editar espacio deportivo (admin)', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, ADMIN_EMAIL, ADMIN_PASSWORD)
  })

  test('admin puede acceder a /admin/spaces/new', async ({ page }) => {
    await page.goto('/admin/spaces/new')
    await expect(page.getByRole('heading', { name: 'Nuevo espacio' })).toBeVisible()
  })

  test('formulario de nuevo espacio tiene todos los campos requeridos', async ({ page }) => {
    await page.goto('/admin/spaces/new')

    await expect(page.getByPlaceholder('Tenis No. 3')).toBeVisible()
    await expect(page.locator('select').first()).toBeVisible()
    await expect(page.locator('input[type="number"]').first()).toBeVisible()
    await expect(page.getByRole('button', { name: 'Guardar espacio' })).toBeVisible()
  })

  test('admin puede crear un nuevo espacio y es redirigido a /admin', async ({ page }) => {
    await page.goto('/admin/spaces/new')

    await page.getByPlaceholder('Tenis No. 3').fill(`Cancha Test ${Date.now()}`)
    await page.locator('input[type="number"]').first().fill('100')
    await page.getByRole('button', { name: 'Guardar espacio' }).click()

    await expect(page.locator('.bg-green-50')).toBeVisible({ timeout: 5000 })
    await expect(page).toHaveURL('/admin', { timeout: 5000 })
  })

  test('admin puede editar un espacio existente desde la agenda', async ({ page }) => {
    await page.goto('/admin')

    const configLink = page.getByRole('link', { name: 'Config' }).first()
    const count = await configLink.count()
    if (count === 0) {
      await expect(page.getByRole('link', { name: 'Crear espacio' })).toBeVisible()
      return
    }

    await configLink.click()
    await expect(page.getByRole('heading', { name: 'Configurar espacio' })).toBeVisible()
  })

  test('botones de duración de slot son seleccionables', async ({ page }) => {
    await page.goto('/admin/spaces/new')

    const btn60 = page.getByRole('button', { name: '60 min' })
    await expect(btn60).toBeVisible()
    await btn60.click()
    await expect(btn60).toHaveClass(/bg-blue-600/)
  })
})
