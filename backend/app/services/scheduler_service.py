import asyncio
import logging
from datetime import date, datetime, timedelta
import requests
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.cliente import Cliente
from app.models.membresia import Membresia
from app.models.plantilla_mensaje import PlantillaMensaje
from app.models.campana_especial import CampanaEspecial
from app.models.mensaje_programado import MensajeProgramado

logger = logging.getLogger("scheduler")
logger.setLevel(logging.INFO)

import os
WHATSAPP_SERVICE_URL = os.getenv("WHATSAPP_SERVICE_URL", "http://localhost:3001")
GYM_NAME = "Gym Style Life"

DEFAULT_TEMPLATES = {
    "CUMPLEANOS": "¡Hola {nombre}! 🎂 El equipo de {nombre_gimnasio} te desea un muy feliz cumpleaños. ¡Que tengas un excelente día lleno de entrenamiento y éxitos!",
    "RECORDATORIO_VENCIMIENTO": "Hola {nombre}, te recordamos que tu membresía vence el {fecha_vencimiento} ({dias_restantes} días restantes). ¡Te esperamos para renovar y seguir entrenando!",
    "RECORDATORIO_VENCIDO": "Hola {nombre}, te recordamos que tu membresía ya venció el {fecha_vencimiento}. Te extrañamos en {nombre_gimnasio}. ¡Te esperamos para renovar y seguir entrenando!",
    "BIENVENIDA": "¡Bienvenido a {nombre_gimnasio}, {nombre}! 💪 Nos alegra que te unas a nuestra comunidad. Tu membresía está activa hasta el {fecha_vencimiento}.",
    "NAVIDAD": "¡Hola {nombre}! 🎄 De parte de todo el equipo de {nombre_gimnasio}, te deseamos una muy Feliz Navidad llena de paz, amor y bienestar junto a tus seres queridos. ¡Gracias por ser parte de nuestra familia!",
    "ANO_NUEVO": "¡Hola {nombre}! 🎆 ¡Feliz Año Nuevo! Te deseamos un próspero año lleno de nuevas metas, salud y entrenamientos increíbles. ¡A por todas este año en {nombre_gimnasio}!",
    "DIA_DE_LA_MADRE": "¡Hola {nombre}! 🌸 En este Día de la Madre, queremos felicitarte y agradecerte por toda tu dedicación y fuerza. ¡Que tengas un día maravilloso te desea {nombre_gimnasio}!",
    "DIA_DEL_PADRE": "¡Hola {nombre}! 👔 ¡Feliz Día del Padre! Celebramos tu esfuerzo y constancia todos los días. Disfruta tu día te desea {nombre_gimnasio}.",
    "AMOR_Y_AMISTAD": "¡Hola {nombre}! ❤️ En el Día de Amor y Amistad, queremos recordarte lo valioso que eres para nosotros. ¡Gracias por entrenar con el corazón en {nombre_gimnasio}!",
    "HALLOWEEN": "¡Hola {nombre}! 🎃 ¡Feliz Halloween! Hoy entrenamos sin excusas ni fantasmas en {nombre_gimnasio}. ¡Te esperamos!",
    "FIESTAS_PATRIAS_COLOMBIA": "¡Hola {nombre}! 🇨🇴 ¡Feliz Día de la Independencia! Orgullosos de nuestra tierra y de nuestra fuerza. ¡A entrenar con orgullo patrio en {nombre_gimnasio}!",
}

_last_generation_date = None

def get_template_content(db: Session, codigo: str) -> str:
    plantilla = db.query(PlantillaMensaje).filter(PlantillaMensaje.codigo == codigo).first()
    if plantilla:
        return plantilla.contenido
    return DEFAULT_TEMPLATES.get(codigo, "Hola {nombre}, te enviamos un mensaje de {nombre_gimnasio}.")

def render_template(content: str, variables: dict) -> str:
    for k, v in variables.items():
        content = content.replace(f"{{{k}}}", str(v) if v is not None else "")
    return content

def generate_daily_queue(db: Session, force: bool = False):
    global _last_generation_date
    today = date.today()
    if _last_generation_date == today and not force:
        return
    
    logger.info(f"Generando cola de mensajes programados para el día: {today} (Forzado: {force})")
    
    # 1. CUMPLEAÑOS
    clientes = db.query(Cliente).all()
    for c in clientes:
        if c.fecha_nacimiento:
            if c.fecha_nacimiento.day == today.day and c.fecha_nacimiento.month == today.month:
                # Comprobar si ya se programó para hoy
                exists = db.query(MensajeProgramado).filter(
                    MensajeProgramado.cliente_id == c.id,
                    MensajeProgramado.tipo == "CUMPLEANOS",
                    MensajeProgramado.fecha_programada == today
                ).first()
                if not exists and c.whatsapp:
                    tmpl = get_template_content(db, "CUMPLEANOS")
                    msg = render_template(tmpl, {
                        "nombre": c.nombres,
                        "apellido": c.apellidos,
                        "nombre_gimnasio": GYM_NAME
                    })
                    nuevo = MensajeProgramado(
                        cliente_id=c.id,
                        numero_destino=c.whatsapp,
                        tipo="CUMPLEANOS",
                        mensaje=msg,
                        fecha_programada=today,
                        hora_programada="09:00"
                    )
                    db.add(nuevo)

    # 2. RECORDATORIO DE VENCIMIENTO (3 días antes de terminar membresía activa)
    target_date = today + timedelta(days=3)
    membresias_por_vencer = db.query(Membresia).filter(
        Membresia.fecha_fin == target_date,
        Membresia.estado == "ACTIVA"
    ).all()
    for m in membresias_por_vencer:
        c = db.query(Cliente).filter(Cliente.id == m.cliente_id).first()
        if c and c.whatsapp:
            exists = db.query(MensajeProgramado).filter(
                MensajeProgramado.cliente_id == c.id,
                MensajeProgramado.tipo == "RECORDATORIO_VENCIMIENTO",
                MensajeProgramado.fecha_programada == today
            ).first()
            if not exists:
                tmpl = get_template_content(db, "RECORDATORIO_VENCIMIENTO")
                msg = render_template(tmpl, {
                    "nombre": c.nombres,
                    "apellido": c.apellidos,
                    "fecha_vencimiento": m.fecha_fin.strftime("%d-%m-%Y"),
                    "dias_restantes": 3,
                    "nombre_gimnasio": GYM_NAME
                })
                nuevo = MensajeProgramado(
                    cliente_id=c.id,
                    numero_destino=c.whatsapp,
                    tipo="RECORDATORIO",
                    mensaje=msg,
                    fecha_programada=today,
                    hora_programada="11:00"
                )
                db.add(nuevo)

    # 2b. RECORDATORIO DE MEMBRESÍA YA VENCIDA (Vence hoy, vence hace 1 día, o hace 5 días)
    for offset in [0, 1, 5]:
        target_date = today - timedelta(days=offset)
        membresias_vencidas = db.query(Membresia).filter(
            Membresia.fecha_fin == target_date
        ).all()
        
        for m in membresias_vencidas:
            c = db.query(Cliente).filter(Cliente.id == m.cliente_id).first()
            if c and c.whatsapp:
                tipo_msg = f"RECORDATORIO_VENCIDO_{offset}D"
                exists = db.query(MensajeProgramado).filter(
                    MensajeProgramado.cliente_id == c.id,
                    MensajeProgramado.tipo == tipo_msg,
                    MensajeProgramado.fecha_programada == today
                ).first()
                
                if not exists:
                    tmpl = get_template_content(db, "RECORDATORIO_VENCIDO")
                    msg = render_template(tmpl, {
                        "nombre": c.nombres,
                        "apellido": c.apellidos,
                        "fecha_vencimiento": m.fecha_fin.strftime("%d-%m-%Y"),
                        "nombre_gimnasio": GYM_NAME
                    })
                    nuevo = MensajeProgramado(
                        cliente_id=c.id,
                        numero_destino=c.whatsapp,
                        tipo="RECORDATORIO",
                        mensaje=msg,
                        fecha_programada=today,
                        hora_programada="12:00"
                    )
                    db.add(nuevo)

    # 3. CAMPAÑAS ESPECIALES
    campanas = db.query(CampanaEspecial).filter(
        CampanaEspecial.activa == True,
        CampanaEspecial.fecha == today
    ).all()
    for camp in campanas:
        # Filtrar clientes según el público objetivo de la campaña
        if camp.aplica_a == "ACTIVOS":
            dest_clientes = db.query(Cliente).filter(Cliente.estado == "ACTIVO").all()
        elif camp.aplica_a == "VENCIDOS":
            dest_clientes = db.query(Cliente).filter(Cliente.estado == "VENCIDO").all()
        else:
            dest_clientes = db.query(Cliente).all()
            
        for c in dest_clientes:
            if c.whatsapp:
                exists = db.query(MensajeProgramado).filter(
                    MensajeProgramado.cliente_id == c.id,
                    MensajeProgramado.tipo == f"CAMPANA_{camp.id}",
                    MensajeProgramado.fecha_programada == today
                ).first()
                if not exists:
                    msg = render_template(camp.plantilla, {
                        "nombre": c.nombres,
                        "apellido": c.apellidos,
                        "nombre_gimnasio": GYM_NAME
                    })
                    nuevo = MensajeProgramado(
                        cliente_id=c.id,
                        numero_destino=c.whatsapp,
                        tipo="CAMPANA",
                        mensaje=msg,
                        fecha_programada=today,
                        hora_programada=camp.hora
                    )
                    db.add(nuevo)
        
        camp.ultimo_envio = datetime.now()
        db.add(camp)

    db.commit()
    _last_generation_date = today
    logger.info("Cola diaria de automatizaciones generada exitosamente.")

async def run_scheduler_loop():
    logger.info("Iniciando servicio programador de mensajes en segundo plano...")
    await asyncio.sleep(10) # Dar tiempo a que el servidor FastAPI inicie completamente
    while True:
        try:
            db = SessionLocal()
            try:
                generate_daily_queue(db)
                
                # Procesar mensajes pendientes
                # Buscamos pendientes de hoy o anteriores que se puedan recuperar
                pendientes = db.query(MensajeProgramado).filter(
                    MensajeProgramado.estado == "PENDIENTE"
                ).all()
                
                now = datetime.now()
                today_str = date.today()
                current_time_str = now.strftime("%H:%M")
                
                for msg in pendientes:
                    # Comprobar si ya llegó la hora de envío
                    # Si es de un día anterior, o es de hoy y ya pasó o coincide la hora
                    is_ready = False
                    if msg.fecha_programada < today_str:
                        is_ready = True
                    elif msg.fecha_programada == today_str and msg.hora_programada <= current_time_str:
                        is_ready = True
                        
                    if is_ready:
                        # 1. VALIDAR RECUPERACIÓN INTELIGENTE (Late Messages)
                        days_late = (today_str - msg.fecha_programada).days
                        expired = False
                        limit_days = 2 # Por defecto 2 días (Promociones / Campañas)
                        
                        if msg.tipo == "CUMPLEANOS":
                            limit_days = 2
                        elif msg.tipo == "RECORDATORIO":
                            limit_days = 1
                        
                        if days_late > limit_days:
                            msg.estado = "CANCELADO"
                            msg.motivo_cancelacion = f"Excedió ventana de recuperación de {limit_days} día(s). Atrasado por {days_late} días."
                            db.add(msg)
                            db.commit()
                            continue
                            
                        # 2. APLICAR GENTILEZA EN MENSAJES DE CUMPLEAÑOS RETRASADOS
                        final_msg = msg.mensaje
                        if msg.tipo == "CUMPLEANOS" and days_late > 0:
                            if days_late == 1:
                                final_msg = "No queremos dejar pasar la oportunidad de desearte un feliz cumpleaños. Esperamos que hayas tenido un excelente día.\n\n" + msg.mensaje
                            elif days_late == 2:
                                final_msg = "Aunque con un poco de retraso, queremos enviarte un feliz cumpleaños.\n\n" + msg.mensaje
                        
                        # 3. ENVIAR MENSAJE
                        payload = {
                            "phone": msg.numero_destino,
                            "message": final_msg
                        }
                        
                        logger.info(f"Intentando enviar mensaje ID {msg.id} de tipo {msg.tipo} a {msg.numero_destino}")
                        msg.intentos += 1
                        
                        try:
                            res = requests.post(f"{WHATSAPP_SERVICE_URL}/send", json=payload, timeout=10)
                            if res.status_code == 200:
                                msg.estado = "ENVIADO"
                                msg.hora_real_envio = datetime.now()
                                msg.respuesta_envio = res.text
                                logger.info(f"Mensaje ID {msg.id} enviado exitosamente.")
                            else:
                                if msg.intentos >= 3:
                                    msg.estado = "FALLIDO"
                                msg.error = f"Servidor respondió con código {res.status_code}."
                        except requests.RequestException as re:
                            if msg.intentos >= 3:
                                msg.estado = "FALLIDO"
                            # Sanitizar errores de red e impedir fugas de traza/puertos/rutas
                            err_str = str(re)
                            if "ConnectionPool" in err_str or "Max retries" in err_str or "NewConnectionError" in err_str:
                                msg.error = "No se pudo establecer conexión con el servicio local de WhatsApp."
                            else:
                                msg.error = "Error de comunicación al intentar enviar."
                        except Exception:
                            if msg.intentos >= 3:
                                msg.estado = "FALLIDO"
                            msg.error = "Error interno al procesar el envío."
                            
                        db.add(msg)
                        db.commit()
                        
            finally:
                db.close()
                
        except Exception as e:
            logger.error(f"Error en el bucle del programador: {e}")
            
        await asyncio.sleep(30) # Comprobar cada 30 segundos
