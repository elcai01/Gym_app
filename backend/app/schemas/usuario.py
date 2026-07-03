from typing import Optional
from pydantic import BaseModel


class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    id: int
    nombre: str
    username: str
    rol: str
    cliente_id: Optional[int] = None
    activo: bool
    token: str


class UsuarioClienteCreate(BaseModel):
    cliente_id: int
    password: str
    username: Optional[str] = None


class UsuarioStaffCreate(BaseModel):
    nombre: str
    username: str
    password: str
    rol_id: int


class UsuarioOut(BaseModel):
    id: int
    nombre: str
    username: str
    rol: str
    cliente_id: Optional[int] = None
    activo: bool

    class Config:
        from_attributes = True