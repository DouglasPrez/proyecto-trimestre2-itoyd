"""
Test de integracion — Cancelacion de reserva con reembolso (Serie 2, Examen Final)

Prueba los servicios de SportSpace via la API REST con FastAPI TestClient.

Proposito:
  Validar que un usuario puede cancelar una reserva confirmada y recibir
  el reembolso correspondiente segun la politica de cancelacion:
    1. Autenticacion (login) -> obtiene token JWT
    2. Busqueda de disponibilidad -> encuentra canchas libres
    3. Creacion de reserva -> status PENDING
    4. Confirmacion con pago simulado -> status CONFIRMED, amount_paid = 75.0
    5. Cancelacion de reserva -> status CANCELLED, refund_amount > 0

Partes del test:
  - Setup: crea tablas y datos demo (complejo, espacio con politica de
           cancelacion: 4h reembolso completo, 50% penalizacion entre 1-4h,
           0% si falta < 1h)
  - Escenario: ejecuta los 5 pasos del flujo
  - Asserts: verifica status HTTP, transiciones de estado, reembolso
"""

import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'App', 'backend'))

from datetime import datetime
from fastapi.testclient import TestClient
from app.main import app
from app.database import Base, engine, SessionLocal
from app import models
from app.auth import hash_password


def setup_db():
    """Limpia y puebla la base de datos con datos demo para el test."""
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    americas = models.Complex(name="Las Americas", zone="Zona Norte",
                              address="Blvd. Los Proceres 18-50, Guatemala")
    db.add(americas)
    db.flush()

    # Cancha con politica de cancelacion estandar:
    # - cancel_free_hours = 4  (reembolso total si faltan > 4h)
    # - cancel_penalty_pct = 50 (50% de penalizacion entre 1-4h)
    # - cancel_no_refund_hours = 1 (sin reembolso si falta < 1h)
    tenis1 = models.Space(complex_id=americas.id, name="Tenis No. 1",
                          sport_type="tenis", duration_minutes=60,
                          cleaning_minutes=15, price_per_hour=75.0,
                          open_time="07:00", close_time="22:00",
                          cancel_free_hours=4, cancel_penalty_pct=50,
                          cancel_no_refund_hours=1)
    db.add(tenis1)
    db.flush()

    admin = models.User(email="admin@sportspace.com", name="Admin",
                        hashed_password=hash_password("password123"),
                        role=models.UserRole.ADMIN, complex_id=americas.id)
    user = models.User(email="juan@email.com", name="Juan Perez",
                       hashed_password=hash_password("password123"),
                       role=models.UserRole.USER)
    db.add_all([admin, user])
    db.flush()

    tenis1_id = tenis1.id
    user_email = user.email

    db.commit()
    db.close()
    return {"tenis1_id": tenis1_id, "user_email": user_email}


class TestCancelacionReserva:

    @classmethod
    def setup_class(cls):
        cls.data = setup_db()
        cls.client = TestClient(app)

    def test_cancelacion_reserva_con_reembolso(self):
        # 1. Login como usuario regular
        login_resp = self.client.post("/auth/login", json={
            "email": self.data["user_email"],
            "password": "password123",
        })
        assert login_resp.status_code == 200
        token = login_resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 2. Buscar disponibilidad del espacio
        today = datetime.utcnow().strftime("%Y-%m-%d")
        avail_resp = self.client.get(
            f"/availability/{self.data['tenis1_id']}/{today}"
        )
        assert avail_resp.status_code == 200
        avail = avail_resp.json()
        assert avail["space_id"] == self.data["tenis1_id"]

        available = [s for s in avail["slots"] if s["status"] == "available"]
        assert len(available) > 0, "Debe haber al menos un slot disponible"
        selected = available[0]

        # 3. Crear reserva (bloqueo optimista -> PENDING)
        create_resp = self.client.post("/reservations", json={
            "space_id": self.data["tenis1_id"],
            "start_time": selected["start_dt"],
        }, headers=headers)
        assert create_resp.status_code == 201
        reservation = create_resp.json()
        assert reservation["status"] == "PENDING"
        reservation_id = reservation["id"]

        # 4. Confirmar reserva con pago simulado -> CONFIRMED
        confirm_resp = self.client.put(
            f"/reservations/{reservation_id}/confirm",
            json={"payment_method_last4": "4321"},
            headers=headers,
        )
        assert confirm_resp.status_code == 200
        confirmed = confirm_resp.json()
        assert confirmed["status"] == "CONFIRMED"
        assert confirmed["amount_paid"] == 75.0
        assert confirmed["reservation_code"].startswith("SPT-")

        # 5. Cancelar reserva -> CANCELLED con reembolso
        cancel_resp = self.client.put(
            f"/reservations/{reservation_id}/cancel",
            headers=headers,
        )
        assert cancel_resp.status_code == 200
        cancelled = cancel_resp.json()
        assert cancelled["status"] == "CANCELLED"
        assert cancelled["cancelled_at"] is not None
        assert cancelled["refund_amount"] is not None
        # Como es hoy y faltan > 4h, el reembolso debe ser completo
        assert cancelled["refund_amount"] == 75.0
