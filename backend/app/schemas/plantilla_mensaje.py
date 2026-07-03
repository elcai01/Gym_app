from pydantic import BaseModel
from datetime import datetime

class PlantillaMensajeBase(BaseModel):
    codigo: str
    nombre: str
    contenido: str

class PlantillaMensajeCreate(PlantillaMensajeBase):
    pass

class PlantillaMensajeResponse(PlantillaMensajeBase):
    id: int
    creado_en: datetime

    class Config:
        from_attributes = True
