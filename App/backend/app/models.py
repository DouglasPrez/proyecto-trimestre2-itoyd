from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, Enum as SAEnum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

from .database import Base


class UserRole(str, enum.Enum):
    USER = "USER"
    ADMIN = "ADMIN"


class ReservationStatus(str, enum.Enum):
    PENDING = "PENDING"
    CONFIRMED = "CONFIRMED"
    CANCELLED = "CANCELLED"
    EXPIRED = "EXPIRED"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(SAEnum(UserRole), default=UserRole.USER, nullable=False)
    complex_id = Column(Integer, ForeignKey("complexes.id"), nullable=True)

    reservations = relationship("Reservation", back_populates="user")
    managed_complex = relationship(
        "Complex", back_populates="admins", foreign_keys=[complex_id]
    )


class Complex(Base):
    __tablename__ = "complexes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    zone = Column(String, nullable=False)
    address = Column(String, nullable=True)

    spaces = relationship("Space", back_populates="complex")
    admins = relationship(
        "User", back_populates="managed_complex", foreign_keys="User.complex_id"
    )


class Space(Base):
    __tablename__ = "spaces"

    id = Column(Integer, primary_key=True, index=True)
    complex_id = Column(Integer, ForeignKey("complexes.id"), nullable=False)
    name = Column(String, nullable=False)
    sport_type = Column(String, nullable=False)
    duration_minutes = Column(Integer, default=60)
    cleaning_minutes = Column(Integer, default=15)
    price_per_hour = Column(Float, nullable=False)
    open_time = Column(String, default="07:00")
    close_time = Column(String, default="22:00")
    is_active = Column(Boolean, default=True)
    cancel_free_hours = Column(Integer, default=4)
    cancel_penalty_pct = Column(Integer, default=50)
    cancel_no_refund_hours = Column(Integer, default=1)

    complex = relationship("Complex", back_populates="spaces")
    reservations = relationship("Reservation", back_populates="space")
    blocks = relationship("Block", back_populates="space")


class Reservation(Base):
    __tablename__ = "reservations"

    id = Column(Integer, primary_key=True, index=True)
    reservation_code = Column(String, unique=True, index=True, nullable=True)
    space_id = Column(Integer, ForeignKey("spaces.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    status = Column(SAEnum(ReservationStatus), default=ReservationStatus.PENDING, nullable=False)
    amount_paid = Column(Float, nullable=True)
    payment_method_last4 = Column(String, nullable=True)
    expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    cancelled_at = Column(DateTime, nullable=True)
    refund_amount = Column(Float, nullable=True)

    space = relationship("Space", back_populates="reservations")
    user = relationship("User", back_populates="reservations")


class Block(Base):
    __tablename__ = "blocks"

    id = Column(Integer, primary_key=True, index=True)
    space_id = Column(Integer, ForeignKey("spaces.id"), nullable=False)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    reason = Column(String, default="Mantenimiento")
    is_recurring = Column(Boolean, default=False)
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    space = relationship("Space", back_populates="blocks")
