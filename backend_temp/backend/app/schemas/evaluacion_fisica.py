from datetime import date
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel


class EvaluacionFisicaBase(BaseModel):
    cliente_id: int
    usuario_id: Optional[int] = None
    fecha_evaluacion: date
    peso: Optional[Decimal] = None
    estatura: Optional[Decimal] = None
    imc: Optional[Decimal] = None
    torax: Optional[Decimal] = None
    biceps_izq: Optional[Decimal] = None
    biceps_der: Optional[Decimal] = None
    abdomen_sup: Optional[Decimal] = None
    abdomen_inf: Optional[Decimal] = None
    cadera: Optional[Decimal] = None
    muslo: Optional[Decimal] = None
    pantorrilla: Optional[Decimal] = None
    porcentaje_grasa: Optional[Decimal] = None
    porcentaje_muscular: Optional[Decimal] = None
    porcentaje_oseo: Optional[Decimal] = None
    porcentaje_liquidos: Optional[Decimal] = None
    biotipo: Optional[str] = None
    objetivo: Optional[str] = None
    gasto_energetico: Optional[str] = None
    fuma: Optional[str] = None
    bebe: Optional[str] = None
    horas_sueno: Optional[str] = None
    otros_deportes: Optional[str] = None
    lesiones: Optional[str] = None
    cirugias: Optional[str] = None
    observaciones: Optional[str] = None


class EvaluacionFisicaCreate(EvaluacionFisicaBase):
    pass


class EvaluacionFisicaUpdate(BaseModel):
    cliente_id: Optional[int] = None
    usuario_id: Optional[int] = None
    fecha_evaluacion: Optional[date] = None
    peso: Optional[Decimal] = None
    estatura: Optional[Decimal] = None
    imc: Optional[Decimal] = None
    torax: Optional[Decimal] = None
    biceps_izq: Optional[Decimal] = None
    biceps_der: Optional[Decimal] = None
    abdomen_sup: Optional[Decimal] = None
    abdomen_inf: Optional[Decimal] = None
    cadera: Optional[Decimal] = None
    muslo: Optional[Decimal] = None
    pantorrilla: Optional[Decimal] = None
    porcentaje_grasa: Optional[Decimal] = None
    porcentaje_muscular: Optional[Decimal] = None
    porcentaje_oseo: Optional[Decimal] = None
    porcentaje_liquidos: Optional[Decimal] = None
    biotipo: Optional[str] = None
    objetivo: Optional[str] = None
    gasto_energetico: Optional[str] = None
    fuma: Optional[str] = None
    bebe: Optional[str] = None
    horas_sueno: Optional[str] = None
    otros_deportes: Optional[str] = None
    lesiones: Optional[str] = None
    cirugias: Optional[str] = None
    observaciones: Optional[str] = None


class EvaluacionFisicaResponse(EvaluacionFisicaBase):
    id: int

    class Config:
        from_attributes = True