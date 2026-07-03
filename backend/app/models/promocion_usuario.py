from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, func, ForeignKey
from app.database import Base

class PromocionUsuario(Base):
    __tablename__ = "promociones_usuarios"

    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.id", ondelete="CASCADE"), nullable=False, index=True)
    promocion_id = Column(Integer, ForeignKey("promociones.id", ondelete="CASCADE"), nullable=False, index=True)
    fecha_canje = Column(TIMESTAMP, server_default=func.current_timestamp(), nullable=False)
    estado = Column(String(20), nullable=False, default="USADO") # ENTREGADO, USADO, VENCIDO, PENDIENTE
    observacion = Column(Text, nullable=True)
