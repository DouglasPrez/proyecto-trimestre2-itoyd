import { test, expect } from '@playwright/test'
import { login, USER_EMAIL, USER_PASSWORD, ADMIN_EMAIL, ADMIN_PASSWORD } from './helpers'

test.describe('Permisos y rutas protegidas', () => {
  test('visitante anónimo en /reservations redirige a /login', async ({ page }) => {
    await page.goto('/reservations')
    await expect(page).toHaveURL('/login')
  })

  test('visitante anónimo en /admin redirige a /login', async ({ page }) => {
    await page.goto('/admin')
    await expect(page).toHaveURL('/login')
  })

  test('visitante anónimo en /admin/spaces/new redirige a /login', async ({ page }) => {
    await page.goto('/admin/spaces/new')
    await expect(page).toHaveURL('/login')
  })

  test('usuario regular en /admin redirige a /', async ({ page }) => {
    await login(page, USER_EMAIL, USER_PASSWORD)
    await page.goto('/admin')
    await expect(page).toHaveURL('/')
  })

  test('usuario regular en /admin/spaces/new redirige a /', async ({ page }) => {
    await login(page, USER_EMAIL, USER_PASSWORD)
    await page.goto('/admin/spaces/new')
    await expect(page).toHaveURL('/')
  })

  test('admin puede acceder a /admin', async ({ page }) => {
    await login(page, ADMIN_EMAIL, ADMIN_PASSWORD)
    await page.goto('/admin')
    await expect(page).toHaveURL('/admin')
    await expect(page.getByRole('heading', { name: 'Panel de administración' })).toBeVisible()
  })

  test('admin puede acceder a /admin/spaces/new', async ({ page }) => {
    await login(page, ADMIN_EMAIL, ADMIN_PASSWORD)
    await page.goto('/admin/spaces/new')
    await expect(page).toHaveURL('/admin/spaces/new')
    await expect(page.getByRole('heading', { name: 'Nuevo espacio' })).toBeVisible()
  })

  test('usuario regular puede acceder a /reservations', async ({ page }) => {
    await login(page, USER_EMAIL, USER_PASSWORD)
    await page.goto('/reservations')
    await expect(page).toHaveURL('/reservations')
    await expect(page.getByRole('heading', { name: 'Mis Reservas' })).toBeVisible()
  })

  test('/ es accesible sin autenticación', async ({ page }) => {
    await page.goto('/')
    await expect(page).toHaveURL('/')
    await expect(page.getByText('Reserva tu cancha')).toBeVisible()
  })

  test('/login es accesible sin autenticación', async ({ page }) => {
    await page.goto('/login')
    await expect(page).toHaveURL('/login')
  })

  test('/register es accesible sin autenticación', async ({ page }) => {
    await page.goto('/register')
    await expect(page).toHaveURL('/register')
  })
})
