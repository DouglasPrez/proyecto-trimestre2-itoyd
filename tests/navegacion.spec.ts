import { test, expect } from '@playwright/test'
import { login, USER_EMAIL, USER_PASSWORD, ADMIN_EMAIL, ADMIN_PASSWORD } from './helpers'

test.describe('Navegación', () => {
  test('visitante anónimo ve enlaces Ingresar y Registrarse en navbar', async ({ page }) => {
    await page.goto('/')
    await expect(page.getByRole('link', { name: 'Ingresar' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Registrarse' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Salir' })).not.toBeVisible()
  })

  test('usuario autenticado ve "Mis reservas" y "Salir" en navbar', async ({ page }) => {
    await login(page, USER_EMAIL, USER_PASSWORD)
    await expect(page.getByRole('link', { name: 'Mis reservas' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Salir' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Ingresar' })).not.toBeVisible()
  })

  test('admin autenticado ve "Admin" en navbar', async ({ page }) => {
    await login(page, ADMIN_EMAIL, ADMIN_PASSWORD)
    await expect(page.getByRole('link', { name: 'Admin' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Mis reservas' })).not.toBeVisible()
  })

  test('logo SportSpace navega a /', async ({ page }) => {
    await page.goto('/login')
    await page.getByRole('link', { name: 'SportSpace' }).click()
    await expect(page).toHaveURL('/')
  })

  test('enlace Mis reservas en navbar navega a /reservations', async ({ page }) => {
    await login(page, USER_EMAIL, USER_PASSWORD)
    await page.getByRole('link', { name: 'Mis reservas' }).click()
    await expect(page).toHaveURL('/reservations')
  })

  test('enlace Admin en navbar navega a /admin', async ({ page }) => {
    await login(page, ADMIN_EMAIL, ADMIN_PASSWORD)
    await page.getByRole('link', { name: 'Admin' }).click()
    await expect(page).toHaveURL('/admin')
  })

  test('ruta inexistente redirige a /', async ({ page }) => {
    await page.goto('/ruta-que-no-existe')
    await expect(page).toHaveURL('/')
  })

  test('enlace Ingresar lleva a /login', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('link', { name: 'Ingresar' }).click()
    await expect(page).toHaveURL('/login')
  })

  test('enlace Registrarse lleva a /register', async ({ page }) => {
    await page.goto('/')
    await page.getByRole('link', { name: 'Registrarse' }).click()
    await expect(page).toHaveURL('/register')
  })
})
