from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import List
import calendar

from ..database import get_db
from .. import models, schemas
from ..auth import require_admin

router = APIRouter(prefix="/admin", tags=["admin"])


# ── Spaces ────────────────────────────────────────────────────────────────────

@router.get("/spaces", response_model=List[schemas.SpaceResponse])
def list_spaces(
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    return (
        db.query(models.Space)
        .filter(models.Space.complex_id == current_user.complex_id)
        .all()
    )


@router.get("/spaces/{space_id}", response_model=schemas.SpaceResponse)
def get_space(
    space_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    space = db.query(models.Space).filter(models.Space.id == space_id).first()
    if not space or space.complex_id != current_user.complex_id:
        raise HTTPException(status_code=404, detail="Espacio no encontrado")
    return space


@router.post("/spaces", response_model=schemas.SpaceResponse, status_code=201)
def create_space(
    body: schemas.SpaceCreate,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    if body.complex_id != current_user.complex_id:
        raise HTTPException(status_code=403, detail="Solo puedes gestionar tu propio complejo")
    space = models.Space(**body.model_dump())
    db.add(space)
    db.commit()
    db.refresh(space)
    return space


@router.put("/spaces/{space_id}", response_model=schemas.SpaceResponse)
def update_space(
    space_id: int,
    body: schemas.SpaceUpdate,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    space = db.query(models.Space).filter(models.Space.id == space_id).first()
    if not space:
        raise HTTPException(status_code=404, detail="Espacio no encontrado")
    if space.complex_id != current_user.complex_id:
        raise HTTPException(status_code=403, detail="Sin permiso")

    for field, value in body.model_dump().items():
        setattr(space, field, value)
    db.commit()
    db.refresh(space)
    return space


@router.delete("/spaces/{space_id}")
def deactivate_space(
    space_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    space = db.query(models.Space).filter(models.Space.id == space_id).first()
    if not space or space.complex_id != current_user.complex_id:
        raise HTTPException(status_code=404, detail="Espacio no encontrado")
    space.is_active = False
    db.commit()
    return {"message": "Espacio desactivado"}


# ── Blocks ────────────────────────────────────────────────────────────────────

@router.post("/blocks", response_model=schemas.BlockResponse, status_code=201)
def create_block(
    body: schemas.BlockCreate,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    space = db.query(models.Space).filter(models.Space.id == body.space_id).first()
    if not space or space.complex_id != current_user.complex_id:
        raise HTTPException(status_code=403, detail="Sin permiso sobre ese espacio")

    block = models.Block(
        space_id=body.space_id,
        start_time=body.start_time,
        end_time=body.end_time,
        reason=body.reason,
        is_recurring=body.is_recurring,
        created_by_id=current_user.id,
    )
    db.add(block)
    db.commit()
    db.refresh(block)
    return block


@router.delete("/blocks/{block_id}")
def delete_block(
    block_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    block = db.query(models.Block).filter(models.Block.id == block_id).first()
    if not block:
        raise HTTPException(status_code=404, detail="Bloqueo no encontrado")
    if block.space.complex_id != current_user.complex_id:
        raise HTTPException(status_code=403, detail="Sin permiso")
    db.delete(block)
    db.commit()
    return {"message": "Bloqueo eliminado"}


# ── Agenda ────────────────────────────────────────────────────────────────────

@router.get("/agenda/{complex_id}/{date}", response_model=schemas.DayAgenda)
def get_agenda(
    complex_id: int,
    date: str,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    if current_user.complex_id != complex_id:
        raise HTTPException(status_code=403, detail="Sin permiso sobre ese complejo")

    complex_ = db.query(models.Complex).filter(models.Complex.id == complex_id).first()
    if not complex_:
        raise HTTPException(status_code=404, detail="Complejo no encontrado")

    try:
        parsed_date = datetime.strptime(date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido")

    spaces = (
        db.query(models.Space)
        .filter(models.Space.complex_id == complex_id, models.Space.is_active == True)
        .all()
    )

    # Expire pending reservations first
    now = datetime.utcnow()
    db.query(models.Reservation).filter(
        models.Reservation.status == models.ReservationStatus.PENDING,
        models.Reservation.expires_at < now,
    ).update({"status": models.ReservationStatus.EXPIRED})
    db.commit()

    space_agendas = []
    day_start = datetime(parsed_date.year, parsed_date.month, parsed_date.day)
    day_end = day_start + timedelta(days=1)

    for space in spaces:
        oh, om = map(int, space.open_time.split(":"))
        ch, cm = map(int, space.close_time.split(":"))
        slot_start = datetime(parsed_date.year, parsed_date.month, parsed_date.day, oh, om)
        close_dt = datetime(parsed_date.year, parsed_date.month, parsed_date.day, ch, cm)
        slot_duration = timedelta(minutes=space.duration_minutes)
        cleaning = timedelta(minutes=space.cleaning_minutes)

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

        slots: List[schemas.AgendaSlot] = []
        current = slot_start

        while current + slot_duration <= close_dt:
            slot_end = current + slot_duration
            status = "available"
            user_name = None
            reservation_code = None
            reservation_id = None
            block_reason = None
            block_id = None

            for blk in blocks:
                if blk.start_time < slot_end and blk.end_time > current:
                    status = "blocked"
                    block_reason = blk.reason
                    block_id = blk.id
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
                        user_name = res.user.name if res.user else None
                        reservation_code = res.reservation_code
                        reservation_id = res.id
                        break

            slots.append(
                schemas.AgendaSlot(
                    start=current.strftime("%H:%M"),
                    end=slot_end.strftime("%H:%M"),
                    start_dt=current,
                    end_dt=slot_end,
                    status=status,
                    user_name=user_name,
                    reservation_code=reservation_code,
                    reservation_id=reservation_id,
                    block_reason=block_reason,
                    block_id=block_id,
                )
            )
            current += slot_duration

        space_agendas.append(
            schemas.SpaceAgenda(
                space=schemas.SpaceResponse.model_validate(space),
                slots=slots,
            )
        )

    return schemas.DayAgenda(
        date=date,
        complex=schemas.ComplexResponse.model_validate(complex_),
        spaces=space_agendas,
    )


# ── Monthly Report ────────────────────────────────────────────────────────────

@router.get("/report/{complex_id}/{year}/{month}", response_model=schemas.MonthlyReport)
def monthly_report(
    complex_id: int,
    year: int,
    month: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    if current_user.complex_id != complex_id:
        raise HTTPException(status_code=403, detail="Sin permiso")

    complex_ = db.query(models.Complex).filter(models.Complex.id == complex_id).first()
    if not complex_:
        raise HTTPException(status_code=404, detail="Complejo no encontrado")

    spaces = (
        db.query(models.Space)
        .filter(models.Space.complex_id == complex_id, models.Space.is_active == True)
        .all()
    )

    _, days_in_month = calendar.monthrange(year, month)
    month_start = datetime(year, month, 1)
    month_end = datetime(year, month, days_in_month, 23, 59, 59)

    result = []
    for space in spaces:
        oh, om = map(int, space.open_time.split(":"))
        ch, cm = map(int, space.close_time.split(":"))
        open_minutes = oh * 60 + om
        close_minutes = ch * 60 + cm
        slots_per_day = (close_minutes - open_minutes) // space.duration_minutes
        total_slots = slots_per_day * days_in_month

        reserved_count = (
            db.query(models.Reservation)
            .filter(
                models.Reservation.space_id == space.id,
                models.Reservation.status == models.ReservationStatus.CONFIRMED,
                models.Reservation.start_time >= month_start,
                models.Reservation.start_time <= month_end,
            )
            .count()
        )

        occupancy = round(reserved_count / total_slots * 100, 1) if total_slots > 0 else 0.0
        result.append(
            schemas.SpaceUtilization(
                space_id=space.id,
                space_name=space.name,
                sport_type=space.sport_type,
                total_slots=total_slots,
                reserved_slots=reserved_count,
                occupancy_pct=occupancy,
            )
        )

    return schemas.MonthlyReport(
        complex_id=complex_id,
        complex_name=complex_.name,
        year=year,
        month=month,
        spaces=result,
    )


# ── Complexes list ────────────────────────────────────────────────────────────

@router.get("/complexes", response_model=List[schemas.ComplexResponse])
def list_complexes(
    _: models.User = Depends(require_admin),
    db: Session = Depends(get_db),
):
    return db.query(models.Complex).all()
