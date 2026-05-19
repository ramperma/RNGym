from app.repositories.exercise_repository import list_exercises
from app.repositories.user_repository import (
    create_user,
    email_exists,
    get_user_by_email,
    get_user_by_id,
    update_last_login,
    user_is_admin,
)
from app.repositories.perfil_salud_repository import create_or_update_perfil, delete_perfil, get_perfil_by_usuario
from app.repositories.rutina_repository import (
    create_rutina,
    delete_rutina,
    get_rutina_by_id,
    get_rutina_for_execute,
    list_rutinas,
    update_rutina,
)
from app.repositories.sesion_repository import (
    create_sesion,
    delete_sesion,
    get_registros_by_sesion,
    get_sesion_by_id,
    list_sesiones,
    registrar_sets,
    update_sesion,
)
from app.repositories.registro_diario_repository import (
    get_registro_by_fecha,
    list_registros,
    upsert_registro_diario,
)
from app.repositories.admin_repository import create_admin_user, get_stats, list_all_users, update_admin_user
from app.repositories.maquina_gym_repository import (
    create_maquina,
    delete_maquina,
    get_maquina_by_id,
    list_maquinas,
    update_maquina,
)
from app.repositories.plan_semanal_repository import (
    create_plan_semanal,
    deactivate_plan,
    delete_plan_semanal,
    get_plan_by_id,
    list_planes_semanales,
    update_plan_semanal,
)

__all__ = [
    "list_exercises",
    "create_user",
    "email_exists",
    "get_user_by_email",
    "get_user_by_id",
    "update_last_login",
    "user_is_admin",
    "create_or_update_perfil",
    "delete_perfil",
    "get_perfil_by_usuario",
    "create_rutina",
    "delete_rutina",
    "get_rutina_by_id",
    "get_rutina_for_execute",
    "list_rutinas",
    "update_rutina",
    "create_sesion",
    "delete_sesion",
    "get_registros_by_sesion",
    "get_sesion_by_id",
    "list_sesiones",
    "registrar_sets",
    "update_sesion",
    "get_registro_by_fecha",
    "list_registros",
    "upsert_registro_diario",
    "create_admin_user",
    "get_stats",
    "list_all_users",
    "update_admin_user",
    "create_maquina",
    "delete_maquina",
    "get_maquina_by_id",
    "list_maquinas",
    "update_maquina",
    "create_plan_semanal",
    "deactivate_plan",
    "delete_plan_semanal",
    "get_plan_by_id",
    "list_planes_semanales",
    "update_plan_semanal",
]
