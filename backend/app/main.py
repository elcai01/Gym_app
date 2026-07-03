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
from app.models.rutina import Rutina, RutinaEjercicio, ClienteRutina, ClienteRutinaProgreso
from app.models.pesaje_bascula import PesajeBascula
from app.models.log_mensaje import LogMensaje
from app.models.plantilla_mensaje import PlantillaMensaje
from app.models.campana_especial import CampanaEspecial
from app.models.mensaje_programado import MensajeProgramado
from app.models.promocion import Promocion
from app.models.promocion_usuario import PromocionUsuario

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
    pesajes_bascula,
    acceso_whatsapp,
    plantillas,
    campanas,
    automatizaciones,
    promociones,
    configuracion,
)

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Sistema Gimnasio API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR  = Path(__file__).resolve().parent.parent
MEDIA_DIR = BASE_DIR / "media"
PANEL_DIR = Path("E:/Gimnasio_app/backend")

import asyncio
from datetime import date, datetime, timedelta
import requests
from sqlalchemy import extract
from app.database import SessionLocal

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
app.include_router(pesajes_bascula.router)
app.include_router(acceso_whatsapp.router)
app.include_router(plantillas.router)
app.include_router(campanas.router)
app.include_router(automatizaciones.router)
app.include_router(promociones.router)
app.include_router(configuracion.router)
app.mount("/media", StaticFiles(directory=str(MEDIA_DIR)), name="media")
# app.mount("/panel", StaticFiles(directory=str(PANEL_DIR), html=True), name="panel")


# ============================================================================
# Tareas automáticas en segundo plano (Scheduler)
# ============================================================================

@app.on_event("startup")
async def startup_event():
    import asyncio
    from app.services.scheduler_service import run_scheduler_loop, DEFAULT_TEMPLATES
    from app.database import SessionLocal
    from app.models.plantilla_mensaje import PlantillaMensaje

    # ── Inyección automática de plantillas por defecto ──────────────────────
    # Se insertan las plantillas que aún no existen en la BD.
    # Las plantillas que el usuario ya editó NO se sobreescriben.
    try:
        db = SessionLocal()
        for codigo, contenido in DEFAULT_TEMPLATES.items():
            existe = db.query(PlantillaMensaje).filter(PlantillaMensaje.codigo == codigo).first()
            if not existe:
                nombre = codigo.replace("_", " ").title()
                db.add(PlantillaMensaje(codigo=codigo, nombre=nombre, contenido=contenido))
        db.commit()
    except Exception as e:
        import logging
        logging.getLogger("startup").warning(f"No se pudieron inyectar plantillas por defecto: {e}")
    finally:
        db.close()

    # ── Iniciar programador de mensajes ─────────────────────────────────────
    asyncio.create_task(run_scheduler_loop())


