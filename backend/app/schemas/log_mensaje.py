from datetime import date, datetime
from pydantic import BaseModel


class LogMensajeBase(BaseModel):
    cliente_id: int
    tipo: str
    fecha: date
    mensaje: str
    estado: str = "ENVIADO"


class LogMensajeCreate(LogMensajeBase):
    pass


class LogMensajeResponse(LogMensajeBase):
    id: int
    creado_en: datetime

    class Config:
        from_attributes = True
