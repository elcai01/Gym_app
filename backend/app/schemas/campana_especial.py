from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

class CampanaEspecialBase(BaseModel):
    nombre: str
    activa: bool = True
    fecha: date
    hora: str
    plantilla: str
    aplica_a: str = "TODOS"
    envio_unico: bool = True

class CampanaEspecialCreate(CampanaEspecialBase):
    pass

class CampanaEspecialResponse(CampanaEspecialBase):
    id: int
    ultimo_envio: Optional[datetime] = None
    creado_en: datetime

    class Config:
        from_attributes = True
