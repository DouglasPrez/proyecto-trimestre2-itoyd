from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import List, Optional

from ..database import get_db
from .. import models, schemas

router = APIRouter(prefix="/availability", tags=["availability"])


def expire_pending(db: Session):
    now = datetime.utcnow()
    db.query(models.Reservation).filter(
        models.Reservation.status == models.ReservationStatus.PENDING,
        models.Reservation.expires_at < now,
    ).update({"status": models.ReservationStatus.EXPIRED})
    db.commit()


def build_slots(space: models.Space, date_str: str, db: Session) -> List[schemas.TimeSlot]:
    expire_pending(db)

    date = datetime.strptime(date_str, "%Y-%m-%d").date()

    oh, om = map(int, space.open_time.split(":"))
    ch, cm = map(int, space.close_time.split(":"))
    slot_start = datetime(date.year, date.month, date.day, oh, om)
    close_dt = datetime(date.year, date.month, date.day, ch, cm)
    slot_duration = timedelta(minutes=space.duration_minutes)
    cleaning = timedelta(minutes=space.cleaning_minutes)

    day_start = datetime(date.year, date.month, date.day)
    day_end = day_start + timedelta(days=1)

    reservations = (
        db.query(models.Reservation)
        .filter(
            models.Reservation.space_id == space.id,
            models.Reservation.start_time < day_end,
            models.Reservation.end_time > day_start,
            models.Reservation.status.in_(
                [models.ReservationStatus.CONFIRMED, models.ReservationStatus.PENDING]
            ),
        )
        .all()
    )

    blocks = (
        db.query(models.Block)
        .filter(
            models.Block.space_id == space.id,
            models.Block.start_time < day_end,
            models.Block.end_time > day_start,
        )
        .all()
    )

    slots: List[schemas.TimeSlot] = []
    current = slot_start

    while current + slot_duration <= close_dt:
        slot_end = current + slot_duration
        status = "available"
        reservation_code = None
        reservation_id = None

        for block in blocks:
            if block.start_time < slot_end and block.end_time > current:
                status = "blocked"
                break

        if status == "available":
            for res in reservations:
                effective_end = res.end_time + cleaning
                if res.start_time < slot_end and effective_end > current:
                    status = (
                        "reserved"
                        if res.status == models.ReservationStatus.CONFIRMED
                        else "pending"
                    )
                    reservation_code = res.reservation_code
                    reservation_id = res.id
                    break

        slots.append(
            schemas.TimeSlot(
                start=current.strftime("%H:%M"),
                end=slot_end.strftime("%H:%M"),
                start_dt=current,
                end_dt=slot_end,
                status=status,
                reservation_code=reservation_code,
                reservation_id=reservation_id,
            )
        )
        current += slot_duration

    return slots


@router.get("/search", response_model=List[schemas.SpaceAvailability])
def search_availability(
    date: str = Query(..., description="YYYY-MM-DD"),
    sport: Optional[str] = Query(None),
    zone: Optional[str] = Query(None),
    complex_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
):
    try:
        datetime.strptime(date, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use YYYY-MM-DD")

    query = db.query(models.Space).join(models.Complex).filter(models.Space.is_active == True)

    if sport:
        query = query.filter(models.Space.sport_type.ilike(f"%{sport}%"))
    if zone:
        query = query.filter(models.Complex.zone.ilike(f"%{zone}%"))
    if complex_id:
        query = query.filter(models.Space.complex_id == complex_id)

    spaces = query.all()
    result = []

    for space in spaces:
        slots = build_slots(space, date, db)
        has_available = any(s.status == "available" for s in slots)
        if has_available or complex_id:
            result.append(
                schemas.SpaceAvailability(
                    space_id=space.id,
                    space_name=space.name,
                    sport_type=space.sport_type,
                    complex_id=space.complex_id,
                    complex_name=space.complex.name,
                    zone=space.complex.zone,
                    date=date,
                    price_per_hour=space.price_per_hour,
                    duration_minutes=space.duration_minutes,
                    slots=slots,
                )
            )

    return result


@router.get("/{space_id}/{date}", response_model=schemas.SpaceAvailability)
def get_space_availability(space_id: int, date: str, db: Session = Depends(get_db)):
    try:
        datetime.strptime(date, "%Y-%m-%d")
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido")

    space = db.query(models.Space).filter(models.Space.id == space_id, models.Space.is_active == True).first()
    if not space:
        raise HTTPException(status_code=404, detail="Espacio no encontrado")

    slots = build_slots(space, date, db)
    return schemas.SpaceAvailability(
        space_id=space.id,
        space_name=space.name,
        sport_type=space.sport_type,
        complex_id=space.complex_id,
        complex_name=space.complex.name,
        zone=space.complex.zone,
        date=date,
        price_per_hour=space.price_per_hour,
        duration_minutes=space.duration_minutes,
        slots=slots,
    )
