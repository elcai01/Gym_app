from datetime import date
from typing import List
import requests
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import Response
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.log_mensaje import LogMensaje
from app.models.cliente import Cliente
from app.schemas.log_mensaje import LogMensajeResponse

router = APIRouter(prefix="/whatsapp", tags=["WhatsApp Control"])

WHATSAPP_SERVICE_URL = "http://localhost:3001"


class EnviarManualRequest(BaseModel):
    cliente_id: int
    mensaje: str


@router.get("/status")
def obtener_estado_whatsapp():
    """Consulta el estado del microservicio de WhatsApp Web."""
    try:
        response = requests.get(f"{WHATSAPP_SERVICE_URL}/status", timeout=2)
        response.raise_for_status()
        return response.json()
    except requests.RequestException:
        # Si el servicio de Node no responde, significa que está desconectado
        return {"status": "DISCONNECTED", "hasQr": False, "qrBase64": None}


@router.get("/qr")
def obtener_qr_whatsapp():
    """Obtiene la imagen PNG del código QR del microservicio."""
    try:
        response = requests.get(f"{WHATSAPP_SERVICE_URL}/qr", timeout=5)
        if response.status_code == 200:
            return Response(content=response.content, media_type="image/png")
        else:
            raise HTTPException(
                status_code=response.status_code, 
                detail="QR no disponible. Posiblemente ya esté conectado o iniciándose."
            )
    except HTTPException:
        raise
    except requests.RequestException as e:
        raise HTTPException(
            status_code=503, 
            detail=f"No se pudo conectar al microservicio de WhatsApp: {e}"
        )


@router.post("/enviar-manual", response_model=LogMensajeResponse)
def enviar_mensaje_manual(datos: EnviarManualRequest, db: Session = Depends(get_db)):
    """Envía un mensaje personalizado a un cliente y lo registra en el historial."""
    cliente = db.query(Cliente).filter(Cliente.id == datos.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    
    if not cliente.whatsapp:
        raise HTTPException(status_code=400, detail="El cliente no tiene teléfono de WhatsApp registrado.")
    
    payload = {
        "phone": cliente.whatsapp,
        "message": datos.mensaje
    }
    
    estado = "ENVIADO"
    error_msg = None
    
    try:
        response = requests.post(f"{WHATSAPP_SERVICE_URL}/send", json=payload, timeout=12)
        if response.status_code != 200:
            estado = "FALLIDO"
            try:
                error_msg = response.json().get("error", "Error desconocido del microservicio")
            except Exception:
                error_msg = f"HTTP {response.status_code}"
    except Exception as e:
        estado = "FALLIDO"
        error_msg = str(e)
        
    nuevo_log = LogMensaje(
        cliente_id=cliente.id,
        tipo="MANUAL",
        fecha=date.today(),
        mensaje=datos.mensaje,
        estado=estado
    )
    db.add(nuevo_log)
    db.commit()
    db.refresh(nuevo_log)
    
    if estado == "FALLIDO":
        raise HTTPException(
            status_code=500, 
            detail=f"Error al enviar el mensaje por WhatsApp: {error_msg}. Registrado en historial como FALLIDO."
        )
        
    return nuevo_log


@router.get("/historial/{cliente_id}", response_model=List[LogMensajeResponse])
def obtener_historial_mensajes(cliente_id: int, db: Session = Depends(get_db)):
    """Obtiene todos los logs de mensajes enviados a un cliente ordenados por fecha descendente."""
    return (
        db.query(LogMensaje)
        .filter(LogMensaje.cliente_id == cliente_id)
        .order_by(LogMensaje.id.desc())
        .all()
    )


class EnviarPruebaRequest(BaseModel):
    phone: str
    message: str


@router.post("/enviar-prueba")
def enviar_mensaje_prueba(datos: EnviarPruebaRequest):
    """Envía un mensaje de prueba directo a un número sin registrar en historial."""
    payload = {
        "phone": datos.phone,
        "message": datos.message
    }
    try:
        response = requests.post(f"{WHATSAPP_SERVICE_URL}/send", json=payload, timeout=12)
        if response.status_code == 200:
            return response.json()
        else:
            error_detail = "Error desconocido del microservicio de WhatsApp."
            try:
                error_detail = response.json().get("error", error_detail)
            except Exception:
                pass
            raise HTTPException(status_code=response.status_code, detail=error_detail)
    except requests.RequestException as e:
        raise HTTPException(status_code=500, detail=f"No se pudo contactar al microservicio de WhatsApp: {e}")

@router.post("/logout")
def desconectar_whatsapp():
    """Desconecta la sesión de WhatsApp activa en el microservicio."""
    try:
        response = requests.post(f"{WHATSAPP_SERVICE_URL}/logout", timeout=10)
        if response.status_code == 200:
            return response.json()
        else:
            error_detail = "Error desconocido del microservicio de WhatsApp."
            try:
                error_detail = response.json().get("error", error_detail)
            except Exception:
                pass
            raise HTTPException(status_code=response.status_code, detail=error_detail)
    except requests.RequestException as e:
        raise HTTPException(status_code=500, detail=f"No se pudo contactar al microservicio de WhatsApp: {e}")
