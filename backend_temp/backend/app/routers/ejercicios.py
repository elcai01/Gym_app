from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.ejercicio import Ejercicio
from app.schemas.ejercicio import EjercicioCreate, EjercicioResponse, EjercicioUpdate

router = APIRouter(prefix="/ejercicios", tags=["Ejercicios"])


@router.post("/", response_model=EjercicioResponse)
def crear_ejercicio(datos: EjercicioCreate, db: Session = Depends(get_db)):
    nuevo = Ejercicio(**datos.model_dump())
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


@router.get("/", response_model=List[EjercicioResponse])
def listar_ejercicios(db: Session = Depends(get_db)):
    return db.query(Ejercicio).order_by(Ejercicio.id.desc()).all()


@router.get("/{ejercicio_id}", response_model=EjercicioResponse)
def obtener_ejercicio(ejercicio_id: int, db: Session = Depends(get_db)):
    ejercicio = db.query(Ejercicio).filter(Ejercicio.id == ejercicio_id).first()
    if not ejercicio:
        raise HTTPException(status_code=404, detail="Ejercicio no encontrado")
    return ejercicio


@router.put("/{ejercicio_id}", response_model=EjercicioResponse)
def actualizar_ejercicio(ejercicio_id: int, datos: EjercicioUpdate, db: Session = Depends(get_db)):
    ejercicio = db.query(Ejercicio).filter(Ejercicio.id == ejercicio_id).first()
    if not ejercicio:
        raise HTTPException(status_code=404, detail="Ejercicio no encontrado")

    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(ejercicio, campo, valor)

    db.commit()
    db.refresh(ejercicio)
    return ejercicio


@router.delete("/{ejercicio_id}")
def eliminar_ejercicio(ejercicio_id: int, db: Session = Depends(get_db)):
    ejercicio = db.query(Ejercicio).filter(Ejercicio.id == ejercicio_id).first()
    if not ejercicio:
        raise HTTPException(status_code=404, detail="Ejercicio no encontrado")

    db.delete(ejercicio)
    db.commit()
    return {"mensaje": "Ejercicio eliminado correctamente"}
