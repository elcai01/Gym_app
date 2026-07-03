import os
import sys

# Agregar el directorio de la app al path para poder importar módulos
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.database import SessionLocal
from app.models.rol import Rol
from app.models.usuario import Usuario

def main():
    db = SessionLocal()
    roles = db.query(Rol).all()
    print("ROLES:")
    for r in roles:
        print(f" - {r.id}: {r.nombre}")
        
    usuarios = db.query(Usuario).all()
    print("\nUSUARIOS:")
    for u in usuarios:
        rol_nombre = next((r.nombre for r in roles if r.id == u.rol_id), "N/A")
        print(f" - {u.id}: {u.username} (Rol: {rol_nombre})")
        
if __name__ == "__main__":
    main()
