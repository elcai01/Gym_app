from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.usuario import Usuario
from app.models.cliente import Cliente
from app.models.rol import Rol
from app.core.security import get_password_hash

def main():
    db: Session = SessionLocal()
    try:
        usuarios = db.query(Usuario).all()
        modificados = 0
        for user in usuarios:
            # Check if it's already hashed (bcrypt hashes start with $2b$ or $2a$)
            if user.password_hash and not str(user.password_hash).startswith("$2b$"):
                print(f"Hasheando contraseña para usuario: {user.username}")
                try:
                    pw = str(user.password_hash)[:72]
                    user.password_hash = get_password_hash(pw)
                    modificados += 1
                except Exception as e:
                    print(f"Error con usuario {user.username}: {e}")
        
        if modificados > 0:
            db.commit()
            print(f"Se han migrado {modificados} contraseñas exitosamente.")
        else:
            print("No se encontraron contraseñas en texto plano. Todas están seguras.")
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    main()
