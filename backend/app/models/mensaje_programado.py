from sqlalchemy import Column, Integer, String, Text, Date, TIMESTAMP, func, ForeignKey
from app.database import Base

class MensajeProgramado(Base):
    __tablename__ = "mensajes_programados"

    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.id", ondelete="CASCADE"), nullable=False)
    numero_destino = Column(String(30), nullable=False)
    tipo = Column(String(50), nullable=False) # CUMPLEANOS, RECORDATORIO_VENCIMIENTO, CAMPANA, etc.
    mensaje = Column(Text, nullable=False)
    fecha_programada = Column(Date, nullable=False, index=True)
    hora_programada = Column(String(5), nullable=False) # Formato HH:MM
    estado = Column(String(20), nullable=False, default="PENDIENTE") # PENDIENTE, ENVIADO, FALLIDO, CANCELADO
    intentos = Column(Integer, default=0, nullable=False)
    hora_real_envio = Column(TIMESTAMP, nullable=True)
    respuesta_envio = Column(Text, nullable=True)
    error = Column(Text, nullable=True)
    motivo_cancelacion = Column(Text, nullable=True)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())
