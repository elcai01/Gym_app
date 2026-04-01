from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.membresia import Membresia
from app.models.cliente import Cliente
from app.schemas.membresia import MembresiaCreate, MembresiaResponse, MembresiaUpdate

router = APIRouter(prefix="/membresias", tags=["Membresias"])


@router.post("/", response_model=MembresiaResponse)
def crear_membresia(membresia: MembresiaCreate, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == membresia.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    nueva_membresia = Membresia(**membresia.model_dump())
    db.add(nueva_membresia)
    db.commit()
    db.refresh(nueva_membresia)
    return nueva_membresia


@router.get("/", response_model=List[MembresiaResponse])
def listar_membresias(db: Session = Depends(get_db)):
    return db.query(Membresia).order_by(Membresia.id.desc()).all()


@router.get("/{membresia_id}", response_model=MembresiaResponse)
def obtener_membresia(membresia_id: int, db: Session = Depends(get_db)):
    membresia = db.query(Membresia).filter(Membresia.id == membresia_id).first()
    if not membresia:
        raise HTTPException(status_code=404, detail="Membresía no encontrada")
    return membresia


@router.put("/{membresia_id}", response_model=MembresiaResponse)
def actualizar_membresia(membresia_id: int, datos: MembresiaUpdate, db: Session = Depends(get_db)):
    membresia = db.query(Membresia).filter(Membresia.id == membresia_id).first()
    if not membresia:
        raise HTTPException(status_code=404, detail="Membresía no encontrada")

    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(membresia, campo, valor)

    db.commit()
    db.refresh(membresia)
    return membresia


@router.delete("/{membresia_id}")
def eliminar_membresia(membresia_id: int, db: Session = Depends(get_db)):
    membresia = db.query(Membresia).filter(Membresia.id == membresia_id).first()
    if not membresia:
        raise HTTPException(status_code=404, detail="Membresía no encontrada")

    db.delete(membresia)
    db.commit()
    return {"mensaje": "Membresía eliminada correctamente"}