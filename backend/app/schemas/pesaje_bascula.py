from datetime import date, datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel


class PesajeBasculaBase(BaseModel):
    cliente_id: int
    usuario_id: Optional[int] = None
    fecha_pesaje: date

    peso: Optional[Decimal] = None
    impedancia: Optional[Decimal] = None

    imc: Optional[Decimal] = None
    porcentaje_grasa: Optional[Decimal] = None
    porcentaje_muscular: Optional[Decimal] = None
    porcentaje_oseo: Optional[Decimal] = None
    porcentaje_liquidos: Optional[Decimal] = None


class PesajeBasculaCreate(PesajeBasculaBase):
    pass


class PesajeBasculaResponse(PesajeBasculaBase):
    id: int
    creado_en: Optional[datetime] = None

    class Config:
        from_attributes = True
