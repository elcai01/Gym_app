from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.models.cliente import Cliente
from app.models.rol import Rol
from app.models.usuario import Usuario
from app.models.plan import Plan
from app.models.membresia import Membresia
from app.models.pago import Pago
from app.models.asistencia import Asistencia
from app.models.evaluacion_fisica import EvaluacionFisica
from app.models.ejercicio import Ejercicio
from app.models.rutina import Rutina, RutinaEjercicio, ClienteRutina

from app.routers import (
    clientes,
    membresias,
    pagos,
    asistencias,
    evaluaciones_fisicas,
    usuarios,
    rutinas,
    ejercicios,
    acceso,
)

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Sistema Gimnasio API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = Path(__file__).resolve().parent.parent
MEDIA_DIR = BASE_DIR / "media"

@app.get("/")
def raiz():
    return {"mensaje": "API del gimnasio funcionando"}

app.include_router(clientes.router)
app.include_router(membresias.router)
app.include_router(pagos.router)
app.include_router(asistencias.router)
app.include_router(evaluaciones_fisicas.router)
app.include_router(usuarios.router)
app.include_router(rutinas.router)
app.include_router(ejercicios.router)
app.include_router(acceso.router)
app.mount("/media", StaticFiles(directory=str(MEDIA_DIR)), name="media")
