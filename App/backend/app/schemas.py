from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional, List

from .models import UserRole, ReservationStatus


# ── Auth ────────────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    email: str
    name: str
    password: str


class UserLogin(BaseModel):
    email: str
    password: str


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    email: str
    name: str
    role: UserRole
    complex_id: Optional[int] = None


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


# ── Complex ──────────────────────────────────────────────────────────────────

class ComplexResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    zone: str
    address: Optional[str] = None


# ── Space ────────────────────────────────────────────────────────────────────

class SpaceBase(BaseModel):
    name: str
    sport_type: str
    duration_minutes: int = 60
    cleaning_minutes: int = 15
    price_per_hour: float
    open_time: str = "07:00"
    close_time: str = "22:00"
    cancel_free_hours: int = 4
    cancel_penalty_pct: int = 50
    cancel_no_refund_hours: int = 1


class SpaceCreate(SpaceBase):
    complex_id: int


class SpaceUpdate(SpaceBase):
    pass


class SpaceResponse(SpaceBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    complex_id: int
    is_active: bool


# ── Availability ─────────────────────────────────────────────────────────────

class TimeSlot(BaseModel):
    start: str
    end: str
    start_dt: datetime
    end_dt: datetime
    status: str  # available | reserved | pending | blocked
    reservation_code: Optional[str] = None
    reservation_id: Optional[int] = None


class SpaceAvailability(BaseModel):
    space_id: int
    space_name: str
    sport_type: str
    complex_id: int
    complex_name: str
    zone: str
    date: str
    price_per_hour: float
    duration_minutes: int
    slots: List[TimeSlot]


# ── Reservation ───────────────────────────────────────────────────────────────

class ReservationCreate(BaseModel):
    space_id: int
    start_time: datetime


class ReservationConfirm(BaseModel):
    payment_method_last4: str


class ReservationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    reservation_code: Optional[str] = None
    space_id: int
    user_id: int
    start_time: datetime
    end_time: datetime
    status: ReservationStatus
    amount_paid: Optional[float] = None
    payment_method_last4: Optional[str] = None
    expires_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    refund_amount: Optional[float] = None
    space: Optional[SpaceResponse] = None
    user: Optional[UserResponse] = None


# ── Block ─────────────────────────────────────────────────────────────────────

class BlockCreate(BaseModel):
    space_id: int
    start_time: datetime
    end_time: datetime
    reason: str = "Mantenimiento"
    is_recurring: bool = False


class BlockResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    space_id: int
    start_time: datetime
    end_time: datetime
    reason: str
    is_recurring: bool


# ── Admin Agenda ──────────────────────────────────────────────────────────────

class AgendaSlot(BaseModel):
    start: str
    end: str
    start_dt: datetime
    end_dt: datetime
    status: str
    user_name: Optional[str] = None
    reservation_code: Optional[str] = None
    reservation_id: Optional[int] = None
    block_reason: Optional[str] = None
    block_id: Optional[int] = None


class SpaceAgenda(BaseModel):
    space: SpaceResponse
    slots: List[AgendaSlot]


class DayAgenda(BaseModel):
    date: str
    complex: ComplexResponse
    spaces: List[SpaceAgenda]


# ── Report ────────────────────────────────────────────────────────────────────

class SpaceUtilization(BaseModel):
    space_id: int
    space_name: str
    sport_type: str
    total_slots: int
    reserved_slots: int
    occupancy_pct: float


class MonthlyReport(BaseModel):
    complex_id: int
    complex_name: str
    year: int
    month: int
    spaces: List[SpaceUtilization]
