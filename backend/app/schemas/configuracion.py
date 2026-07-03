from pydantic import BaseModel
from typing import Optional

class ConfiguracionBase(BaseModel):
    clave: str
    valor: Optional[str] = None

class ConfiguracionCreate(ConfiguracionBase):
    pass

class Configuracion(ConfiguracionBase):
    class Config:
        from_attributes = True
