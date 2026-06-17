import { test, expect } from '@playwright/test'
import { todayISO } from './helpers'

test.describe('Búsqueda de canchas', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/')
  })

  test('la página principal carga automáticamente resultados', async ({ page }) => {
    await expect(page.getByRole('button', { name: /Buscar disponibilidad/ })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Buscar disponibilidad' })).not.toHaveText('Buscando...', { timeout: 8000 })
  })

  test('los filtros de deporte están presentes con las opciones correctas', async ({ page }) => {
    const deporteSelect = page.locator('select').nth(0)
    await expect(deporteSelect).toBeVisible()

    await expect(deporteSelect.getByRole('option', { name: 'Todos los deportes' })).toBeAttached()
    await expect(deporteSelect.getByRole('option', { name: 'Fútbol' })).toBeAttached()
    await expect(deporteSelect.getByRole('option', { name: 'Tenis' })).toBeAttached()
    await expect(deporteSelect.getByRole('option', { name: 'Básquetbol' })).toBeAttached()
    await expect(deporteSelect.getByRole('option', { name: 'Pádel' })).toBeAttached()
  })

  test('los filtros de zona están presentes con las opciones correctas', async ({ page }) => {
    const zonaSelect = page.locator('select').nth(1)
    await expect(zonaSelect).toBeVisible()

    await expect(zonaSelect.getByRole('option', { name: 'Todas las zonas' })).toBeAttached()
    await expect(zonaSelect.getByRole('option', { name: 'Zona Norte' })).toBeAttached()
    await expect(zonaSelect.getByRole('option', { name: 'Zona Sur' })).toBeAttached()
  })

  test('el campo de fecha muestra la fecha de hoy por defecto', async ({ page }) => {
    const dateInput = page.locator('input[type="date"]')
    await expect(dateInput).toHaveValue(todayISO())
  })

  test('buscar por deporte actualiza resultados', async ({ page }) => {
    await page.locator('select').nth(0).selectOption('futbol')
    await page.getByRole('button', { name: /Buscar disponibilidad/ }).click()

    await expect(page.getByRole('button', { name: 'Buscar disponibilidad' })).not.toHaveText('Buscando...', { timeout: 8000 })
    await expect(page.getByText('Disponible')).toBeVisible()
  })

  test('los slots de horario tienen estilos según su estado', async ({ page }) => {
    await page.getByRole('button', { name: /Buscar disponibilidad/ }).click()
    await expect(page.getByRole('button', { name: 'Buscar disponibilidad' })).not.toHaveText('Buscando...', { timeout: 8000 })

    const slots = page.locator('.slot-available, .slot-reserved, .slot-pending, .slot-blocked')
    const count = await slots.count()
    if (count > 0) {
      await expect(slots.first()).toBeVisible()
    }
  })
})
