from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.asistencia import Asistencia
from app.models.cliente import Cliente
from app.schemas.asistencia import AsistenciaCreate, AsistenciaResponse, AsistenciaUpdate

router = APIRouter(prefix="/asistencias", tags=["Asistencias"])


@router.post("/", response_model=AsistenciaResponse)
def crear_asistencia(asistencia: AsistenciaCreate, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == asistencia.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    nueva_asistencia = Asistencia(
        cliente_id=asistencia.cliente_id,
        fecha_hora_salida=asistencia.fecha_hora_salida,
        metodo_ingreso=asistencia.metodo_ingreso,
        observaciones=asistencia.observaciones
    )

    db.add(nueva_asistencia)
    db.commit()
    db.refresh(nueva_asistencia)
    return nueva_asistencia


@router.get("/", response_model=List[AsistenciaResponse])
def listar_asistencias(db: Session = Depends(get_db)):
    return db.query(Asistencia).order_by(Asistencia.id.desc()).all()


@router.get("/{asistencia_id}", response_model=AsistenciaResponse)
def obtener_asistencia(asistencia_id: int, db: Session = Depends(get_db)):
    asistencia = db.query(Asistencia).filter(Asistencia.id == asistencia_id).first()
    if not asistencia:
        raise HTTPException(status_code=404, detail="Asistencia no encontrada")
    return asistencia


@router.put("/{asistencia_id}", response_model=AsistenciaResponse)
def actualizar_asistencia(asistencia_id: int, datos: AsistenciaUpdate, db: Session = Depends(get_db)):
    asistencia = db.query(Asistencia).filter(Asistencia.id == asistencia_id).first()
    if not asistencia:
        raise HTTPException(status_code=404, detail="Asistencia no encontrada")

    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(asistencia, campo, valor)

    db.commit()
    db.refresh(asistencia)
    return asistencia


@router.delete("/{asistencia_id}")
def eliminar_asistencia(asistencia_id: int, db: Session = Depends(get_db)):
    asistencia = db.query(Asistencia).filter(Asistencia.id == asistencia_id).first()
    if not asistencia:
        raise HTTPException(status_code=404, detail="Asistencia no encontrada")

    db.delete(asistencia)
    db.commit()
    return {"mensaje": "Asistencia eliminada correctamente"}