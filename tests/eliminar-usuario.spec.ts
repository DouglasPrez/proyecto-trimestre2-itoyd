import { test, expect } from '@playwright/test'
import { login, USER_EMAIL, USER_PASSWORD } from './helpers'

test.describe('Cancelación de reservas y listado', () => {
  test.beforeEach(async ({ page }) => {
    await login(page, USER_EMAIL, USER_PASSWORD)
  })

  test('usuario puede acceder a /reservations', async ({ page }) => {
    await page.goto('/reservations')
    await expect(page.getByRole('heading', { name: 'Mis Reservas' })).toBeVisible()
  })

  test('la página de reservas muestra las tabs Próximas e Historial', async ({ page }) => {
    await page.goto('/reservations')
    await expect(page.getByRole('button', { name: 'Próximas' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Historial' })).toBeVisible()
  })

  test('puede cambiar a la pestaña Historial', async ({ page }) => {
    await page.goto('/reservations')
    await page.getByRole('button', { name: 'Historial' }).click()

    const historialBtn = page.getByRole('button', { name: 'Historial' })
    await expect(historialBtn).toHaveClass(/bg-white/)
  })

  test('reservas cancelables muestran botón Cancelar', async ({ page }) => {
    await page.goto('/reservations')

    const cancelLinks = page.getByRole('link', { name: 'Cancelar' })
    const count = await cancelLinks.count()

    if (count > 0) {
      await expect(cancelLinks.first()).toBeVisible()
    } else {
      // Sin reservas próximas, verifica el estado vacío
      await expect(page.getByText('No tienes reservas próximas.')).toBeVisible()
    }
  })

  test('botón Nueva reserva lleva a la página de búsqueda', async ({ page }) => {
    await page.goto('/reservations')
    await page.getByRole('link', { name: 'Nueva reserva' }).click()
    await expect(page).toHaveURL('/')
  })
})
