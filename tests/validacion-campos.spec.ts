import { test, expect } from '@playwright/test'

test.describe('Validación de campos', () => {
  test('campo email en login rechaza texto sin formato de email', async ({ page }) => {
    await page.goto('/login')
    const emailInput = page.locator('input[type="email"]')
    await emailInput.fill('noesuncorreo')
    await page.getByRole('button', { name: 'Ingresar' }).click()

    await expect(page).toHaveURL('/login')
    const validity = await emailInput.evaluate((el: HTMLInputElement) => el.validity.valid)
    expect(validity).toBe(false)
  })

  test('campo email en registro rechaza texto sin formato de email', async ({ page }) => {
    await page.goto('/register')
    const emailInput = page.locator('input[type="email"]')
    await emailInput.fill('noesuncorreo')
    await page.getByRole('button', { name: 'Crear cuenta' }).click()

    await expect(page).toHaveURL('/register')
    const validity = await emailInput.evaluate((el: HTMLInputElement) => el.validity.valid)
    expect(validity).toBe(false)
  })

  test('contraseña en registro tiene minLength=6', async ({ page }) => {
    await page.goto('/register')
    const passInput = page.locator('input[type="password"]')
    await page.locator('input').first().fill('Test')
    await page.locator('input[type="email"]').fill('test@test.com')
    await passInput.fill('123')
    await page.getByRole('button', { name: 'Crear cuenta' }).click()

    await expect(page).toHaveURL('/register')
    const validity = await passInput.evaluate((el: HTMLInputElement) => el.validity.valid)
    expect(validity).toBe(false)
  })

  test('campo nombre en registro es requerido', async ({ page }) => {
    await page.goto('/register')
    await page.locator('input[type="email"]').fill('test@test.com')
    await page.locator('input[type="password"]').fill('password123')
    await page.getByRole('button', { name: 'Crear cuenta' }).click()

    await expect(page).toHaveURL('/register')
  })

  test('campo email en login es requerido', async ({ page }) => {
    await page.goto('/login')
    await page.locator('input[type="password"]').fill('password123')
    await page.getByRole('button', { name: 'Ingresar' }).click()

    await expect(page).toHaveURL('/login')
  })

  test('campo contraseña en login es requerido', async ({ page }) => {
    await page.goto('/login')
    await page.locator('input[type="email"]').fill('test@test.com')
    await page.getByRole('button', { name: 'Ingresar' }).click()

    await expect(page).toHaveURL('/login')
  })

  test('campo Nombre del espacio en SpaceConfig es requerido', async ({ page }) => {
    await page.goto('/login')
    await page.locator('input[type="email"]').fill('admin@sportspace.com')
    await page.locator('input[type="password"]').fill('password123')
    await page.getByRole('button', { name: 'Ingresar' }).click()
    await page.waitForURL('/admin')

    await page.goto('/admin/spaces/new')
    await page.locator('input[type="number"]').first().fill('100')
    await page.getByRole('button', { name: 'Guardar espacio' }).click()

    await expect(page).toHaveURL('/admin/spaces/new')
  })
})
