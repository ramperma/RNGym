from sqlalchemy.orm import Session
from app.db.session import engine
from app.models.usuario import Usuario
from app.core.security import hash_password
from sqlalchemy import select, text

def seed_user():
    with Session(engine) as session:
        # Check if user exists
        result = session.execute(select(Usuario).where(Usuario.email == "r.perez@ramnet.es"))
        user = result.scalar_one_or_none()
        
        if not user:
            print("Creating user r.perez@ramnet.es...")
            import uuid
            user_id = str(uuid.uuid4())
            session.execute(
                text("""
                    INSERT INTO usuarios (
                        id, email, hashed_password, nombre, rol, consentimiento_gdpr,
                        idioma, timezone, email_verificado, fecha_alta, esta_activo,
                        consentimiento_marketing, version_politica_privacidad, permitir_ia,
                        max_rutinas, max_sesiones_semana
                    ) VALUES (
                        :id, :email, :hashed_password, :nombre, CAST(:rol AS rol_usuario), :consentimiento_gdpr,
                        'es', 'Europe/Madrid', false, NOW(), true,
                        false, '1.0', true, 5, 7
                    )
                """),
                {
                    "id": user_id,
                    "email": "r.perez@ramnet.es",
                    "hashed_password": hash_password("EstoEsUnaPrueba"),
                    "nombre": "Ramón",
                    "rol": "admin",
                    "consentimiento_gdpr": True
                }
            )
            session.commit()
            print("User created successfully.")
        else:
            print("User already exists.")

if __name__ == "__main__":
    seed_user()
