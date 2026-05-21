from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.usuario import Usuario
from app.models.cliente import Cliente
from app.models.rol import Rol
from app.schemas.usuario import (
    LoginRequest,
    LoginResponse,
    UsuarioClienteCreate,
    UsuarioOut,
)

router = APIRouter(prefix="/usuarios", tags=["usuarios"])


@router.post("/login", response_model=LoginResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    usuario = (
        db.query(Usuario)
        .filter(Usuario.username == data.username)
        .filter(Usuario.activo == True)
        .first()
    )

    if not usuario:
        raise HTTPException(status_code=401, detail="Usuario no encontrado o inactivo.")

    if usuario.password_hash != data.password:
        raise HTTPException(status_code=401, detail="Contraseña incorrecta.")

    rol = db.query(Rol).filter(Rol.id == usuario.rol_id).first()
    nombre_rol = rol.nombre.upper() if rol else "SIN_ROL"

    usuario.ultimo_acceso = datetime.now()
    db.commit()
    db.refresh(usuario)

    return LoginResponse(
        id=usuario.id,
        nombre=usuario.nombre,
        username=usuario.username,
        rol=nombre_rol,
        cliente_id=usuario.cliente_id,
        activo=usuario.activo,
    )


@router.post("/", response_model=UsuarioOut)
def crear_usuario_cliente(data: UsuarioClienteCreate, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == data.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado.")

    username = (cliente.documento or "").strip()
    if not username:
        raise HTTPException(status_code=400, detail="El cliente no tiene documento válido.")

    existente_username = db.query(Usuario).filter(Usuario.username == username).first()
    if existente_username:
        raise HTTPException(status_code=400, detail="Ese username ya existe.")

    existente_cliente = db.query(Usuario).filter(Usuario.cliente_id == data.cliente_id).first()
    if existente_cliente:
        raise HTTPException(status_code=400, detail="Ese cliente ya tiene un usuario asignado.")

    rol_cliente = db.query(Rol).filter(Rol.nombre.ilike("CLIENTE")).first()
    if not rol_cliente:
        raise HTTPException(status_code=500, detail="No existe el rol CLIENTE en la base de datos.")

    nuevo_usuario = Usuario(
        nombre=f"{cliente.nombres} {cliente.apellidos}".strip(),
        username=username,
        password_hash=data.password,
        rol_id=rol_cliente.id,
        cliente_id=cliente.id,
        activo=True,
    )

    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)

    return UsuarioOut(
        id=nuevo_usuario.id,
        nombre=nuevo_usuario.nombre,
        username=nuevo_usuario.username,
        rol=rol_cliente.nombre.upper(),
        cliente_id=nuevo_usuario.cliente_id,
        activo=nuevo_usuario.activo,
    )


@router.get("", response_model=list[UsuarioOut])
def listar_usuarios(db: Session = Depends(get_db)):
    usuarios = db.query(Usuario).order_by(Usuario.id).all()

    respuesta = []
    for u in usuarios:
        rol = db.query(Rol).filter(Rol.id == u.rol_id).first()
        respuesta.append(
            UsuarioOut(
                id=u.id,
                nombre=u.nombre,
                username=u.username,
                rol=rol.nombre.upper() if rol else "SIN_ROL",
                cliente_id=u.cliente_id,
                activo=u.activo,
            )
        )
    return respuesta