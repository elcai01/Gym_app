from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.plantilla_mensaje import PlantillaMensaje
from app.schemas.plantilla_mensaje import PlantillaMensajeCreate, PlantillaMensajeResponse

router = APIRouter(prefix="/plantillas", tags=["Plantillas de Mensajes"])

@router.get("/", response_model=List[PlantillaMensajeResponse])
def listar_plantillas(db: Session = Depends(get_db)):
    from app.services.scheduler_service import DEFAULT_TEMPLATES
    modificado = False
    for k, v in DEFAULT_TEMPLATES.items():
        existe = db.query(PlantillaMensaje).filter(PlantillaMensaje.codigo == k).first()
        if not existe:
            db.add(PlantillaMensaje(codigo=k, nombre=k.replace("_", " ").title(), contenido=v))
            modificado = True
    if modificado:
        db.commit()
    return db.query(PlantillaMensaje).all()

@router.post("/", response_model=PlantillaMensajeResponse)
def crear_o_actualizar_plantilla(datos: PlantillaMensajeCreate, db: Session = Depends(get_db)):
    plantilla = db.query(PlantillaMensaje).filter(PlantillaMensaje.codigo == datos.codigo).first()
    if plantilla:
        plantilla.nombre = datos.nombre
        plantilla.contenido = datos.contenido
    else:
        plantilla = PlantillaMensaje(**datos.model_dump())
        db.add(plantilla)
    db.commit()
    db.refresh(plantilla)
    return plantilla

@router.delete("/{plantilla_id}")
def eliminar_plantilla(plantilla_id: int, db: Session = Depends(get_db)):
    plantilla = db.query(PlantillaMensaje).filter(PlantillaMensaje.id == plantilla_id).first()
    if not plantilla:
        raise HTTPException(status_code=404, detail="Plantilla no encontrada")
    db.delete(plantilla)
    db.commit()
    return {"mensaje": "Plantilla eliminada correctamente"}
