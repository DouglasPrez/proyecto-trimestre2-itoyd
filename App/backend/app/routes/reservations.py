from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import List

from ..database import get_db
from .. import models, schemas
from ..auth import get_current_user
from ..aws.s3 import upload_voucher, get_voucher_presigned_url
from ..aws.voucher import build_voucher_html

router = APIRouter(prefix="/reservations", tags=["reservations"])

LOCK_MINUTES = 15


def _expire_pending(db: Session):
    now = datetime.utcnow()
    db.query(models.Reservation).filter(
        models.Reservation.status == models.ReservationStatus.PENDING,
        models.Reservation.expires_at < now,
    ).update({"status": models.ReservationStatus.EXPIRED})
    db.commit()


def _calc_refund(space: models.Space, reservation: models.Reservation) -> float:
    now = datetime.utcnow()
    hours_until = (reservation.start_time - now).total_seconds() / 3600

    if hours_until >= space.cancel_free_hours:
        return reservation.amount_paid or 0.0
    elif hours_until >= space.cancel_no_refund_hours:
        pct = (100 - space.cancel_penalty_pct) / 100
        return round((reservation.amount_paid or 0.0) * pct, 2)
    else:
        return 0.0


@router.post("", response_model=schemas.ReservationResponse, status_code=201)
def create_reservation(
    body: schemas.ReservationCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _expire_pending(db)

    space = db.query(models.Space).filter(
        models.Space.id == body.space_id, models.Space.is_active == True
    ).first()
    if not space:
        raise HTTPException(status_code=404, detail="Espacio no encontrado")

    slot_end = body.start_time + timedelta(minutes=space.duration_minutes)
    cleaning = timedelta(minutes=space.cleaning_minutes)

    conflict = (
        db.query(models.Reservation)
        .filter(
            models.Reservation.space_id == body.space_id,
            models.Reservation.status.in_(
                [models.ReservationStatus.CONFIRMED, models.ReservationStatus.PENDING]
            ),
            models.Reservation.start_time < slot_end + cleaning,
            models.Reservation.end_time + cleaning > body.start_time,
        )
        .first()
    )
    if conflict:
        raise HTTPException(status_code=409, detail="El espacio ya está ocupado en ese horario")

    block_conflict = (
        db.query(models.Block)
        .filter(
            models.Block.space_id == body.space_id,
            models.Block.start_time < slot_end,
            models.Block.end_time > body.start_time,
        )
        .first()
    )
    if block_conflict:
        raise HTTPException(status_code=409, detail="El espacio está bloqueado en ese horario")

    now = datetime.utcnow()
    reservation = models.Reservation(
        space_id=body.space_id,
        user_id=current_user.id,
        start_time=body.start_time,
        end_time=slot_end,
        status=models.ReservationStatus.PENDING,
        expires_at=now + timedelta(minutes=LOCK_MINUTES),
        created_at=now,
    )
    db.add(reservation)
    db.commit()
    db.refresh(reservation)

    # Generate code after we have the ID
    reservation.reservation_code = f"SPT-{body.start_time.year}-{reservation.id:06d}"
    db.commit()
    db.refresh(reservation)

    return reservation


@router.get("/me", response_model=List[schemas.ReservationResponse])
def my_reservations(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _expire_pending(db)
    reservations = (
        db.query(models.Reservation)
        .filter(models.Reservation.user_id == current_user.id)
        .order_by(models.Reservation.start_time.desc())
        .all()
    )
    return reservations


@router.get("/{reservation_id}", response_model=schemas.ReservationResponse)
def get_reservation(
    reservation_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _expire_pending(db)
    reservation = db.query(models.Reservation).filter(
        models.Reservation.id == reservation_id
    ).first()
    if not reservation:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")
    if reservation.user_id != current_user.id and current_user.role != models.UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Sin permiso")
    return reservation


@router.put("/{reservation_id}/confirm", response_model=schemas.ReservationResponse)
def confirm_reservation(
    reservation_id: int,
    body: schemas.ReservationConfirm,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    _expire_pending(db)
    reservation = db.query(models.Reservation).filter(
        models.Reservation.id == reservation_id
    ).first()
    if not reservation:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")
    if reservation.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Sin permiso")
    if reservation.status != models.ReservationStatus.PENDING:
        raise HTTPException(status_code=400, detail=f"La reserva está en estado {reservation.status}")

    space = reservation.space
    hours = space.duration_minutes / 60
    amount = round(space.price_per_hour * hours, 2)

    reservation.status = models.ReservationStatus.CONFIRMED
    reservation.payment_method_last4 = body.payment_method_last4
    reservation.amount_paid = amount
    reservation.expires_at = None
    db.commit()
    db.refresh(reservation)

    html = build_voucher_html(
        reservation_code=reservation.reservation_code,
        space_name=space.name,
        complex_name=space.complex.name,
        sport_type=space.sport_type,
        start_time=reservation.start_time,
        end_time=reservation.end_time,
        amount_paid=amount,
        payment_last4=body.payment_method_last4,
        user_email=current_user.email,
    )
    upload_voucher(reservation.reservation_code, html)

    return reservation


@router.put("/{reservation_id}/cancel", response_model=schemas.ReservationResponse)
def cancel_reservation(
    reservation_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    reservation = db.query(models.Reservation).filter(
        models.Reservation.id == reservation_id
    ).first()
    if not reservation:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")
    if reservation.user_id != current_user.id and current_user.role != models.UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Sin permiso")
    if reservation.status not in (
        models.ReservationStatus.CONFIRMED, models.ReservationStatus.PENDING
    ):
        raise HTTPException(status_code=400, detail="La reserva no puede cancelarse")

    refund = _calc_refund(reservation.space, reservation) if reservation.status == models.ReservationStatus.CONFIRMED else 0.0

    reservation.status = models.ReservationStatus.CANCELLED
    reservation.cancelled_at = datetime.utcnow()
    reservation.refund_amount = refund
    db.commit()
    db.refresh(reservation)
    return reservation


@router.get("/{reservation_id}/voucher")
def get_voucher(
    reservation_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    reservation = db.query(models.Reservation).filter(
        models.Reservation.id == reservation_id
    ).first()
    if not reservation:
        raise HTTPException(status_code=404, detail="Reserva no encontrada")
    if reservation.user_id != current_user.id and current_user.role != models.UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Sin permiso")
    if reservation.status != models.ReservationStatus.CONFIRMED:
        raise HTTPException(status_code=400, detail="El comprobante solo está disponible para reservas confirmadas")
    if not reservation.reservation_code:
        raise HTTPException(status_code=404, detail="Código de reserva no disponible")

    url = get_voucher_presigned_url(reservation.reservation_code)
    if not url:
        raise HTTPException(status_code=404, detail="Comprobante no disponible (S3 no configurado o no encontrado)")

    return JSONResponse({"voucher_url": url})
