from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.pesaje_bascula import PesajeBascula
from app.models.cliente import Cliente
from app.schemas.pesaje_bascula import PesajeBasculaCreate, PesajeBasculaResponse

router = APIRouter(prefix="/pesajes-bascula", tags=["Pesajes Báscula"])


@router.post("/", response_model=PesajeBasculaResponse)
def registrar_pesaje(datos: PesajeBasculaCreate, db: Session = Depends(get_db)):
    """Registra un nuevo pesaje de báscula para un cliente."""
    cliente = db.query(Cliente).filter(Cliente.id == datos.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    nuevo_pesaje = PesajeBascula(**datos.model_dump())
    db.add(nuevo_pesaje)
    db.commit()
    db.refresh(nuevo_pesaje)
    return nuevo_pesaje


@router.get("/cliente/{cliente_id}", response_model=List[PesajeBasculaResponse])
def historial_por_cliente(cliente_id: int, db: Session = Depends(get_db)):
    """Retorna el historial de pesajes de un cliente, del más reciente al más antiguo."""
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    return (
        db.query(PesajeBascula)
        .filter(PesajeBascula.cliente_id == cliente_id)
        .order_by(PesajeBascula.fecha_pesaje.desc(), PesajeBascula.id.desc())
        .all()
    )


@router.delete("/{pesaje_id}")
def eliminar_pesaje(pesaje_id: int, db: Session = Depends(get_db)):
    """Elimina un registro de pesaje por su ID."""
    pesaje = db.query(PesajeBascula).filter(PesajeBascula.id == pesaje_id).first()
    if not pesaje:
        raise HTTPException(status_code=404, detail="Pesaje no encontrado")
    db.delete(pesaje)
    db.commit()
    return {"mensaje": "Pesaje eliminado correctamente"}
