import re

def main():
    file_path = r"d:\Proyectos\Gimnasio_app\backend\app\routers\rutinas.py"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Add ClienteRutinaProgreso import if not present
    if "ClienteRutinaProgreso" not in content:
        content = content.replace("from app.models.rutina import Rutina, RutinaEjercicio, ClienteRutina",
                                  "from app.models.rutina import Rutina, RutinaEjercicio, ClienteRutina, ClienteRutinaProgreso")

    # 2. Modify construir_detalle_rutina to accept cliente_rutina_id and map progress
    # from: def construir_detalle_rutina(db: Session, rutina: Rutina) -> RutinaDetalleResponse:
    # to: def construir_detalle_rutina(db: Session, rutina: Rutina, cliente_rutina_id: int = None) -> RutinaDetalleResponse:
    target_func = "def construir_detalle_rutina(db: Session, rutina: Rutina) -> RutinaDetalleResponse:"
    if target_func in content:
        new_func = """def construir_detalle_rutina(db: Session, rutina: Rutina, cliente_rutina_id: int = None) -> RutinaDetalleResponse:
    items = (
        db.query(RutinaEjercicio, Ejercicio)
        .join(Ejercicio, Ejercicio.id == RutinaEjercicio.ejercicio_id)
        .filter(RutinaEjercicio.rutina_id == rutina.id)
        .order_by(RutinaEjercicio.dia.asc(), RutinaEjercicio.orden.asc(), RutinaEjercicio.id.asc())
        .all()
    )

    progreso_dict = {}
    if cliente_rutina_id:
        progresos = db.query(ClienteRutinaProgreso).filter(ClienteRutinaProgreso.cliente_rutina_id == cliente_rutina_id).all()
        for p in progresos:
            progreso_dict[p.rutina_ejercicio_id] = p.cumplido

    ejercicios = []
    for re_obj, ejr in items:
        cumplido = progreso_dict.get(re_obj.id, False)
        ejercicios.append(
            RutinaEjercicioResponse(
                id=re_obj.id,
                ejercicio_id=ejr.id,
                nombre=ejr.nombre,
                grupo_muscular=ejr.grupo_muscular,
                descripcion=ejr.descripcion,
                instrucciones=ejr.instrucciones,
                imagen_url=ejr.imagen_url,
                gif_url=ejr.gif_url,
                video_url=ejr.video_url,
                dia=re_obj.dia,
                orden=re_obj.orden,
                series=re_obj.series,
                repeticiones=re_obj.repeticiones,
                descanso=re_obj.descanso,
                observaciones=re_obj.observaciones,
                cumplido=cumplido,
            )
        )

    return RutinaDetalleResponse(
        id=rutina.id,
        nombre=rutina.nombre,
        objetivo=rutina.objetivo,
        descripcion=rutina.descripcion,
        nivel=rutina.nivel,
        activa=rutina.activa,
        ejercicios=ejercicios,
    )"""
        # We need to replace the whole body of the function. Let's find the end of it.
        # It ends right before "@router.get" or something similar.
        start_idx = content.find(target_func)
        end_idx = content.find("@router.get", start_idx)
        if end_idx != -1:
            content = content[:start_idx] + new_func + "\n\n" + content[end_idx:]

    # 3. Fix the calls to construir_detalle_rutina
    content = content.replace("rutina=construir_detalle_rutina(db, rutina),", "rutina=construir_detalle_rutina(db, rutina, cliente_rutina.id),")
    content = content.replace("rutina=construir_detalle_rutina(db, r),", "rutina=construir_detalle_rutina(db, r, cr.id),")

    # 4. Fix /cumplir endpoint
    cumplir_endpoint = """@router.post("/cliente-rutina/{cliente_rutina_id}/ejercicio/{rutina_ejercicio_id}/cumplir")
def cumplir_ejercicio_cliente(
    cliente_rutina_id: int,
    rutina_ejercicio_id: int,
    db: Session = Depends(get_db),
):
    cliente_rutina = (
        db.query(ClienteRutina)
        .filter(ClienteRutina.id == cliente_rutina_id)
        .first()
    )

    if not cliente_rutina:
        raise HTTPException(status_code=404, detail="Asignación de rutina no encontrada")

    rutina_ejercicio = (
        db.query(RutinaEjercicio)
        .filter(
            RutinaEjercicio.id == rutina_ejercicio_id,
            RutinaEjercicio.rutina_id == cliente_rutina.rutina_id,
        )
        .first()
    )

    if not rutina_ejercicio:
        raise HTTPException(status_code=404, detail="Ejercicio no encontrado en la rutina")

    # Guardar en ClienteRutinaProgreso
    from sqlalchemy.sql import func
    progreso = db.query(ClienteRutinaProgreso).filter(
        ClienteRutinaProgreso.cliente_rutina_id == cliente_rutina_id,
        ClienteRutinaProgreso.rutina_ejercicio_id == rutina_ejercicio_id
    ).first()

    if progreso:
        progreso.cumplido = True
        progreso.fecha_cumplido = func.now()
    else:
        nuevo_progreso = ClienteRutinaProgreso(
            cliente_rutina_id=cliente_rutina_id,
            rutina_ejercicio_id=rutina_ejercicio_id,
            cumplido=True,
            fecha_cumplido=func.now()
        )
        db.add(nuevo_progreso)

    db.commit()

    # Verificar si todos están cumplidos
    total_ejercicios = db.query(RutinaEjercicio).filter(RutinaEjercicio.rutina_id == cliente_rutina.rutina_id).count()
    cumplidos = db.query(ClienteRutinaProgreso).filter(
        ClienteRutinaProgreso.cliente_rutina_id == cliente_rutina_id,
        ClienteRutinaProgreso.cumplido == True
    ).count()

    if cumplidos >= total_ejercicios and total_ejercicios > 0:
        cliente_rutina.completada = True
        db.commit()

    return {"ok": True, "mensaje": "Ejercicio marcado como cumplido"}
"""
    # Replace old /cumplir block
    start_cumplir = content.find('@router.post("/cliente-rutina/{cliente_rutina_id}/ejercicio/{rutina_ejercicio_id}/cumplir")')
    if start_cumplir != -1:
        end_cumplir = content.find("@router.get", start_cumplir)
        if end_cumplir == -1: # Last function in file
            content = content[:start_cumplir] + cumplir_endpoint
        else:
            content = content[:start_cumplir] + cumplir_endpoint + "\n" + content[end_cumplir:]

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
        
    print("Backend patched")

if __name__ == "__main__":
    main()
