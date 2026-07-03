from datetime import date
from typing import Optional
from pydantic import BaseModel, EmailStr


class ClienteBase(BaseModel):
    tipo_documento: str = "CC"
    documento: str
    nombres: str
    apellidos: str
    fecha_nacimiento: Optional[date] = None
    genero: Optional[str] = None
    telefono: Optional[str] = None
    whatsapp: Optional[str] = None
    email: Optional[EmailStr] = None
    direccion: Optional[str] = None
    contacto_emergencia_nombre: Optional[str] = None
    contacto_emergencia_telefono: Optional[str] = None
    foto_url: Optional[str] = None
    fecha_ingreso: date
    estado: str = "ACTIVO"
    observaciones: Optional[str] = None
    huella_id: Optional[int] = None


class ClienteCreate(ClienteBase):
    pass


class ClienteUpdate(BaseModel):
    tipo_documento: Optional[str] = None
    documento: Optional[str] = None
    nombres: Optional[str] = None
    apellidos: Optional[str] = None
    fecha_nacimiento: Optional[date] = None
    genero: Optional[str] = None
    telefono: Optional[str] = None
    whatsapp: Optional[str] = None
    email: Optional[EmailStr] = None
    direccion: Optional[str] = None
    contacto_emergencia_nombre: Optional[str] = None
    contacto_emergencia_telefono: Optional[str] = None
    foto_url: Optional[str] = None
    fecha_ingreso: Optional[date] = None
    estado: Optional[str] = None
    observaciones: Optional[str] = None
    huella_id: Optional[int] = None


class ClienteResponse(ClienteBase):
    id: int

    class Config:
        from_attributes = True
