"""
SportSpace API — Lambda entry point (E4)
Runtime: Python 3.12

Wraps the FastAPI app with Mangum and seeds a fresh SQLite DB in /tmp
on every cold start (ephemeral — intentional for demo/dev).

Handler string: index.handler  (Terraform compute module default)
"""

import os
import sys

# Ensure the package root is on the Python path when running inside the zip.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from mangum import Mangum

from app.main import app
from app.database import engine, Base, SessionLocal
from app import models
from app.auth import hash_password
from datetime import datetime, timedelta


# ---------------------------------------------------------------------------
# Cold-start seed — runs once per Lambda instance lifecycle
# ---------------------------------------------------------------------------

def _seed_db() -> None:
    """Create tables and populate demo data if the DB is empty."""
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        if db.query(models.Complex).first():
            return  # already seeded on a previous warm invocation

        # Complexes
        americas = models.Complex(
            name="Las Américas", zone="Zona Norte",
            address="Blvd. Los Próceres 18-50, Guatemala"
        )
        norte = models.Complex(
            name="Complejo Norte", zone="Zona Norte",
            address="Calzada Roosevelt 12-00, Guatemala"
        )
        sur = models.Complex(
            name="Complejo Sur", zone="Zona Sur",
            address="Av. Petapa 44-60, Guatemala"
        )
        db.add_all([americas, norte, sur])
        db.flush()

        # Spaces
        tenis1 = models.Space(complex_id=americas.id, name="Tenis No. 1", sport_type="tenis",
                              duration_minutes=60, cleaning_minutes=15, price_per_hour=75.0,
                              open_time="07:00", close_time="22:00")
        tenis2 = models.Space(complex_id=americas.id, name="Tenis No. 2", sport_type="tenis",
                              duration_minutes=60, cleaning_minutes=15, price_per_hour=75.0,
                              open_time="07:00", close_time="22:00")
        padel1 = models.Space(complex_id=americas.id, name="Pádel No. 1", sport_type="padel",
                              duration_minutes=60, cleaning_minutes=15, price_per_hour=100.0,
                              open_time="07:00", close_time="21:00")
        futbol1 = models.Space(complex_id=norte.id, name="Fútbol 5 No. 1", sport_type="futbol",
                               duration_minutes=60, cleaning_minutes=15, price_per_hour=200.0,
                               open_time="06:00", close_time="22:00")
        basket1 = models.Space(complex_id=norte.id, name="Básquet No. 1", sport_type="basquetbol",
                               duration_minutes=60, cleaning_minutes=10, price_per_hour=150.0,
                               open_time="07:00", close_time="21:00")
        tenis_sur = models.Space(complex_id=sur.id, name="Tenis No. 1", sport_type="tenis",
                                 duration_minutes=60, cleaning_minutes=15, price_per_hour=80.0,
                                 open_time="07:00", close_time="21:00")
        db.add_all([tenis1, tenis2, padel1, futbol1, basket1, tenis_sur])
        db.flush()

        # Users
        admin1 = models.User(
            email="admin@sportspace.com", name="Admin Las Américas",
            hashed_password=hash_password("password123"),
            role=models.UserRole.ADMIN, complex_id=americas.id
        )
        admin2 = models.User(
            email="admin2@sportspace.com", name="Admin Complejo Norte",
            hashed_password=hash_password("password123"),
            role=models.UserRole.ADMIN, complex_id=norte.id
        )
        user1 = models.User(
            email="juan@email.com", name="Juan Pérez",
            hashed_password=hash_password("password123"),
            role=models.UserRole.USER
        )
        user2 = models.User(
            email="maria@email.com", name="María García",
            hashed_password=hash_password("password123"),
            role=models.UserRole.USER
        )
        db.add_all([admin1, admin2, user1, user2])
        db.flush()

        # Sample reservations
        today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)

        def _make_res(space, user, hour, days_offset=0):
            start = today + timedelta(days=days_offset, hours=hour)
            end = start + timedelta(minutes=space.duration_minutes)
            res = models.Reservation(
                space_id=space.id, user_id=user.id,
                start_time=start, end_time=end,
                status=models.ReservationStatus.CONFIRMED,
                amount_paid=space.price_per_hour,
                payment_method_last4="4321",
                created_at=datetime.utcnow(),
            )
            db.add(res)
            db.flush()
            res.reservation_code = f"SPT-{start.year}-{res.id:06d}"

        _make_res(tenis1, user1, 8)
        _make_res(tenis1, user2, 10)
        _make_res(tenis2, user1, 9)
        _make_res(padel1, user2, 11)
        _make_res(futbol1, user1, 18, days_offset=2)
        _make_res(tenis1, user1, 9, days_offset=1)

        # Sample maintenance block
        db.add(models.Block(
            space_id=padel1.id,
            start_time=today + timedelta(hours=7),
            end_time=today + timedelta(hours=9),
            reason="Mantenimiento de red",
            created_by_id=admin1.id,
        ))

        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


_seed_db()

# Mangum adapts ASGI (FastAPI) to the Lambda + API Gateway HTTP API v2 event format.
handler = Mangum(app, lifespan="off")
