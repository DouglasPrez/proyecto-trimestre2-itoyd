import { test, expect } from '@playwright/test'

test.describe('Crear usuario (registro)', () => {
  test('registro exitoso redirige a / y muestra navbar con sesión', async ({ page }) => {
    const unique = Date.now()
    await page.goto('/register')

    await page.locator('input').first().fill(`Test User ${unique}`)
    await page.locator('input[type="email"]').fill(`test${unique}@example.com`)
    await page.locator('input[type="password"]').fill('password123')
    await page.getByRole('button', { name: 'Crear cuenta' }).click()

    await expect(page).toHaveURL('/')
    await expect(page.getByRole('button', { name: 'Salir' })).toBeVisible()
  })

  test('registro con email duplicado muestra error', async ({ page }) => {
    await page.goto('/register')

    await page.locator('input').first().fill('Juan Existente')
    await page.locator('input[type="email"]').fill('juan@email.com')
    await page.locator('input[type="password"]').fill('password123')
    await page.getByRole('button', { name: 'Crear cuenta' }).click()

    await expect(page.locator('.bg-red-50')).toBeVisible()
    await expect(page).toHaveURL('/register')
  })

  test('el formulario requiere nombre, email y contraseña', async ({ page }) => {
    await page.goto('/register')

    await page.getByRole('button', { name: 'Crear cuenta' }).click()
    await expect(page).toHaveURL('/register')
  })

  test('la página de registro muestra enlace a login', async ({ page }) => {
    await page.goto('/register')
    await expect(page.getByRole('link', { name: 'Inicia sesión' })).toBeVisible()
  })

  test('el heading muestra "Crear cuenta"', async ({ page }) => {
    await page.goto('/register')
    await expect(page.getByRole('heading', { name: 'Crear cuenta' })).toBeVisible()
  })
})
