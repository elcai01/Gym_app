from typing import List, Dict, Any
from datetime import date, datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database import get_db
from app.models.promocion import Promocion
from app.models.promocion_usuario import PromocionUsuario
from app.models.cliente import Cliente
from app.models.membresia import Membresia
from app.schemas.promocion import PromocionCreate, PromocionResponse
from app.schemas.promocion_usuario import PromocionUsuarioResponse
from pydantic import BaseModel

router = APIRouter(prefix="/promociones", tags=["Motor de Promociones"])

class CanjeRequest(BaseModel):
    cliente_id: int
    codigo: str

class AsignacionManualRequest(BaseModel):
    cliente_id: int
    promocion_id: int
    observacion: str = ""

@router.get("/", response_model=List[PromocionResponse])
def listar_promociones(db: Session = Depends(get_db)):
    return db.query(Promocion).order_by(Promocion.id.desc()).all()

@router.post("/", response_model=PromocionResponse)
def crear_promocion(datos: PromocionCreate, db: Session = Depends(get_db)):
    # Validar código único
    exists = db.query(Promocion).filter(Promocion.codigo == datos.codigo.upper()).first()
    if exists:
        raise HTTPException(status_code=400, detail="Ya existe una promoción con este código cupón.")
        
    nueva = Promocion(**datos.model_dump())
    nueva.codigo = nueva.codigo.upper()
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva

@router.delete("/{promocion_id}")
def eliminar_promocion(promocion_id: int, db: Session = Depends(get_db)):
    promo = db.query(Promocion).filter(Promocion.id == promocion_id).first()
    if not promo:
        raise HTTPException(status_code=404, detail="Promoción no encontrada")
    db.delete(promo)
    db.commit()
    return {"mensaje": "Promoción eliminada correctamente"}

@router.post("/canjear", response_model=PromocionUsuarioResponse)
def canjear_codigo(datos: CanjeRequest, db: Session = Depends(get_db)):
    # 1. Validar cliente
    cliente = db.query(Cliente).filter(Cliente.id == datos.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
        
    # 2. Validar promoción
    promo = db.query(Promocion).filter(Promocion.codigo == datos.codigo.upper()).first()
    if not promo:
        raise HTTPException(status_code=404, detail="El código promocional no existe.")
        
    today = date.today()
    
    # 3. Validaciones
    if not promo.activa:
        raise HTTPException(status_code=400, detail="Esta promoción se encuentra inactiva.")
        
    if today < promo.fecha_inicio or today > promo.fecha_fin:
        raise HTTPException(status_code=400, detail="Este código ha expirado o aún no está vigente.")
        
    if promo.limite_usos is not None and promo.usos_realizados >= promo.limite_usos:
        raise HTTPException(status_code=400, detail="El cupón ha alcanzado el límite de usos global.")
        
    # 4. Validar uso por usuario
    if promo.un_uso_por_usuario:
        ya_usado = db.query(PromocionUsuario).filter(
            PromocionUsuario.cliente_id == cliente.id,
            PromocionUsuario.promocion_id == promo.id
        ).first()
        if ya_usado:
            raise HTTPException(status_code=400, detail="Ya has utilizado este código promocional.")
            
    # 5. Aplicar beneficios automáticos
    observacion_canje = f"Canje automático de código: {promo.codigo}."
    estado_beneficio = "USADO"
    
    if promo.tipo_beneficio in ["1_MES_GRATIS", "15_DIAS_GRATIS"]:
        # Buscar membresía activa
        membresia = db.query(Membresia).filter(
            Membresia.cliente_id == cliente.id,
            Membresia.estado == "ACTIVA"
        ).first()
        
        dias_a_sumar = 30 if promo.tipo_beneficio == "1_MES_GRATIS" else 15
        
        if membresia:
            membresia.fecha_fin = membresia.fecha_fin + timedelta(days=dias_a_sumar)
            db.add(membresia)
            observacion_canje += f" Membresía extendida {dias_a_sumar} días (Hasta {membresia.fecha_fin.strftime('%d-%m-%Y')})."
        else:
            # Crear nueva membresía si no tiene activa
            nueva_memb = Membresia(
                cliente_id=cliente.id,
                plan_id=1, # Plan base o por defecto
                fecha_inicio=today,
                fecha_fin=today + timedelta(days=dias_a_sumar),
                estado="ACTIVA",
                observaciones=f"Creado por canje de beneficio: {promo.nombre}"
            )
            db.add(nueva_memb)
            observacion_canje += f" Nueva membresía de {dias_a_sumar} días creada automáticamente."
    else:
        # Beneficios que requieren entrega manual (descuentos, VIP, clase personalizada)
        estado_beneficio = "PENDIENTE"
        observacion_canje += " Beneficio registrado en historial. Contactar al administrador para reclamar."
        
    # Registrar canje
    registro = PromocionUsuario(
        cliente_id=cliente.id,
        promocion_id=promo.id,
        estado=estado_beneficio,
        observacion=observacion_canje
    )
    db.add(registro)
    
    # Incrementar usos
    promo.usos_realizados += 1
    db.add(promo)
    
    db.commit()
    db.refresh(registro)
    
    # Cargar promoción para la respuesta
    registro.promocion = promo
    return registro

@router.post("/asignar-manual", response_model=PromocionUsuarioResponse)
def asignar_manual(datos: AsignacionManualRequest, db: Session = Depends(get_db)):
    cliente = db.query(Cliente).filter(Cliente.id == datos.cliente_id).first()
    if not cliente:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
        
    promo = db.query(Promocion).filter(Promocion.id == datos.promocion_id).first()
    if not promo:
        raise HTTPException(status_code=404, detail="Promoción no encontrada")
        
    # Validaciones de límites y uso
    if not promo.activa:
        raise HTTPException(status_code=400, detail="Esta promoción se encuentra inactiva.")
        
    if promo.limite_usos is not None and promo.usos_realizados >= promo.limite_usos:
        raise HTTPException(status_code=400, detail="Esta promoción ha alcanzado el límite de usos global.")
        
    if promo.un_uso_por_usuario:
        ya_usado = db.query(PromocionUsuario).filter(
            PromocionUsuario.cliente_id == cliente.id,
            PromocionUsuario.promocion_id == promo.id
        ).first()
        if ya_usado:
            raise HTTPException(status_code=400, detail="El cliente ya ha utilizado esta promoción.")
            
    # Registrar asignación
    observacion_canje = f"Asignado manualmente por Administrador. {datos.observacion}".strip()
    
    # Aplicar beneficios automáticos de membresía si aplica
    if promo.tipo_beneficio in ["1_MES_GRATIS", "15_DIAS_GRATIS"]:
        membresia = db.query(Membresia).filter(
            Membresia.cliente_id == cliente.id,
            Membresia.estado == "ACTIVA"
        ).first()
        
        dias_a_sumar = 30 if promo.tipo_beneficio == "1_MES_GRATIS" else 15
        
        if membresia:
            membresia.fecha_fin = membresia.fecha_fin + timedelta(days=dias_a_sumar)
            db.add(membresia)
            observacion_canje += f" Membresía extendida {dias_a_sumar} días (Hasta {membresia.fecha_fin.strftime('%d-%m-%Y')})."
        else:
            nueva_memb = Membresia(
                cliente_id=cliente.id,
                plan_id=1,
                fecha_inicio=date.today(),
                fecha_fin=date.today() + timedelta(days=dias_a_sumar),
                estado="ACTIVA",
                observaciones=f"Creado por asignación manual de: {promo.nombre}"
            )
            db.add(nueva_memb)
            observacion_canje += f" Nueva membresía de {dias_a_sumar} días creada automáticamente."
            
    registro = PromocionUsuario(
        cliente_id=cliente.id,
        promocion_id=promo.id,
        estado="USADO" if promo.tipo_beneficio in ["1_MES_GRATIS", "15_DIAS_GRATIS"] else "PENDIENTE",
        observacion=observacion_canje
    )
    db.add(registro)
    
    promo.usos_realizados += 1
    db.add(promo)
    
    db.commit()
    db.refresh(registro)
    
    registro.promocion = promo
    return registro

@router.get("/historial/{cliente_id}", response_model=List[PromocionUsuarioResponse])
def obtener_historial_promociones(cliente_id: int, db: Session = Depends(get_db)):
    registros = db.query(PromocionUsuario).filter(
        PromocionUsuario.cliente_id == cliente_id
    ).order_by(PromocionUsuario.id.desc()).all()
    
    # Poblar la promoción relacionada
    for r in registros:
        r.promocion = db.query(Promocion).filter(Promocion.id == r.promocion_id).first()
        
    return registros

@router.get("/estadisticas")
def obtener_estadisticas_promociones(db: Session = Depends(get_db)):
    total_creadas = db.query(Promocion).count()
    active_count = db.query(Promocion).filter(
        Promocion.activa == True,
        Promocion.fecha_inicio <= date.today(),
        Promocion.fecha_fin >= date.today()
    ).count()
    
    expired_count = db.query(Promocion).filter(
        Promocion.fecha_fin < date.today()
    ).count()
    
    total_usadas = db.query(PromocionUsuario).count()
    
    # Usuarios con más promociones canjeadas
    top_usuarios_raw = db.query(
        PromocionUsuario.cliente_id,
        func.count(PromocionUsuario.id).label("total")
    ).group_by(PromocionUsuario.cliente_id).order_by(func.count(PromocionUsuario.id).desc()).limit(5).all()
    
    top_usuarios = []
    for cliente_id, total in top_usuarios_raw:
        cli = db.query(Cliente).filter(Cliente.id == cliente_id).first()
        if cli:
            top_usuarios.append({
                "cliente_id": cliente_id,
                "nombre": f"{cli.nombres} {cli.apellidos}",
                "total": total
            })
            
    # Estadísticas por tipo de beneficio
    beneficios_raw = db.query(
        Promocion.tipo_beneficio,
        func.count(PromocionUsuario.id)
    ).join(PromocionUsuario, PromocionUsuario.promocion_id == Promocion.id).group_by(Promocion.tipo_beneficio).all()
    
    beneficios_stats = {tipo: cant for tipo, cant in beneficios_raw}
    
    return {
        "total_creadas": total_creadas,
        "activas": active_count,
        "vencidas": expired_count,
        "total_usadas": total_usadas,
        "top_usuarios": top_usuarios,
        "beneficios_stats": beneficios_stats
    }
