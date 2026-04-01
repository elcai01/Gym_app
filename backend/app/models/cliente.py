from sqlalchemy import Column, Integer, String, Date, Text, TIMESTAMP, func
from app.database import Base


class Cliente(Base):
    __tablename__ = "clientes"

    id = Column(Integer, primary_key=True, index=True)
    tipo_documento = Column(String(20), nullable=False, default="CC")
    documento = Column(String(30), unique=True, nullable=False, index=True)
    nombres = Column(String(120), nullable=False)
    apellidos = Column(String(120), nullable=False)
    fecha_nacimiento = Column(Date, nullable=True)
    genero = Column(String(20), nullable=True)
    telefono = Column(String(30), nullable=True)
    whatsapp = Column(String(30), nullable=True)
    email = Column(String(120), nullable=True)
    direccion = Column(Text, nullable=True)
    contacto_emergencia_nombre = Column(String(120), nullable=True)
    contacto_emergencia_telefono = Column(String(30), nullable=True)
    foto_url = Column(Text, nullable=True)
    fecha_ingreso = Column(Date, nullable=False)
    estado = Column(String(20), nullable=False, default="ACTIVO")
    observaciones = Column(Text, nullable=True)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())
    actualizado_en = Column(
        TIMESTAMP,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp()
    )