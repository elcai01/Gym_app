from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, ForeignKey, func
from app.database import Base


class Asistencia(Base):
    __tablename__ = "asistencias"

    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.id", ondelete="CASCADE"), nullable=False)
    fecha_hora_ingreso = Column(TIMESTAMP, server_default=func.current_timestamp(), nullable=False)
    fecha_hora_salida = Column(TIMESTAMP, nullable=True)
    metodo_ingreso = Column(String(30), nullable=False, default="MANUAL")
    observaciones = Column(Text, nullable=True)