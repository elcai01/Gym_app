from sqlalchemy import Column, String
from app.database import Base

class Configuracion(Base):
    __tablename__ = "configuraciones"

    clave = Column(String, primary_key=True, index=True)
    valor = Column(String, nullable=True)
