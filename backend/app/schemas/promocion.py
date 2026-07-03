from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

class PromocionBase(BaseModel):
    nombre: str
    descripcion: Optional[str] = None
    codigo: str
    fecha_inicio: date
    fecha_fin: date
    activa: bool = True
    limite_usos: Optional[int] = None
    un_uso_por_usuario: bool = True
    un_uso_global: bool = False
    tipo_beneficio: str
    beneficio_personalizado: Optional[str] = None
    observaciones: Optional[str] = None

class PromocionCreate(PromocionBase):
    pass

class PromocionResponse(PromocionBase):
    id: int
    usos_realizados: int
    creado_en: datetime

    class Config:
        from_attributes = True
