# SportSpace — App

Sistema de reservas de canchas deportivas.

## Cómo correr la aplicación

### 1. Backend (Python / FastAPI)

```bash
cd backend

# Instalar dependencias (solo la primera vez)
pip3 install -r requirements.txt

# Poblar la base de datos con datos de demo (solo la primera vez)
python3 seed.py

# Iniciar el servidor
python3 -m uvicorn app.main:app --reload --port 8000
```

El backend corre en: http://localhost:8000  
Documentación automática: http://localhost:8000/docs

### 2. Frontend (React / Vite)

```bash
cd frontend

# Instalar dependencias (solo la primera vez)
npm install

# Iniciar el servidor de desarrollo
npm run dev
```

El frontend corre en: http://localhost:5173

---

## Cuentas de demo

| Rol              | Email                   | Contraseña   |
|------------------|-------------------------|--------------|
| Admin (Las Américas) | admin@sportspace.com    | password123  |
| Admin (Norte)    | admin2@sportspace.com   | password123  |
| Usuario          | juan@email.com          | password123  |
| Usuario          | maria@email.com         | password123  |

---

## Flujo principal

1. Entra en http://localhost:5173
2. Selecciona deporte, fecha y zona → clic en **Buscar disponibilidad**
3. Haz clic en un slot verde (disponible)
4. Ingresa cualquier número de 4+ dígitos como "tarjeta" y confirma
5. Verás el voucher con código `SPT-YEAR-XXXXXX`

**Como admin (admin@sportspace.com):**
- Ve a `/admin` para la agenda del día
- Clic en slot verde para crear bloqueo
- Clic en el candado para eliminar un bloqueo
- Pestaña "Reporte mensual" para ver ocupación

---

## Estructura

```
App/
├── backend/
│   ├── app/
│   │   ├── main.py          # FastAPI app + CORS
│   │   ├── database.py      # SQLAlchemy + SQLite
│   │   ├── models.py        # User, Complex, Space, Reservation, Block
│   │   ├── schemas.py       # Pydantic schemas
│   │   ├── auth.py          # JWT + password hashing
│   │   └── routes/
│   │       ├── auth.py          # /auth/register, /auth/login
│   │       ├── availability.py  # /availability/search, /{space}/{date}
│   │       ├── reservations.py  # /reservations (CRUD)
│   │       └── admin.py         # /admin/agenda, /admin/spaces, /admin/blocks
│   ├── seed.py
│   └── requirements.txt
└── frontend/
    └── src/
        ├── pages/
        │   ├── SearchPage.tsx        # Mockup 1 — Búsqueda
        │   ├── ReservationPage.tsx   # Mockup 2 — Confirmar + countdown 15 min
        │   ├── VoucherPage.tsx       # Mockup 3 — Voucher confirmado
        │   ├── CancelPage.tsx        # Mockup 4 — Política de cancelación
        │   ├── MyReservationsPage.tsx # Mockup 7 — Mis reservas
        │   ├── AdminDashboard.tsx    # Mockup 5 — Agenda admin + reporte
        │   └── SpaceConfigPage.tsx   # Mockup 6 — Configurar cancha
        ├── api/client.ts     # Axios + tipos TypeScript
        └── context/AuthContext.tsx  # JWT auth state
```
