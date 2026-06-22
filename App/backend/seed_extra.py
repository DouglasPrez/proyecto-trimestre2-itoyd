"""
Agrega datos adicionales de demostración sin borrar los existentes.
  cd App/backend && python seed_extra.py
"""
from datetime import datetime, timedelta
from app.database import SessionLocal, engine, Base
from app import models
from app.auth import hash_password

Base.metadata.create_all(bind=engine)
db = SessionLocal()

today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)

# ── Obtener espacios existentes ───────────────────────────────────────────────
spaces = {s.name: s for s in db.query(models.Space).all()}
complexes = {c.name: c for c in db.query(models.Complex).all()}

tenis1   = spaces.get("Tenis No. 1")   # Las Américas
tenis2   = spaces.get("Tenis No. 2")
padel1   = spaces.get("Pádel No. 1")
futbol1  = spaces.get("Fútbol 5 No. 1")
basket1  = spaces.get("Básquet No. 1")

# ── Usuarios nuevos ───────────────────────────────────────────────────────────
def get_or_create_user(email, name, role=models.UserRole.USER, complex_id=None):
    u = db.query(models.User).filter_by(email=email).first()
    if not u:
        u = models.User(
            email=email, name=name,
            hashed_password=hash_password("password123"),
            role=role, complex_id=complex_id,
        )
        db.add(u)
        db.flush()
    return u

carlos   = get_or_create_user("carlos@email.com",   "Carlos Morales")
sofia    = get_or_create_user("sofia@email.com",    "Sofía Ramírez")
andres   = get_or_create_user("andres@email.com",   "Andrés López")
valeria  = get_or_create_user("valeria@email.com",  "Valeria Castillo")
rodrigo  = get_or_create_user("rodrigo@email.com",  "Rodrigo Fuentes")
admin_sur = get_or_create_user(
    "admin3@sportspace.com", "Admin Complejo Sur",
    role=models.UserRole.ADMIN,
    complex_id=complexes.get("Complejo Sur", complexes.get("Las Américas")).id,
)

db.flush()

# ── Helper para crear reserva ─────────────────────────────────────────────────
def make_res(space, user, hour, days_offset=0,
             status=models.ReservationStatus.CONFIRMED,
             last4="1234", refund=None):
    if not space:
        return
    start = today + timedelta(days=days_offset, hours=hour)
    end   = start + timedelta(minutes=space.duration_minutes)
    res = models.Reservation(
        space_id=space.id,
        user_id=user.id,
        start_time=start,
        end_time=end,
        status=status,
        amount_paid=space.price_per_hour if status != models.ReservationStatus.CANCELLED else None,
        payment_method_last4=last4 if status != models.ReservationStatus.CANCELLED else None,
        refund_amount=refund,
        created_at=today + timedelta(days=days_offset - 3),
        cancelled_at=datetime.utcnow() if status == models.ReservationStatus.CANCELLED else None,
    )
    db.add(res)
    db.flush()
    res.reservation_code = f"SPT-{start.year}-{res.id:06d}"
    return res

# ── Reservas futuras (aparecen en "Próximas") ─────────────────────────────────
make_res(tenis1,  carlos,   9,  days_offset=1,  last4="5678")
make_res(tenis2,  sofia,    14, days_offset=1,  last4="9012")
make_res(padel1,  andres,   10, days_offset=2,  last4="3456")
make_res(futbol1, valeria,  17, days_offset=2,  last4="7890")
make_res(basket1, rodrigo,  8,  days_offset=3,  last4="2345")
make_res(tenis1,  valeria,  11, days_offset=4,  last4="6789")
make_res(futbol1, carlos,   19, days_offset=5,  last4="1111")
make_res(padel1,  sofia,    16, days_offset=6,  last4="2222")

# ── Reservas pasadas CONFIRMADAS (aparecen en "Historial") ────────────────────
make_res(tenis1,  carlos,   10, days_offset=-1, last4="5678")
make_res(tenis2,  andres,   9,  days_offset=-2, last4="3456")
make_res(padel1,  sofia,    15, days_offset=-3, last4="9012")
make_res(futbol1, rodrigo,  18, days_offset=-5, last4="2345")
make_res(basket1, valeria,  8,  days_offset=-7, last4="7890")
make_res(tenis1,  rodrigo,  11, days_offset=-10, last4="4444")

# ── Reservas CANCELADAS (historial con reembolso) ─────────────────────────────
make_res(padel1,  carlos,  13, days_offset=-4,
         status=models.ReservationStatus.CANCELLED, refund=50.0)
make_res(tenis2,  valeria, 10, days_offset=-6,
         status=models.ReservationStatus.CANCELLED, refund=37.5)
make_res(futbol1, andres,  17, days_offset=-8,
         status=models.ReservationStatus.CANCELLED, refund=0.0)

# ── Reservas EXPIRADAS ────────────────────────────────────────────────────────
make_res(basket1, sofia,  9, days_offset=-14,
         status=models.ReservationStatus.EXPIRED)
make_res(tenis1,  carlos, 8, days_offset=-20,
         status=models.ReservationStatus.EXPIRED)

db.commit()
print("Datos extra agregados exitosamente.")
print("\nCuentas de demo (password: password123):")
print("  carlos@email.com   — Carlos Morales")
print("  sofia@email.com    — Sofía Ramírez")
print("  andres@email.com   — Andrés López")
print("  valeria@email.com  — Valeria Castillo")
print("  rodrigo@email.com  — Rodrigo Fuentes")
db.close()
