from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class AsistenciaBase(BaseModel):
    cliente_id: int
    fecha_hora_salida: Optional[datetime] = None
    metodo_ingreso: str = "MANUAL"
    observaciones: Optional[str] = None


class AsistenciaCreate(AsistenciaBase):
    pass


class AsistenciaUpdate(BaseModel):
    cliente_id: Optional[int] = None
    fecha_hora_salida: Optional[datetime] = None
    metodo_ingreso: Optional[str] = None
    observaciones: Optional[str] = None


class AsistenciaResponse(BaseModel):
    id: int
    cliente_id: int
    fecha_hora_ingreso: datetime
    fecha_hora_salida: Optional[datetime] = None
    metodo_ingreso: str
    observaciones: Optional[str] = None

    class Config:
        from_attributes = True