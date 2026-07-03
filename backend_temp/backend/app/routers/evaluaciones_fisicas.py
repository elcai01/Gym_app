from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.evaluacion_fisica import EvaluacionFisica
from app.models.cliente import Cliente
from app.schemas.evaluacion_fisica import EvaluacionFisicaCreate, EvaluacionFisicaResponse, EvaluacionFisicaUpdate

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
def listar_evaluaciones(cliente_id: Optional[int] = Query(default=None), db: Session = Depends(get_db)):
    query = db.query(EvaluacionFisica)
    if cliente_id is not None:
        query = query.filter(EvaluacionFisica.cliente_id == cliente_id)
    return query.order_by(EvaluacionFisica.fecha_evaluacion.desc(), EvaluacionFisica.id.desc()).all()


@router.get("/cliente-cedula/{cedula}")
def obtener_medidas_por_cedula(cedula: str, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.documento == cedula).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    historial = (
        db.query(EvaluacionFisica)
        .filter(EvaluacionFisica.cliente_id == cliente.id)
        .order_by(EvaluacionFisica.fecha_evaluacion.desc(), EvaluacionFisica.id.desc())
        .all()
    )

    return {
        "cliente": {
            "id": cliente.id,
            "documento": cliente.documento,
            "nombres": cliente.nombres,
            "apellidos": cliente.apellidos,
            "telefono": cliente.telefono,
            "whatsapp": cliente.whatsapp,
            "estado": cliente.estado,
        },
        "historial": [EvaluacionFisicaResponse.model_validate(item).model_dump(mode="json") for item in historial],
        "ultima_evaluacion": EvaluacionFisicaResponse.model_validate(historial[0]).model_dump(mode="json") if historial else None,
    }


@router.get("/cliente/{cliente_id}/historial", response_model=List[EvaluacionFisicaResponse])
def historial_por_cliente(cliente_id: int, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return (
        db.query(EvaluacionFisica)
        .filter(EvaluacionFisica.cliente_id == cliente_id)
        .order_by(EvaluacionFisica.fecha_evaluacion.desc(), EvaluacionFisica.id.desc())
        .all()
    )


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

    update_data = datos.model_dump(exclude_unset=True)
    if "cliente_id" in update_data and update_data["cliente_id"] is not None:
        cliente = db.query(Cliente).filter(Cliente.id == update_data["cliente_id"]).first()
        if not cliente:
            raise HTTPException(status_code=404, detail="Cliente no encontrado")

    for campo, valor in update_data.items():
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
