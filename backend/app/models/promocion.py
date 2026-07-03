from sqlalchemy import Column, Integer, String, Text, Date, Boolean, TIMESTAMP, func
from app.database import Base

class Promocion(Base):
    __tablename__ = "promociones"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), nullable=False)
    descripcion = Column(Text, nullable=True)
    codigo = Column(String(50), unique=True, index=True, nullable=False)
    fecha_inicio = Column(Date, nullable=False)
    fecha_fin = Column(Date, nullable=False)
    activa = Column(Boolean, default=True, nullable=False)
    limite_usos = Column(Integer, nullable=True) # Null = ilimitado
    usos_realizados = Column(Integer, default=0, nullable=False)
    un_uso_por_usuario = Column(Boolean, default=True, nullable=False)
    un_uso_global = Column(Boolean, default=False, nullable=False)
    tipo_beneficio = Column(String(50), nullable=False) # 1_MES_GRATIS, 15_DIAS_GRATIS, 50_DESC, 100_DESC, CLASE_PERSONALIZADA, ACCESO_VIP, OTRO
    beneficio_personalizado = Column(String(150), nullable=True)
    observaciones = Column(Text, nullable=True)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())
