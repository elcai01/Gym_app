from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, func
from app.database import Base

class PlantillaMensaje(Base):
    __tablename__ = "plantilla_mensajes"

    id = Column(Integer, primary_key=True, index=True)
    codigo = Column(String(50), unique=True, index=True, nullable=False) # CUMPLEANOS, BIENVENIDA, RECORDATORIO_VENCIMIENTO, etc.
    nombre = Column(String(100), nullable=False)
    contenido = Column(Text, nullable=False)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())
