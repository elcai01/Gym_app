from typing import Optional
from pydantic import BaseModel


class RegistrarTarjetaRequest(BaseModel):
    cliente_id: int
    rfid_uid: str


class RegistrarHuellaRequest(BaseModel):
    cliente_id: int
    huella_id: int


class ClienteAccesoInfo(BaseModel):
    id: int
    documento: str
    nombres: str
    apellidos: str
    estado: str

    class Config:
        from_attributes = True


class ValidarAccesoResponse(BaseModel):
    permitido: bool
    razon: str
    mensaje: str
    audio: str          # nombre del MP3 que el ESP32 debe reproducir
    cliente: Optional[ClienteAccesoInfo] = None
    asistencia_id: Optional[int] = None
    dias_restantes: Optional[int] = None    # útil para "te quedan 3 días"
    fecha_fin: Optional[str] = None         # ISO date