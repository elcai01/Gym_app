from fastapi import FastAPI
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
from app.routers import clientes, membresias, pagos, asistencias, evaluaciones_fisicas

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Sistema Gimnasio API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def raiz():
    return {"mensaje": "API del gimnasio funcionando"}


app.include_router(clientes.router)
app.include_router(membresias.router)
app.include_router(pagos.router)
app.include_router(asistencias.router)
app.include_router(evaluaciones_fisicas.router)