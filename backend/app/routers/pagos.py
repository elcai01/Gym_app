from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.pago import Pago
from app.models.cliente import Cliente
from app.models.membresia import Membresia
from app.schemas.pago import PagoCreate, PagoResponse, PagoUpdate

router = APIRouter(prefix="/pagos", tags=["Pagos"])


@router.post("/", response_model=PagoResponse)
def crear_pago(pago: PagoCreate, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == pago.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    if pago.membresia_id is not None:
        membresia = db.query(Membresia).filter(Membresia.id == pago.membresia_id).first()
        if not membresia:
            raise HTTPException(status_code=404, detail="Membresía no encontrada")

    nuevo_pago = Pago(
        cliente_id=pago.cliente_id,
        membresia_id=pago.membresia_id,
        usuario_id=pago.usuario_id,
        valor_pagado=pago.valor_pagado,
        descuento=pago.descuento,
        recargo=pago.recargo,
        metodo_pago=pago.metodo_pago,
        referencia=pago.referencia,
        observaciones=pago.observaciones
    )

    db.add(nuevo_pago)
    db.commit()
    db.refresh(nuevo_pago)
    return nuevo_pago


@router.get("/", response_model=List[PagoResponse])
def listar_pagos(db: Session = Depends(get_db)):
    return db.query(Pago).order_by(Pago.id.desc()).all()


@router.get("/{pago_id}", response_model=PagoResponse)
def obtener_pago(pago_id: int, db: Session = Depends(get_db)):
    pago = db.query(Pago).filter(Pago.id == pago_id).first()
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")
    return pago


@router.put("/{pago_id}", response_model=PagoResponse)
def actualizar_pago(pago_id: int, datos: PagoUpdate, db: Session = Depends(get_db)):
    pago = db.query(Pago).filter(Pago.id == pago_id).first()
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")

    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(pago, campo, valor)

    db.commit()
    db.refresh(pago)
    return pago


@router.delete("/{pago_id}")
def eliminar_pago(pago_id: int, db: Session = Depends(get_db)):
    pago = db.query(Pago).filter(Pago.id == pago_id).first()
    if not pago:
        raise HTTPException(status_code=404, detail="Pago no encontrado")

    db.delete(pago)
    db.commit()
    return {"mensaje": "Pago eliminado correctamente"}