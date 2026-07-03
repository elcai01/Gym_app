import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.database import SessionLocal
from sqlalchemy import text

def main():
    db = SessionLocal()
    try:
        print("=== ALL RUTINAS ===")
        res = db.execute(text("SELECT id, nombre, objetivo, descripcion, nivel, activa FROM rutinas;")).fetchall()
        for r in res:
            print(r)
            
        print("\n=== SEARCHING FOR 8062 ===")
        res2 = db.execute(text("SELECT id, nombre FROM rutinas WHERE nombre LIKE '%8062%';")).fetchall()
        for r in res2:
            print(r)
            
    finally:
        db.close()

if __name__ == "__main__":
    main()
