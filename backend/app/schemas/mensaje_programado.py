from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

class MensajeProgramadoResponse(BaseModel):
    id: int
    cliente_id: int
    cliente_nombre: Optional[str] = None
    numero_destino: str
    tipo: str
    mensaje: str
    fecha_programada: date
    hora_programada: str
    estado: str
    intentos: int
    hora_real_envio: Optional[datetime] = None
    respuesta_envio: Optional[str] = None
    error: Optional[str] = None
    motivo_cancelacion: Optional[str] = None
    creado_en: datetime

    class Config:
        from_attributes = True
