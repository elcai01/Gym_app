from sqlalchemy import Column, Integer, String, Text, Date, Boolean, TIMESTAMP, func
from app.database import Base

class CampanaEspecial(Base):
    __tablename__ = "campanas_especiales"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    activa = Column(Boolean, default=True, nullable=False)
    fecha = Column(Date, nullable=False, index=True)
    hora = Column(String(5), nullable=False) # Formato HH:MM
    plantilla = Column(Text, nullable=False)
    aplica_a = Column(String(30), default="TODOS", nullable=False) # TODOS, ACTIVOS, VENCIDOS
    envio_unico = Column(Boolean, default=True, nullable=False)
    ultimo_envio = Column(TIMESTAMP, nullable=True)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())
