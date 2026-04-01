from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.evaluacion_fisica import EvaluacionFisica
from app.models.cliente import Cliente
from app.schemas.evaluacion_fisica import (
    EvaluacionFisicaCreate,
    EvaluacionFisicaResponse,
    EvaluacionFisicaUpdate,
)

router = APIRouter(prefix="/evaluaciones-fisicas", tags=["Evaluaciones Fisicas"])


@router.post("/", response_model=EvaluacionFisicaResponse)
def crear_evaluacion(datos: EvaluacionFisicaCreate, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == datos.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    nueva_evaluacion = EvaluacionFisica(**datos.model_dump())
    db.add(nueva_evaluacion)
    db.commit()
    db.refresh(nueva_evaluacion)
    return nueva_evaluacion


@router.get("/", response_model=List[EvaluacionFisicaResponse])
def listar_evaluaciones(db: Session = Depends(get_db)):
    return db.query(EvaluacionFisica).order_by(EvaluacionFisica.id.desc()).all()


@router.get("/{evaluacion_id}", response_model=EvaluacionFisicaResponse)
def obtener_evaluacion(evaluacion_id: int, db: Session = Depends(get_db)):
    evaluacion = db.query(EvaluacionFisica).filter(EvaluacionFisica.id == evaluacion_id).first()
    if not evaluacion:
        raise HTTPException(status_code=404, detail="Evaluación no encontrada")
    return evaluacion


@router.put("/{evaluacion_id}", response_model=EvaluacionFisicaResponse)
def actualizar_evaluacion(evaluacion_id: int, datos: EvaluacionFisicaUpdate, db: Session = Depends(get_db)):
    evaluacion = db.query(EvaluacionFisica).filter(EvaluacionFisica.id == evaluacion_id).first()
    if not evaluacion:
        raise HTTPException(status_code=404, detail="Evaluación no encontrada")

    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(evaluacion, campo, valor)

    db.commit()
    db.refresh(evaluacion)
    return evaluacion


@router.delete("/{evaluacion_id}")
def eliminar_evaluacion(evaluacion_id: int, db: Session = Depends(get_db)):
    evaluacion = db.query(EvaluacionFisica).filter(EvaluacionFisica.id == evaluacion_id).first()
    if not evaluacion:
        raise HTTPException(status_code=404, detail="Evaluación no encontrada")

    db.delete(evaluacion)
    db.commit()
    return {"mensaje": "Evaluación eliminada correctamente"}