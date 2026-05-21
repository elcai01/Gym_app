from sqlalchemy import Column, Integer, String, Text, Boolean, TIMESTAMP, ForeignKey, Date, func
from app.database import Base


class Rutina(Base):
    __tablename__ = "rutinas"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(150), nullable=False, index=True)
    objetivo = Column(String(150), nullable=True)
    descripcion = Column(Text, nullable=True)
    nivel = Column(String(50), nullable=True)
    activa = Column(Boolean, nullable=False, default=True)
    creado_por = Column(Integer, ForeignKey("usuarios.id"), nullable=True)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())


class RutinaEjercicio(Base):
    __tablename__ = "rutina_ejercicios"

    id = Column(Integer, primary_key=True, index=True)
    rutina_id = Column(Integer, ForeignKey("rutinas.id", ondelete="CASCADE"), nullable=False, index=True)
    ejercicio_id = Column(Integer, ForeignKey("ejercicios.id", ondelete="CASCADE"), nullable=False, index=True)
    dia = Column(String(50), nullable=True)
    orden = Column(Integer, nullable=False, default=1)
    series = Column(String(50), nullable=True)
    repeticiones = Column(String(50), nullable=True)
    descanso = Column(String(50), nullable=True)
    observaciones = Column(Text, nullable=True)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())


class ClienteRutina(Base):
    __tablename__ = "cliente_rutinas"

    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.id", ondelete="CASCADE"), nullable=False, index=True)
    rutina_id = Column(Integer, ForeignKey("rutinas.id", ondelete="CASCADE"), nullable=False, index=True)
    fecha_inicio = Column(Date, nullable=True)
    fecha_fin = Column(Date, nullable=True)
    completada = Column(Boolean, nullable=False, default=False)
    activa = Column(Boolean, nullable=False, default=True)
    observaciones = Column(Text, nullable=True)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())


class ClienteRutinaProgreso(Base):
    __tablename__ = "cliente_rutina_progreso"

    id = Column(Integer, primary_key=True, index=True)
    cliente_rutina_id = Column(Integer, ForeignKey("cliente_rutinas.id", ondelete="CASCADE"), nullable=False, index=True)
    rutina_ejercicio_id = Column(Integer, ForeignKey("rutina_ejercicios.id", ondelete="CASCADE"), nullable=False, index=True)
    cumplido = Column(Boolean, nullable=False, default=False)
    fecha_cumplido = Column(TIMESTAMP, nullable=True)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())
