import os
import sys

# Agregar el directorio de la app al path para poder importar módulos
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.database import SessionLocal, engine
from sqlalchemy import text

def main():
    db = SessionLocal()
    try:
        # Consulta 1: Ver todos los registros de rutinas asignadas a los clientes
        print("--- CLIENTE_RUTINAS ---")
        res1 = db.execute(text("""
            SELECT cr.id, cr.cliente_id, cr.rutina_id, cr.activa, cr.completada, r.nombre
            FROM cliente_rutinas cr
            JOIN rutinas r ON r.id = cr.rutina_id
            ORDER BY cr.id DESC LIMIT 20;
        """)).fetchall()
        for row in res1:
            print(row)

        print("\n--- CLIENTE_RUTINA_PROGRESO ---")
        res2 = db.execute(text("""
            SELECT * FROM cliente_rutina_progreso ORDER BY id DESC LIMIT 20;
        """)).fetchall()
        for row in res2:
            print(row)

        print("\n--- DIAGNOSTICO COMPLETO ---")
        res3 = db.execute(text("""
            SELECT 
                cr.id AS asignacion_id,
                cr.cliente_id,
                cr.activa,
                cr.completada,
                re.id AS rutina_ejercicio_id,
                e.nombre AS ejercicio,
                COALESCE(p.cumplido, false) AS cumplido
            FROM cliente_rutinas cr
            JOIN rutina_ejercicios re ON re.rutina_id = cr.rutina_id
            JOIN ejercicios e ON e.id = re.ejercicio_id
            LEFT JOIN cliente_rutina_progreso p 
                ON p.cliente_rutina_id = cr.id 
                AND p.rutina_ejercicio_id = re.id
            WHERE cr.activa = true
            ORDER BY cr.id DESC, re.orden
            LIMIT 30;
        """)).fetchall()
        for row in res3:
            print(row)
            
    finally:
        db.close()

if __name__ == "__main__":
    main()
