from sqlalchemy import Column, Integer, String, Text, TIMESTAMP, ForeignKey, Numeric, func
from app.database import Base


class Pago(Base):
    __tablename__ = "pagos"

    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.id", ondelete="CASCADE"), nullable=False)
    membresia_id = Column(Integer, ForeignKey("membresias.id", ondelete="SET NULL"), nullable=True)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=True)
    fecha_pago = Column(TIMESTAMP, server_default=func.current_timestamp(), nullable=False)
    valor_pagado = Column(Numeric(12, 2), nullable=False)
    descuento = Column(Numeric(12, 2), nullable=False, default=0)
    recargo = Column(Numeric(12, 2), nullable=False, default=0)
    metodo_pago = Column(String(30), nullable=False)
    referencia = Column(String(100), nullable=True)
    observaciones = Column(Text, nullable=True)