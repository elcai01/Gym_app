from datetime import date
from typing import Optional
from pydantic import BaseModel


class MembresiaBase(BaseModel):
    cliente_id: int
    plan_id: int
    fecha_inicio: date
    fecha_fin: date
    estado: str = "ACTIVA"
    observaciones: Optional[str] = None


class MembresiaCreate(MembresiaBase):
    pass


class MembresiaUpdate(BaseModel):
    cliente_id: Optional[int] = None
    plan_id: Optional[int] = None
    fecha_inicio: Optional[date] = None
    fecha_fin: Optional[date] = None
    estado: Optional[str] = None
    observaciones: Optional[str] = None


class MembresiaResponse(MembresiaBase):
    id: int

    class Config:
        from_attributes = True