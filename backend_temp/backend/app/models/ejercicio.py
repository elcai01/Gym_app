from sqlalchemy import Column, Integer, String, Text, Boolean, TIMESTAMP, func
from app.database import Base


class Ejercicio(Base):
    __tablename__ = "ejercicios"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(150), nullable=False, index=True)
    grupo_muscular = Column(String(100), nullable=True)
    descripcion = Column(Text, nullable=True)
    instrucciones = Column(Text, nullable=True)
    imagen_url = Column(Text, nullable=True)
    gif_url = Column(Text, nullable=True)
    video_url = Column(Text, nullable=True)
    nivel = Column(String(50), nullable=True)
    activo = Column(Boolean, nullable=False, default=True)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())
