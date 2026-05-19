from sqlalchemy.orm import Session
from app.db.session import engine
from app.models.usuario import Usuario
from app.core.security import hash_password
from sqlalchemy import select

def seed_user():
    with Session(engine) as session:
        # Check if user exists
        result = session.execute(select(Usuario).where(Usuario.email == "r.perez@ramnet.es"))
        user = result.scalar_one_or_none()
        
        if not user:
            print("Creating user r.perez@ramnet.es...")
            new_user = Usuario(
                email="r.perez@ramnet.es",
                hashed_password=hash_password("EstoEsUnaPrueba"),
                nombre="Ramón",
                rol="admin",
                consentimiento_gdpr=True
            )
            session.add(new_user)
            session.commit()
            print("User created successfully.")
        else:
            print("User already exists.")

if __name__ == "__main__":
    seed_user()
