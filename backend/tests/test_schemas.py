import pytest
import pydantic
from datetime import datetime
from app.schemas.auth import UserCreate, UserLogin, RefreshRequest, RegisterResponse
from app.schemas.perfil_salud import PerfilSaludCreate, PerfilSaludUpdate
from app.schemas.rutina import RutinaCreate, RutinaEjercicioCreate, RutinaUpdate
from app.schemas.sesion import SesionEntrenoCreate, SesionEntrenoUpdate, RegistrarSetsRequest, SesionEjercicioRegistroCreate
from app.schemas.registro_diario import RegistroDiarioUpdate
from app.schemas.admin import AdminUserCreate, AdminUserUpdate
from app.schemas.plan_semanal import AIWeeklyPlanRequest


class TestAuthSchemas:
    def test_user_create_valid(self):
        u = UserCreate(email="test@test.com", password="Test1234Aa", nombre="Test", apellidos="User")
        assert u.email == "test@test.com"
        assert u.nombre == "Test"

    def test_user_create_invalid_email(self):
        with pytest.raises(pydantic.ValidationError):
            UserCreate(email="not-an-email", password="Test1234Aa", nombre="Test")

    def test_user_login_schema(self):
        login = UserLogin(email="user@test.com", password="password")
        assert login.email == "user@test.com"

    def test_refresh_request_schema(self):
        req = RefreshRequest(refresh_token="some-token")
        assert req.refresh_token == "some-token"


class TestPerfilSaludSchema:
    def test_perfil_salud_create_minimal(self):
        p = PerfilSaludCreate()
        assert p.fecha_nacimiento is None
        assert p.altura_cm is None
        assert p.consentimiento_salud is False

    def test_perfil_salud_create_full(self):
        from datetime import date
        p = PerfilSaludCreate(
            fecha_nacimiento=date(1990, 5, 15),
            sexo_biologico="M",
            altura_cm=180.5,
            peso_actual_kg=80.0,
            consentimiento_salud=True,
            lesiones=["rodilla"],
        )
        assert p.fecha_nacimiento.year == 1990
        assert p.sexo_biologico == "M"
        assert p.lesiones == ["rodilla"]

    def test_perfil_salud_update_partial(self):
        u = PerfilSaludUpdate(peso_actual_kg=79.5)
        assert u.peso_actual_kg == 79.5
        assert u.altura_cm is None


class TestRutinaSchema:
    def test_rutina_create_with_ejercicios(self):
        r = RutinaCreate(
            nombre="Pierna Lunes",
            tipo_rutina="fuerza",
            ejercicios=[
                RutinaEjercicioCreate(ejercicio_id="ex-001", orden=1, series=3, repeticiones="10-12")
            ],
        )
        assert r.nombre == "Pierna Lunes"
        assert len(r.ejercicios) == 1
        assert r.ejercicios[0].series == 3

    def test_rutina_update_partial(self):
        u = RutinaUpdate(nombre="Nuevo nombre")
        assert u.nombre == "Nuevo nombre"
        assert u.tipo_rutina is None


class TestSesionSchema:
    def test_sesion_entreno_create_defaults(self):
        s = SesionEntrenoCreate(fecha_inicio=datetime(2026, 4, 20, 18, 0, 0))
        assert s.estado == "planificada"
        assert s.rutina_id is None

    def test_registrar_sets_request(self):
        req = RegistrarSetsRequest(
            ejercicio_id="ex-001",
            registros=[
                SesionEjercicioRegistroCreate(set_numero=1, peso_kg=60.0, repeticiones=12, rpe=7),
                SesionEjercicioRegistroCreate(set_numero=2, peso_kg=60.0, repeticiones=10, rpe=8),
            ],
        )
        assert len(req.registros) == 2
        assert req.registros[0].set_numero == 1

    def test_sesion_update_partial(self):
        u = SesionEntrenoUpdate(estado="completada")
        assert u.estado == "completada"
        assert u.nombre is None


class TestRegistroDiarioSchema:
    def test_registro_diario_update_partial(self):
        r = RegistroDiarioUpdate(peso_kg=78.5, nivel_energia=8)
        assert r.peso_kg == 78.5
        assert r.nivel_energia == 8
        assert r.kcal_consumidas is None


class TestAdminSchema:
    def test_admin_user_create(self):
        u = AdminUserCreate(email="admin@test.com", password="Admin123!", nombre="Admin", rol="admin")
        assert u.rol == "admin"

    def test_admin_user_update_partial(self):
        u = AdminUserUpdate(rol="entrenador", esta_activo=False)
        assert u.rol == "entrenador"
        assert u.esta_activo is False

    def test_admin_user_create_default_rol(self):
        u = AdminUserCreate(email="user@test.com", password="User123!", nombre="User")
        assert u.rol == "usuario"


class TestAIWeeklyPlanRequestSchema:
    def test_weekly_plan_request_valid_percentages(self):
        r = AIWeeklyPlanRequest(
            objetivo="hipertrofia",
            porcentaje_maquinas_guiadas=40,
            porcentaje_peso_libre=60,
        )
        assert r.porcentaje_maquinas_guiadas == 40
        assert r.porcentaje_peso_libre == 60

    def test_weekly_plan_request_invalid_percentages(self):
        with pytest.raises(pydantic.ValidationError):
            AIWeeklyPlanRequest(
                objetivo="hipertrofia",
                porcentaje_maquinas_guiadas=120,
            )

        with pytest.raises(pydantic.ValidationError):
            AIWeeklyPlanRequest(
                objetivo="hipertrofia",
                porcentaje_peso_libre=-5,
            )