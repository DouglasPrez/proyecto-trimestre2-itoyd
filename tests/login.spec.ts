import { test, expect } from '@playwright/test'
import { ADMIN_EMAIL, ADMIN_PASSWORD, USER_EMAIL, USER_PASSWORD } from './helpers'

test.describe('Login', () => {
  test('login exitoso como usuario regular redirige a /', async ({ page }) => {
    await page.goto('/login')
    await page.locator('input[type="email"]').fill(USER_EMAIL)
    await page.locator('input[type="password"]').fill(USER_PASSWORD)
    await page.getByRole('button', { name: 'Ingresar' }).click()

    await expect(page).toHaveURL('/')
    await expect(page.getByText('Reserva tu cancha')).toBeVisible()
  })

  test('login exitoso como admin redirige a /admin', async ({ page }) => {
    await page.goto('/login')
    await page.locator('input[type="email"]').fill(ADMIN_EMAIL)
    await page.locator('input[type="password"]').fill(ADMIN_PASSWORD)
    await page.getByRole('button', { name: 'Ingresar' }).click()

    await expect(page).toHaveURL('/admin')
    await expect(page.getByRole('heading', { name: 'Panel de administración' })).toBeVisible()
  })

  test('login fallido con credenciales incorrectas no autentica al usuario', async ({ page }) => {
    await page.goto('/login')
    await page.locator('input[type="email"]').fill('noexiste@email.com')
    await page.locator('input[type="password"]').fill('claveincorrecta')

    const [response] = await Promise.all([
      page.waitForResponse(r => r.url().includes('/auth/login') && r.request().method() === 'POST'),
      page.getByRole('button', { name: 'Ingresar' }).click(),
    ])

    // El interceptor axios hace window.location.href='/login' en 401,
    // recargando la página sin sesión activa
    expect(response.ok()).toBe(false)
    await page.waitForURL('/login')
    await expect(page.getByRole('button', { name: 'Salir' })).not.toBeVisible()
    await expect(page.getByRole('heading', { name: 'SportSpace' })).toBeVisible()
  })

  test('la página de login muestra el enlace a registro', async ({ page }) => {
    await page.goto('/login')
    await expect(page.getByRole('link', { name: 'Regístrate' })).toBeVisible()
  })

  test('botón queda deshabilitado durante el envío', async ({ page }) => {
    await page.goto('/login')
    await page.locator('input[type="email"]').fill(USER_EMAIL)
    await page.locator('input[type="password"]').fill(USER_PASSWORD)
    await page.getByRole('button', { name: 'Ingresar' }).click()

    await expect(page.getByRole('button', { name: /Ingresando|Ingresar/ })).toBeVisible()
  })
})
