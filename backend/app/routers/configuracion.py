from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.models.configuracion import Configuracion
from app.schemas.configuracion import Configuracion as ConfiguracionSchema, ConfiguracionCreate

router = APIRouter(
    prefix="/configuracion",
    tags=["configuracion"]
)

@router.get("/", response_model=List[ConfiguracionSchema])
def get_todas_configuraciones(db: Session = Depends(get_db)):
    return db.query(Configuracion).all()

@router.get("/{clave}", response_model=ConfiguracionSchema)
def get_configuracion(clave: str, db: Session = Depends(get_db)):
    config = db.query(Configuracion).filter(Configuracion.clave == clave).first()
    if not config:
        raise HTTPException(status_code=404, detail="Configuración no encontrada")
    return config

@router.post("/", response_model=ConfiguracionSchema)
def set_configuracion(config: ConfiguracionCreate, db: Session = Depends(get_db)):
    db_config = db.query(Configuracion).filter(Configuracion.clave == config.clave).first()
    if db_config:
        db_config.valor = config.valor
    else:
        db_config = Configuracion(clave=config.clave, valor=config.valor)
        db.add(db_config)
    db.commit()
    db.refresh(db_config)
    return db_config
