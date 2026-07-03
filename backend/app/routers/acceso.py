from datetime import date, datetime, time
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.cliente import Cliente
from app.models.membresia import Membresia
from app.models.asistencia import Asistencia
from app.schemas.acceso import (
    RegistrarHuellaRequest,
    ValidarAccesoResponse,
    ClienteAccesoInfo,
)
from app.schemas.cliente import ClienteResponse

router = APIRouter(prefix="/acceso", tags=["Acceso (Huella)"])

# ============================================================
# Audios disponibles en la microSD del DFPlayer (recepción)
# ============================================================
AUDIO_BIENVENIDA = "001_bienvenida.mp3"
AUDIO_BIENVENIDA_POR_VENCER = "002_por_vencer.mp3"
AUDIO_MEMBRESIA_VENCIDA = "003_vencida.mp3"
AUDIO_SIN_MEMBRESIA = "004_sin_membresia.mp3"
AUDIO_NO_RECONOCIDO = "005_no_reconocido.mp3"
AUDIO_INACTIVO = "006_inactivo.mp3"
AUDIO_YA_INGRESO = "007_ya_ingreso.mp3"


def _cliente_a_info(cliente: Cliente) -> ClienteAccesoInfo:
    return ClienteAccesoInfo(
        id=cliente.id,
        documento=cliente.documento,
        nombres=cliente.nombres,
        apellidos=cliente.apellidos,
        estado=cliente.estado,
    )

def _evaluar_acceso(cliente: Cliente, db: Session) -> ValidarAccesoResponse:
    if cliente.estado != "ACTIVO":
        return ValidarAccesoResponse(
            permitido=False,
            razon="cliente_inactivo",
            mensaje=f"Cliente en estado {cliente.estado}",
            audio=AUDIO_INACTIVO,
            cliente=_cliente_a_info(cliente),
        )

    membresia = (
        db.query(Membresia)
        .filter(Membresia.cliente_id == cliente.id)
        .order_by(Membresia.fecha_fin.desc())
        .first()
    )

    if not membresia:
        return ValidarAccesoResponse(
            permitido=False,
            razon="sin_membresia",
            mensaje="El cliente no tiene ninguna membresía registrada",
            audio=AUDIO_SIN_MEMBRESIA,
            cliente=_cliente_a_info(cliente),
        )

    hoy = date.today()
    dias_restantes = (membresia.fecha_fin - hoy).days

    if dias_restantes < 0:
        return ValidarAccesoResponse(
            permitido=False,
            razon="membresia_vencida",
            mensaje=f"Membresía vencida el {membresia.fecha_fin.isoformat()}",
            audio=AUDIO_MEMBRESIA_VENCIDA,
            cliente=_cliente_a_info(cliente),
            dias_restantes=dias_restantes,
            fecha_fin=membresia.fecha_fin.isoformat(),
        )

    inicio_dia = datetime.combine(hoy, time.min)
    fin_dia = datetime.combine(hoy, time.max)
    asistencia_hoy = (
        db.query(Asistencia)
        .filter(
            Asistencia.cliente_id == cliente.id,
            Asistencia.fecha_hora_ingreso >= inicio_dia,
            Asistencia.fecha_hora_ingreso <= fin_dia,
        )
        .first()
    )

    if asistencia_hoy:
        return ValidarAccesoResponse(
            permitido=True,
            razon="ya_ingreso_hoy",
            mensaje="Acceso permitido (ya registrado hoy)",
            audio=AUDIO_YA_INGRESO,
            cliente=_cliente_a_info(cliente),
            asistencia_id=asistencia_hoy.id,
            dias_restantes=dias_restantes,
            fecha_fin=membresia.fecha_fin.isoformat(),
        )

    nueva_asistencia = Asistencia(
        cliente_id=cliente.id,
        metodo_ingreso="ACCESO",
        observaciones=None,
    )
    db.add(nueva_asistencia)
    db.commit()
    db.refresh(nueva_asistencia)

    audio = AUDIO_BIENVENIDA
    if dias_restantes <= 3:
        audio = AUDIO_BIENVENIDA_POR_VENCER

    return ValidarAccesoResponse(
        permitido=True,
        razon="ok" if dias_restantes > 3 else "por_vencer",
        mensaje="Acceso permitido",
        audio=audio,
        cliente=_cliente_a_info(cliente),
        asistencia_id=nueva_asistencia.id,
        dias_restantes=dias_restantes,
        fecha_fin=membresia.fecha_fin.isoformat(),
    )


# ============================================================
# ENDPOINTS HUELLA
# ============================================================

@router.get("/validar-huella", response_model=ValidarAccesoResponse)
def validar_acceso_huella(
    huella_id: int = Query(..., description="ID de huella en el AS608 (1-300)"),
    db: Session = Depends(get_db),
):
    cliente = db.query(Cliente).filter(Cliente.huella_id == huella_id).first()
    if not cliente:
        return ValidarAccesoResponse(
            permitido=False,
            razon="huella_no_registrada",
            mensaje="Huella no asociada a ningún cliente",
            audio=AUDIO_NO_RECONOCIDO,
        )

    resultado = _evaluar_acceso(cliente, db)

    if resultado.asistencia_id and resultado.razon in ("ok", "por_vencer"):
        asistencia = db.query(Asistencia).filter(Asistencia.id == resultado.asistencia_id).first()
        if asistencia:
            asistencia.metodo_ingreso = "HUELLA"
            db.commit()

    return resultado


@router.post("/registrar-huella", response_model=ClienteResponse)
def registrar_huella(datos: RegistrarHuellaRequest, db: Session = Depends(get_db)):
    if datos.huella_id < 1 or datos.huella_id > 300:
        raise HTTPException(status_code=400, detail="huella_id debe estar entre 1 y 300")

    cliente = db.query(Cliente).filter(Cliente.id == datos.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")

    en_uso = db.query(Cliente).filter(
        Cliente.huella_id == datos.huella_id, Cliente.id != cliente.id
    ).first()
    if en_uso:
        raise HTTPException(
            status_code=400,
            detail=f"Huella ya asignada a {en_uso.nombres} {en_uso.apellidos} (ID {en_uso.id})",
        )

    cliente.huella_id = datos.huella_id
    db.commit()
    db.refresh(cliente)
    return cliente


@router.delete("/quitar-huella/{cliente_id}")
def quitar_huella(cliente_id: int, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    cliente.huella_id = None
    db.commit()
    return {"ok": True, "mensaje": "Huella desasignada"}


@router.get("/proximo-huella-id")
def proximo_huella_id(db: Session = Depends(get_db)):
    usados = {
        row[0] for row in db.query(Cliente.huella_id)
        .filter(Cliente.huella_id.isnot(None))
        .all()
    }
    for i in range(1, 301):
        if i not in usados:
            return {"siguiente_id": i, "usados": len(usados)}
    raise HTTPException(status_code=400, detail="No hay más espacios libres (300/300)")