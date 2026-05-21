import streamlit as st
import pandas as pd
from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import Session
import sys
import os
from dotenv import load_dotenv

# Añadir el backend al path para poder importar los modelos
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend')))

from app.models.usuario import Usuario
from app.models.perfil_salud import PerfilSalud
from app.core.security import hash_password

# Cargar variables de entorno
load_dotenv(os.path.join(os.path.dirname(__file__), '..', 'backend', '.env'))

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    st.error("No se encontró DATABASE_URL en el archivo .env del backend.")
    st.stop()

engine = create_engine(DATABASE_URL)

st.set_page_config(page_title="Gym Trainer - Admin Panel", page_icon="🏋️‍♂️", layout="wide")

st.sidebar.title("Gym Trainer Admin")
page = st.sidebar.selectbox("Navegación", ["Dashboard", "Gestión de Usuarios", "Límites y Configuración"])

if page == "Dashboard":
    st.title("📊 Dashboard de Control")
    
    with Session(engine) as session:
        total_users = session.query(Usuario).count()
        active_users = session.query(Usuario).filter(Usuario.esta_activo == True).count()
        total_routines = session.execute(text("SELECT count(*) FROM rutinas")).scalar()
        total_ai_plans = session.execute(text("SELECT count(*) FROM planes_semanales")).scalar()
        
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Usuarios Totales", total_users)
    col2.metric("Usuarios Activos", active_users)
    col3.metric("Rutinas Creadas", total_routines)
    col4.metric("Planes IA Activos", total_ai_plans)
    
    st.subheader("Usuarios Recientes")
    with Session(engine) as session:
        recent_users = session.query(Usuario).order_by(Usuario.fecha_alta.desc()).limit(5).all()
        df_recent = pd.DataFrame([{
            "Nombre": u.nombre,
            "Email": u.email,
            "Rol": u.rol,
            "Fecha Alta": u.fecha_alta
        } for u in recent_users])
        st.table(df_recent)

elif page == "Gestión de Usuarios":
    st.title("👥 Gestión de Usuarios")
    
    with Session(engine) as session:
        users = session.query(Usuario).all()
        df_users = pd.DataFrame([{
            "ID": u.id,
            "Email": u.email,
            "Nombre": u.nombre,
            "Rol": u.rol,
            "Activo": u.esta_activo
        } for u in users])
        
    st.dataframe(df_users, use_container_width=True)
    
    st.divider()
    
    with st.expander("➕ Crear Nuevo Usuario"):
        with st.form("new_user_form"):
            new_email = st.text_input("Email")
            new_name = st.text_input("Nombre")
            new_pass = st.text_input("Contraseña", type="password")
            new_role = st.selectbox("Rol", ["usuario", "entrenador", "admin"])
            submit = st.form_submit_button("Crear Usuario")
            
            if submit:
                errores = []
                if not new_email.strip():
                    errores.append("El email es obligatorio.")
                if not new_name.strip():
                    errores.append("El nombre es obligatorio.")
                if not new_pass:
                    errores.append("La contraseña es obligatoria.")
                if errores:
                    for err in errores:
                        st.warning(err, icon="⚠️")
                    st.stop()

                with Session(engine) as session:
                    existing = session.execute(text("SELECT 1 FROM usuarios WHERE email = :email"), {"email": new_email}).fetchone()
                    if existing:
                        st.error(f"⚠️ El email **{new_email}** ya está registrado. No se puede duplicar.", icon="🚫")
                        st.stop()

                    hashed = hash_password(new_pass)
                    from uuid import uuid4
                    from datetime import datetime
                    try:
                        session.execute(
                            text("""
                                INSERT INTO usuarios (
                                    id, email, hashed_password, nombre, apellidos, rol, idioma, timezone,
                                    email_verificado, fecha_alta, esta_activo, consentimiento_gdpr,
                                    consentimiento_marketing, version_politica_privacidad, permitir_ia,
                                    max_rutinas, max_sesiones_semana
                                ) VALUES (
                                    :id, :email, :hashed_password, :nombre, :apellidos,
                                    CAST(:rol AS rol_usuario), 'es', 'Europe/Madrid', false,
                                    :fecha_alta, true, true, false, '1.0', true, 5, 7
                                )
                            """),
                            {
                                "id": str(uuid4()),
                                "email": new_email,
                                "hashed_password": hashed,
                                "nombre": new_name,
                                "apellidos": None,
                                "rol": new_role,
                                "fecha_alta": datetime.now(),
                            },
                        )
                        session.commit()
                        st.success(f"✅ Usuario **{new_name}** ({new_email}) creado correctamente.")
                        st.rerun()
                    except Exception as e:
                        err_msg = str(e)
                        if "unique constraint" in err_msg.lower() or "already exists" in err_msg.lower():
                            st.error(f"🚫 El email **{new_email}** ya está registrado.")
                        else:
                            st.error(f"❌ Error inesperado al crear usuario: {err_msg}")

    st.subheader("✏️ Editar / Desactivar Usuario")
    
    # Buscador de usuarios reactivo
    search_query = st.text_input("🔍 Buscar usuario (por Nombre, Email o Rol):", "", placeholder="Escribe para buscar...")
    
    filtered_users = users
    if search_query.strip():
        q = search_query.lower().strip()
        filtered_users = [
            u for u in users
            if q in u.email.lower() or (u.nombre and q in u.nombre.lower()) or q in u.rol.lower()
        ]
        
    if not filtered_users:
        st.warning("⚠️ No se encontraron usuarios con ese criterio de búsqueda.")
        selected_user = None
    else:
        user_emails = [u.email for u in filtered_users]
        selected_email = st.selectbox("Selecciona el email del usuario que deseas modificar:", user_emails)
        selected_user = next(u for u in filtered_users if u.email == selected_email)
        
    if selected_user is not None:
        with st.form("edit_user_form"):
            edit_name = st.text_input("Nombre", value=selected_user.nombre or "")
            edit_role = st.selectbox("Rol", ["usuario", "entrenador", "admin"], index=["usuario", "entrenador", "admin"].index(selected_user.rol))
            edit_active = st.checkbox("Activo", value=selected_user.esta_activo)
            
            st.subheader("Configuración de IA")
            
            # Un solo switch para activar/desactivar el uso de IA
            edit_permitir_ia = st.checkbox("Permitir uso de Inteligencia Artificial (IA)", value=selected_user.permitir_ia)
            
            col1, col2 = st.columns(2)
            edit_max_r = col1.number_input("Máx Rutinas", value=selected_user.max_rutinas, min_value=1)
            edit_max_s = col2.number_input("Máx Sesiones/Semana", value=selected_user.max_sesiones_semana, min_value=1)
            
            update = st.form_submit_button("Actualizar Usuario")
            
            if update:
                with Session(engine) as session:
                    session.execute(
                        text("""
                            UPDATE usuarios
                            SET nombre = :nombre,
                                rol = CAST(:rol AS rol_usuario),
                                esta_activo = :esta_activo,
                                permitir_ia = :permitir_ia,
                                max_rutinas = :max_rutinas,
                                max_sesiones_semana = :max_sesiones_semana
                            WHERE id = :id
                        """),
                        {
                            "nombre": edit_name,
                            "rol": edit_role,
                            "esta_activo": edit_active,
                            "permitir_ia": edit_permitir_ia,
                            "max_rutinas": edit_max_r,
                            "max_sesiones_semana": edit_max_s,
                            "id": selected_user.id,
                        },
                    )
                    session.commit()
                    st.success("Usuario actualizado correctamente.")
                    st.rerun()

elif page == "Límites y Configuración":
    st.title("⚙️ Límites y Configuración del Sistema")
    
    st.info("Aquí podrás configurar los límites globales y las suscripciones de los usuarios.")
    
    st.subheader("Configuración de IA")
    system_openai_key = st.text_input("OpenAI System API Key (Global)", type="password", help="Esta es la llave que usa la aplicación por defecto.")
    if st.button("Guardar Configuración IA"):
        st.success("Configuración guardada (Simulado - falta tabla de config global)")

    st.subheader("Límites por Usuario (Propuesta)")
    st.write("Configura cuántas rutinas puede tener un usuario estándar:")
    max_routines = st.number_input("Max Rutinas", min_value=1, max_value=100, value=5)
    st.button("Actualizar Límites Globales")
