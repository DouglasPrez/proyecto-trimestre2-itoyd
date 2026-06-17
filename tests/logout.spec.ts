import { test, expect } from '@playwright/test'
import { login, USER_EMAIL, USER_PASSWORD, ADMIN_EMAIL, ADMIN_PASSWORD } from './helpers'

test.describe('Logout', () => {
  test('usuario puede cerrar sesión y es redirigido a /login', async ({ page }) => {
    await login(page, USER_EMAIL, USER_PASSWORD)
    await expect(page).toHaveURL('/')

    await page.getByRole('button', { name: 'Salir' }).click()
    await expect(page).toHaveURL('/login')
  })

  test('tras logout, /reservations redirige a /login', async ({ page }) => {
    await login(page, USER_EMAIL, USER_PASSWORD)
    await page.getByRole('button', { name: 'Salir' }).click()
    await expect(page).toHaveURL('/login')

    await page.goto('/reservations')
    await expect(page).toHaveURL('/login')
  })

  test('tras logout, /admin redirige a /login', async ({ page }) => {
    await login(page, ADMIN_EMAIL, ADMIN_PASSWORD)
    await page.getByRole('button', { name: 'Salir' }).click()
    await expect(page).toHaveURL('/login')

    await page.goto('/admin')
    await expect(page).toHaveURL('/login')
  })

  test('tras logout, la navbar muestra enlaces de invitado', async ({ page }) => {
    await login(page, USER_EMAIL, USER_PASSWORD)
    await page.getByRole('button', { name: 'Salir' }).click()

    await expect(page.getByRole('link', { name: 'Ingresar' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Registrarse' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Salir' })).not.toBeVisible()
  })
})
