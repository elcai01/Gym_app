from datetime import datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel


class PagoBase(BaseModel):
    cliente_id: int
    membresia_id: Optional[int] = None
    usuario_id: Optional[int] = None
    valor_pagado: Decimal
    descuento: Decimal = 0
    recargo: Decimal = 0
    metodo_pago: str
    referencia: Optional[str] = None
    observaciones: Optional[str] = None


class PagoCreate(PagoBase):
    pass


class PagoUpdate(BaseModel):
    cliente_id: Optional[int] = None
    membresia_id: Optional[int] = None
    usuario_id: Optional[int] = None
    valor_pagado: Optional[Decimal] = None
    descuento: Optional[Decimal] = None
    recargo: Optional[Decimal] = None
    metodo_pago: Optional[str] = None
    referencia: Optional[str] = None
    observaciones: Optional[str] = None


class PagoResponse(PagoBase):
    id: int
    fecha_pago: datetime

    class Config:
        from_attributes = True