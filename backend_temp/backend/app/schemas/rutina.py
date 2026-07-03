from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel


class RutinaBase(BaseModel):
    nombre: str
    objetivo: Optional[str] = None
    descripcion: Optional[str] = None
    nivel: Optional[str] = None
    activa: Optional[bool] = True
    creado_por: Optional[int] = None


class RutinaCreate(RutinaBase):
    pass


class RutinaUpdate(BaseModel):
    nombre: Optional[str] = None
    objetivo: Optional[str] = None
    descripcion: Optional[str] = None
    nivel: Optional[str] = None
    activa: Optional[bool] = None


class RutinaResponse(RutinaBase):
    id: int

    class Config:
        from_attributes = True


class RutinaEjercicioCreate(BaseModel):
    ejercicio_id: int
    dia: Optional[str] = None
    orden: Optional[int] = 1
    series: Optional[str] = None
    repeticiones: Optional[str] = None
    descanso: Optional[str] = None
    observaciones: Optional[str] = None


class ClienteRutinaAssign(BaseModel):
    cliente_id: int
    rutina_id: int
    fecha_inicio: Optional[date] = None
    fecha_fin: Optional[date] = None
    observaciones: Optional[str] = None


class RutinaCumplirRequest(BaseModel):
    cumplido: bool = True


class RutinaEjercicioResponse(BaseModel):
    id: int
    ejercicio_id: int
    nombre: str
    grupo_muscular: Optional[str] = None
    descripcion: Optional[str] = None
    instrucciones: Optional[str] = None
    imagen_url: Optional[str] = None
    gif_url: Optional[str] = None
    video_url: Optional[str] = None
    dia: Optional[str] = None
    orden: Optional[int] = 1
    series: Optional[str] = None
    repeticiones: Optional[str] = None
    descanso: Optional[str] = None
    observaciones: Optional[str] = None
    cumplido: bool = False
    fecha_cumplido: Optional[datetime] = None


class RutinaDetalleResponse(BaseModel):
    id: int
    nombre: str
    objetivo: Optional[str] = None
    descripcion: Optional[str] = None
    nivel: Optional[str] = None
    activa: bool
    ejercicios: List[RutinaEjercicioResponse]


class ClienteRutinaResponse(BaseModel):
    id: int
    cliente_id: int
    rutina_id: int
    fecha_inicio: Optional[date] = None
    fecha_fin: Optional[date] = None
    activa: bool
    observaciones: Optional[str] = None
    rutina: RutinaDetalleResponse
