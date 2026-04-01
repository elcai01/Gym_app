from sqlalchemy import Column, Integer, String, Text, Date, TIMESTAMP, ForeignKey, Numeric, func
from app.database import Base


class EvaluacionFisica(Base):
    __tablename__ = "evaluaciones_fisicas"

    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(Integer, ForeignKey("clientes.id", ondelete="CASCADE"), nullable=False)
    usuario_id = Column(Integer, ForeignKey("usuarios.id"), nullable=True)
    fecha_evaluacion = Column(Date, nullable=False)
    peso = Column(Numeric(8, 2), nullable=True)
    estatura = Column(Numeric(5, 2), nullable=True)
    imc = Column(Numeric(6, 2), nullable=True)
    torax = Column(Numeric(6, 2), nullable=True)
    biceps_izq = Column(Numeric(6, 2), nullable=True)
    biceps_der = Column(Numeric(6, 2), nullable=True)
    abdomen_sup = Column(Numeric(6, 2), nullable=True)
    abdomen_inf = Column(Numeric(6, 2), nullable=True)
    cadera = Column(Numeric(6, 2), nullable=True)
    muslo = Column(Numeric(6, 2), nullable=True)
    pantorrilla = Column(Numeric(6, 2), nullable=True)
    porcentaje_grasa = Column(Numeric(6, 2), nullable=True)
    porcentaje_muscular = Column(Numeric(6, 2), nullable=True)
    porcentaje_oseo = Column(Numeric(6, 2), nullable=True)
    porcentaje_liquidos = Column(Numeric(6, 2), nullable=True)
    biotipo = Column(String(50), nullable=True)
    objetivo = Column(String(150), nullable=True)
    gasto_energetico = Column(String(100), nullable=True)
    fuma = Column(String(30), nullable=True)
    bebe = Column(String(30), nullable=True)
    horas_sueno = Column(String(30), nullable=True)
    otros_deportes = Column(Text, nullable=True)
    lesiones = Column(Text, nullable=True)
    cirugias = Column(Text, nullable=True)
    observaciones = Column(Text, nullable=True)
    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())