from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from .promocion import PromocionResponse

class PromocionUsuarioResponse(BaseModel):
    id: int
    cliente_id: int
    promocion_id: int
    fecha_canje: datetime
    estado: str
    observacion: Optional[str] = None
    promocion: Optional[PromocionResponse] = None

    class Config:
        from_attributes = True
