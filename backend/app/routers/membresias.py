from datetime import date
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


@router.get("/alertas")
def alertas_membresias(db: Session = Depends(get_db)):
    hoy = date.today()

    membresias = db.query(Membresia).order_by(Membresia.fecha_fin.asc()).all()

    vencidas = []
    vencen_hoy = []
    por_vencer = []

    for m in membresias:
        estado = (m.estado or "").upper()
        if estado == "CANCELADA":
            continue

        cliente = db.query(Cliente).filter(Cliente.id == m.cliente_id).first()
        if not cliente or not m.fecha_fin:
            continue

        dias_restantes = (m.fecha_fin - hoy).days

        item = {
            "membresia_id": m.id,
            "cliente_id": m.cliente_id,
            "plan_id": m.plan_id,
            "fecha_inicio": m.fecha_inicio.isoformat() if m.fecha_inicio else None,
            "fecha_fin": m.fecha_fin.isoformat(),
            "estado": estado,
            "dias_restantes": dias_restantes,
            "documento": cliente.documento,
            "nombre_completo": f"{cliente.nombres} {cliente.apellidos}".strip(),
            "telefono": cliente.telefono,
            "whatsapp": cliente.whatsapp,
        }

        if dias_restantes < 0:
            vencidas.append(item)
        elif dias_restantes == 0:
            vencen_hoy.append(item)
        elif dias_restantes <= 3:
            por_vencer.append(item)

    return {
        "vencidas": vencidas,
        "vencen_hoy": vencen_hoy,
        "por_vencer": por_vencer,
    }


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
