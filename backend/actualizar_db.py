import sys
import os

# Asegurar que el directorio raíz del backend esté en el PYTHONPATH
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine, text
from app.database import DATABASE_URL

def main():
    print(f"Conectando a la base de datos: {DATABASE_URL}...")
    try:
        engine = create_engine(DATABASE_URL)
        with engine.connect() as connection:
            trans = connection.begin()
            try:
                # 1. Agregar huella_id si no existe
                print("Verificando/Agregando columna 'huella_id'...")
                connection.execute(text("ALTER TABLE clientes ADD COLUMN IF NOT EXISTS huella_id INTEGER;"))
                
                # 2. Intentar crear restricciones UNIQUE si no existen
                print("Creando índice/restricción de unicidad para huella_id...")
                try:
                    connection.execute(text("ALTER TABLE clientes ADD CONSTRAINT uq_clientes_huella_id UNIQUE (huella_id);"))
                except Exception as e:
                    print("Nota: La restricción UNIQUE para huella_id ya existía o no se pudo crear.")
                
                # 3. Crear tabla log_mensajes para WhatsApp
                print("Creando tabla 'log_mensajes' para WhatsApp si no existe...")
                connection.execute(text("""
                    CREATE TABLE IF NOT EXISTS log_mensajes (
                        id SERIAL PRIMARY KEY,
                        cliente_id INTEGER NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
                        tipo VARCHAR(50) NOT NULL,
                        fecha DATE NOT NULL,
                        mensaje TEXT NOT NULL,
                        estado VARCHAR(20) NOT NULL DEFAULT 'ENVIADO',
                        creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
                """))
                
                print("Creando índice para fecha en log_mensajes...")
                connection.execute(text("CREATE INDEX IF NOT EXISTS idx_log_mensajes_fecha ON log_mensajes(fecha);"))
                
                trans.commit()
                print("\n¡Base de datos actualizada con éxito! No se borró ningún dato existente.")
            except Exception as inner_e:
                trans.rollback()
                raise inner_e
                
    except Exception as e:
        print(f"\n[ERROR] No se pudo actualizar la base de datos: {e}")

if __name__ == "__main__":
    main()
