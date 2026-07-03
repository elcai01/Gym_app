from typing import List
from datetime import date
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.mensaje_programado import MensajeProgramado
from app.models.cliente import Cliente
from app.schemas.mensaje_programado import MensajeProgramadoResponse

router = APIRouter(prefix="/automatizaciones", tags=["Automatizaciones"])

@router.get("/programados-hoy", response_model=List[MensajeProgramadoResponse])
def obtener_mensajes_programados_hoy(db: Session = Depends(get_db)):
    hoy = date.today()
    # Join con Cliente para retornar nombres completos
    resultados = db.query(MensajeProgramado, Cliente).join(
        Cliente, MensajeProgramado.cliente_id == Cliente.id
    ).filter(
        MensajeProgramado.fecha_programada == hoy
    ).order_by(
        MensajeProgramado.hora_programada.asc()
    ).all()
    
    response_list = []
    for msg, cli in resultados:
        response_list.append(
            MensajeProgramadoResponse(
                id=msg.id,
                cliente_id=msg.cliente_id,
                cliente_nombre=f"{cli.nombres} {cli.apellidos}",
                numero_destino=msg.numero_destino,
                tipo=msg.tipo,
                mensaje=msg.mensaje,
                fecha_programada=msg.fecha_programada,
                hora_programada=msg.hora_programada,
                estado=msg.estado,
                intentos=msg.intentos,
                hora_real_envio=msg.hora_real_envio,
                respuesta_envio=msg.respuesta_envio,
                error=msg.error,
                motivo_cancelacion=msg.motivo_cancelacion,
                creado_en=msg.creado_en
            )
        )
    return response_list

@router.post("/reprocesar-cola")
def forzar_reprocesamiento_cola(db: Session = Depends(get_db)):
    """Ejecuta de inmediato la generación y envío de la cola diaria sin esperar al bucle del scheduler."""
    from app.services.scheduler_service import generate_daily_queue
    generate_daily_queue(db, force=True)
    return {"mensaje": "Generación de la cola diaria gatillada exitosamente."}
