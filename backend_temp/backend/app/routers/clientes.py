from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.cliente import Cliente
from app.models.usuario import Usuario
from app.models.membresia import Membresia
from app.models.pago import Pago
from app.models.asistencia import Asistencia
from app.models.evaluacion_fisica import EvaluacionFisica
from app.models.rutina import ClienteRutina, ClienteRutinaProgreso
from app.schemas.cliente import ClienteCreate, ClienteResponse, ClienteUpdate

router = APIRouter(prefix="/clientes", tags=["Clientes"])


def _normalize_email(value):
    if value is None:
        return None
    value = str(value).strip()
    if not value or value == "0" or "@" not in value:
        return None
    return value


def _sanitize_cliente_output(cliente: Cliente) -> Cliente:
    cliente.email = _normalize_email(cliente.email)
    return cliente


@router.post("/", response_model=ClienteResponse)
def crear_cliente(cliente: ClienteCreate, db: Session = Depends(get_db)):
    existente = db.query(Cliente).filter(Cliente.documento == cliente.documento).first()
    if existente:
        raise HTTPException(status_code=400, detail="Ya existe un cliente con ese documento")

    payload = cliente.model_dump()
    payload["email"] = _normalize_email(payload.get("email"))
    nuevo_cliente = Cliente(**payload)
    db.add(nuevo_cliente)
    db.commit()
    db.refresh(nuevo_cliente)
    return _sanitize_cliente_output(nuevo_cliente)


@router.get("/", response_model=List[ClienteResponse])
def listar_clientes(db: Session = Depends(get_db)):
    clientes = db.query(Cliente).order_by(Cliente.id.desc()).all()
    return [_sanitize_cliente_output(c) for c in clientes]


@router.get("/por-cedula/{cedula}", response_model=ClienteResponse)
def obtener_cliente_por_cedula(cedula: str, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.documento == cedula).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return _sanitize_cliente_output(cliente)


@router.get("/{cliente_id}", response_model=ClienteResponse)
def obtener_cliente(cliente_id: int, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return _sanitize_cliente_output(cliente)


@router.put("/{cliente_id}", response_model=ClienteResponse)
def actualizar_cliente(cliente_id: int, datos: ClienteUpdate, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    update_data = datos.model_dump(exclude_unset=True)
    if "email" in update_data:
        update_data["email"] = _normalize_email(update_data.get("email"))

    for campo, valor in update_data.items():
        setattr(cliente, campo, valor)

    db.commit()
    db.refresh(cliente)
    return _sanitize_cliente_output(cliente)


@router.delete("/{cliente_id}/eliminar-completo")
def eliminar_cliente_completo(cliente_id: int, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    try:
        cliente_rutinas_ids = [
            row[0]
            for row in db.query(ClienteRutina.id)
            .filter(ClienteRutina.cliente_id == cliente_id)
            .all()
        ]

        if cliente_rutinas_ids:
            db.query(ClienteRutinaProgreso).filter(
                ClienteRutinaProgreso.cliente_rutina_id.in_(cliente_rutinas_ids)
            ).delete(synchronize_session=False)

        db.query(ClienteRutina).filter(
            ClienteRutina.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.query(EvaluacionFisica).filter(
            EvaluacionFisica.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.query(Asistencia).filter(
            Asistencia.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.query(Pago).filter(
            Pago.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.query(Membresia).filter(
            Membresia.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.query(Usuario).filter(
            Usuario.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.delete(cliente)
        db.commit()
        return {
            "ok": True,
            "mensaje": "Cliente eliminado definitivamente",
            "cliente_id": cliente_id,
            "documento": cliente.documento,
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error eliminando cliente: {e}")


@router.delete("/{cliente_id}")
def eliminar_cliente(cliente_id: int, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    db.delete(cliente)
    db.commit()
    return {"mensaje": "Cliente eliminado correctamente"}

@router.delete("/por-cedula/{cedula}/eliminar-completo")
def eliminar_cliente_completo_por_cedula(cedula: str, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.documento == cedula).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    cliente_id = cliente.id

    try:
        cliente_rutinas_ids = [
            row[0]
            for row in db.query(ClienteRutina.id)
            .filter(ClienteRutina.cliente_id == cliente_id)
            .all()
        ]

        if cliente_rutinas_ids:
            db.query(ClienteRutinaProgreso).filter(
                ClienteRutinaProgreso.cliente_rutina_id.in_(cliente_rutinas_ids)
            ).delete(synchronize_session=False)

        db.query(ClienteRutina).filter(
            ClienteRutina.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.query(EvaluacionFisica).filter(
            EvaluacionFisica.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.query(Asistencia).filter(
            Asistencia.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.query(Pago).filter(
            Pago.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.query(Membresia).filter(
            Membresia.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.query(Usuario).filter(
            Usuario.cliente_id == cliente_id
        ).delete(synchronize_session=False)

        db.delete(cliente)
        db.commit()

        return {
            "ok": True,
            "mensaje": "Cliente eliminado definitivamente",
            "cliente_id": cliente_id,
            "documento": cedula,
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error eliminando cliente: {e}")