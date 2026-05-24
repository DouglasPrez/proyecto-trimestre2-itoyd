from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List

from .database import engine, Base, get_db
from .routes import auth, availability, reservations, admin
from . import models, schemas  # noqa: F401

Base.metadata.create_all(bind=engine)

app = FastAPI(title="SportSpace API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(availability.router)
app.include_router(reservations.router)
app.include_router(admin.router)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/complexes", response_model=List[schemas.ComplexResponse])
def list_complexes(db: Session = Depends(get_db)):
    return db.query(models.Complex).all()
