import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Leemos la variable de entorno de Render, si no existe usamos la local de Neon por defecto (o local)
# Asegurarse de que si Neon devuelve "postgres://" lo cambiemos a "postgresql://" para SQLAlchemy
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://neondb_owner:npg_n3MLvdRkj4eG@ep-restless-dream-atz9wh8p.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require"
)
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()