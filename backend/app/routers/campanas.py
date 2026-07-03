from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.campana_especial import CampanaEspecial
from app.schemas.campana_especial import CampanaEspecialCreate, CampanaEspecialResponse

router = APIRouter(prefix="/campanas", tags=["Campañas Especiales"])

@router.get("/", response_model=List[CampanaEspecialResponse])
def listar_campanas(db: Session = Depends(get_db)):
    return db.query(CampanaEspecial).order_by(CampanaEspecial.id.desc()).all()

@router.post("/", response_model=CampanaEspecialResponse)
def crear_o_actualizar_campana(datos: CampanaEspecialCreate, db: Session = Depends(get_db)):
    # Buscamos si ya existe por nombre y fecha
    campana = db.query(CampanaEspecial).filter(
        CampanaEspecial.nombre == datos.nombre,
        CampanaEspecial.fecha == datos.fecha
    ).first()
    
    if campana:
        for campo, valor in datos.model_dump().items():
            setattr(campana, campo, valor)
    else:
        campana = CampanaEspecial(**datos.model_dump())
        db.add(campana)
        
    db.commit()
    db.refresh(campana)
    return campana

@router.delete("/{campana_id}")
def eliminar_campana(campana_id: int, db: Session = Depends(get_db)):
    campana = db.query(CampanaEspecial).filter(CampanaEspecial.id == campana_id).first()
    if not campana:
        raise HTTPException(status_code=404, detail="Campaña no encontrada")
    db.delete(campana)
    db.commit()
    return {"mensaje": "Campaña eliminada correctamente"}
