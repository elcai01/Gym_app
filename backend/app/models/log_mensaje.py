from sqlalchemy import Column, Integer, String, Date, Text, TIMESTAMP, func, ForeignKey
from app.database import Base


class LogMensaje(Base):
    __tablename__ = "log_mensajes"

    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.id", ondelete="CASCADE"), nullable=False)
    tipo = Column(String(50), nullable=False)  # CUMPLEANOS, COBRO_ANTICIPADO, COBRO_VENCIDO, MANUAL
    fecha = Column(Date, nullable=False, index=True)
    mensaje = Column(Text, nullable=False)
    estado = Column(String(20), nullable=False, default="ENVIADO")  # ENVIADO, FALLIDO
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())
