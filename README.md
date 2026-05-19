# Gym Trainer App

Estado actual: aplicación real arrancable en esta Raspberry, con backend FastAPI sobre PostgreSQL y Flutter compilando para Linux desktop.

## Decisión de repositorio
Se publica como **monorepo**.

Motivo: backend, app Flutter, SQL y documentación siguen siendo un solo producto con releases acopladas. Separarlo ahora añadiría fricción sin beneficio claro.

Referencia breve: `docs/repository-strategy.md`.

## Qué incluye

### Backend (`backend/`)
- FastAPI con estructura modular por `app/`
- Variables de entorno con `.env.example`
- PostgreSQL real mediante SQLAlchemy + psycopg
- **Migraciones con Alembic** (`alembic/`): schema completo versionado
- Endpoints iniciales:
  - `GET /`
  - `GET /api/v1/health`
  - `GET /api/v1/exercises`
  - `GET /api/v1/exercises/{id}`
  - `GET /api/v1/workout-sessions`
  - `GET /api/v1/workout-sessions/{id}`
  - `POST /api/v1/workout-sessions`
  - `GET /api/v1/user-profile`
  - `PUT /api/v1/user-profile`
  - `GET /api/v1/ai/status`
- `docker-compose.yml` para levantar PostgreSQL local
- Modelos SQLAlchemy completos en `app/models/` (sin nutrición)

### Flutter (`flutter_app/`)
- App Flutter compilable en Linux desktop y Android
- Lista real de ejercicios desde backend
- Detalle real de ejercicio
- Guardado real de sesión de entrenamiento y refresco automático de la lista
- Historial visible de sesiones persistidas en PostgreSQL
- Pestaña de perfil/configuración con datos personales relevantes para personalización futura
- Estado IA visible desde backend, sin guardar claves sensibles en la app

## Estructura

```text
backend/
  app/
    api/
    core/
    db/
    models/
    repositories/
  alembic/
    versions/
  db/schema.sql          # legacy, superseded by alembic/
  docker-compose.yml
flutter_app/
docs/
Makefile
README.md
```

## Arranque rápido

### Backend

```bash
cp backend/.env.example backend/.env
make backend-install
make backend-up
make migrate-up           # aplicar migraciones (primera vez: crea todo el schema)
make backend-run
```

Si no necesitas recrear volumen porque partes de cero, `make backend-up` también vale.

Checks:

```bash
make backend-check
make migrate-status       # ver estado de migraciones
```

Demo web local:

```bash
xdg-open http://localhost:8000/app
```

Ejemplo manual:

```bash
curl http://localhost:8000/api/v1/exercises/ex-001
```

### Flutter

```bash
cd flutter_app
PATH=/home/ramni/sdk/flutter/bin:$PATH flutter pub get
PATH=/home/ramni/sdk/flutter/bin:$PATH flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

Para Android Emulator:

```bash
PATH=/home/ramni/sdk/flutter/bin:$PATH flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Build validada en esta Raspberry:

```bash
cd flutter_app
PATH=/home/ramni/sdk/flutter/bin:$PATH flutter build linux --debug --dart-define=API_BASE_URL=http://localhost:8000/api/v1
./build/linux/arm64/debug/bundle/gym_trainer_app
```

## Qué funciona ya
- Backend sirviendo ejercicios desde PostgreSQL real con schema completo (Alembic).
- Migraciones versionadas: `make migrate-up` / `migrate-down`.
- Schema completo sin nutrición: usuarios, perfiles_salud, rutinas, sesiones_entreno, registro_diario, logs_ia.
- Seed de ejercicios con datos de ejemplo.
- Healthcheck validando conexión a base de datos.
- Flutter preparado para consumir esos datos con una UI base más sólida.
- Repo listo para publicarse como monorepo.

## Limitaciones reales ahora mismo
- No hay auth ni usuarios todavía (gestión de usuarios será desde frontend PC admin).
- No hay tests automáticos aún.
- Docker no disponible en este entorno de build.

## Siguiente paso recomendado (Fase 2)
1. Auth completo: register/login/refresh/logout con JWT.
2. Aislamiento de datos por usuario (RLS + contexto por request).
3. Endpoints CRUD de perfil salud, rutinas y sesiones.
