from sqlalchemy import Column, Integer, Date, TIMESTAMP, ForeignKey, Numeric, func
from app.database import Base


class PesajeBascula(Base):
    __tablename__ = "pesajes_bascula"

    id = Column(Integer, primary_key=True, index=True)
    cliente_id = Column(
        Integer,
        ForeignKey("clientes.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    usuario_id = Column(
        Integer,
        ForeignKey("usuarios.id", ondelete="SET NULL"),
        nullable=True,
    )
    fecha_pesaje = Column(Date, nullable=False)

    # Medidas directas de la báscula
    peso = Column(Numeric(8, 2), nullable=True)
    impedancia = Column(Numeric(8, 2), nullable=True)

    # Composición corporal calculada / estimada a partir de la bioimpedancia
    imc = Column(Numeric(6, 2), nullable=True)
    porcentaje_grasa = Column(Numeric(6, 2), nullable=True)
    porcentaje_muscular = Column(Numeric(6, 2), nullable=True)
    porcentaje_oseo = Column(Numeric(6, 2), nullable=True)
    porcentaje_liquidos = Column(Numeric(6, 2), nullable=True)

    creado_en = Column(TIMESTAMP, server_default=func.current_timestamp())
