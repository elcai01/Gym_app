from typing import Optional
from pydantic import BaseModel


class EjercicioBase(BaseModel):
    nombre: str
    grupo_muscular: Optional[str] = None
    descripcion: Optional[str] = None
    instrucciones: Optional[str] = None
    imagen_url: Optional[str] = None
    gif_url: Optional[str] = None
    video_url: Optional[str] = None
    nivel: Optional[str] = None
    activo: Optional[bool] = True


class EjercicioCreate(EjercicioBase):
    pass


class EjercicioUpdate(BaseModel):
    nombre: Optional[str] = None
    grupo_muscular: Optional[str] = None
    descripcion: Optional[str] = None
    instrucciones: Optional[str] = None
    imagen_url: Optional[str] = None
    gif_url: Optional[str] = None
    video_url: Optional[str] = None
    nivel: Optional[str] = None
    activo: Optional[bool] = None


class EjercicioResponse(EjercicioBase):
    id: int

    class Config:
        from_attributes = True
