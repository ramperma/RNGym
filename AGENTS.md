# AGENTS.md

## Repo shape (monorepo)
Three runnable parts, each with its own venv:
- `backend/`: FastAPI + SQLAlchemy + PostgreSQL (venv: `backend/.venv`)
- `flutter_app/`: Flutter client consuming backend `/api/v1`
- `admin_panel/`: Streamlit admin UI (venv: `admin_panel/.venv`)

Backend entrypoint: `backend/app/main.py` (`app.main:app`)

## Backend: required local flow
Use repo-root Make targets (they `cd backend` internally):
1. `cp backend/.env.example backend/.env`
2. `make backend-install`
3. `make backend-up` (starts Postgres from `backend/docker-compose.yml`)
4. **`make migrate-up`** (first time only — creates full schema via Alembic)
5. `make backend-run` (uvicorn with reload on `:8000`)

Quick verification:
- `make backend-check` (hits `/api/v1/health` and `/api/v1/exercises`)

## Migration management
- `make migrate-up` / `migrate-down` / `make migrate-status`
- New migration: `make migrate-create MSG="description"` then edit the generated file in `backend/alembic/versions/`
- **Migration files are source of truth** — never edit `backend/db/schema.sql` for new tables; edit models + generate a migration via Alembic.
- Current migrations: check `backend/alembic/versions/` directly (5+ as of May 2026).

## Backend behavior easy to miss
- `.env` is loaded via `pydantic-settings` with `env_file=".env"` in `app/core/config.py:22`; run from `backend/` (or via Make) so `.env` is found.
- `/api/v1/health` executes `SELECT 1` through SQLAlchemy — DB must be running.
- Exercises come from `ejercicios` table (UUID PKs), via `app/repositories/exercise_repository.py`.
- Auth is implemented (JWT: register/login/refresh/logout/me via `app/api/v1/auth.py:13-65`).
- `backend/db/schema.sql` is LEGACY — it's still mounted as an init script in `docker-compose.yml:13`, but new tables must only be created via Alembic migrations.
- `seed_user.py` creates an admin user (`r.perez@ramnet.es`); run manually after `migrate-up`.

## RLS (Row-Level Security)
- RLS policies exist on `perfiles_salud`, `rutinas`, `sesiones_entreno`, `registros_diarios`, plus a read-only policy on `ejercicios`.
- `RLSContextMiddleware` (`app/middleware/rlsmiddleware.py`) sets `app.current_user_id` via `SET` on a raw `engine.connect()` connection per request — the setting is session-scoped. **The middleware opens a separate raw connection from the pool, not the same connection used by `Session(engine)` in handlers.**
- RLS policies use `current_setting('app.current_user_id', TRUE)` which returns NULL when unset.

## Backend tests
- `make test-backend` runs `pytest tests/ -v` from `backend/` with `PYTHONPATH=.`
- `pytest.ini` sets `pythonpath = .`, `asyncio_mode = strict`
- `conftest.py` only provides `anyio_backend` fixture — no DB fixtures. Tests are unit tests (security, AI, schemas), no integration tests requiring Postgres.
- Run single test file: `cd backend && PYTHONPATH=. .venv/bin/pytest tests/test_security.py -v`

## Admin panel
- `make admin-run` starts Streamlit from `admin_panel/main.py`
- Reads `DATABASE_URL` from `backend/.env` (not its own env file), via `python-dotenv` in `admin_panel/main.py:17`.
- Uses `hash_password` from `app.core.security` — depends on backend being on `sys.path`.

## Flutter: bootstrap/run
- `flutter_app/` is a skeleton; generate platform files first: `make flutter-bootstrap`
- Run with explicit backend URL:
  - Desktop/iOS simulator: `flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1`
  - Android emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1`
- API base is compile-time (`String.fromEnvironment`) in `flutter_app/lib/core/env.dart`; changing URL requires rerun with `--dart-define`.

## Verification
- Backend smoke: `make backend-check`
- Flutter smoke: run app and confirm exercise list loads from `/api/v1/exercises`
- No Python lint/typecheck pipeline configured; no pre-commit hooks.
- Note: `README.md` is stale (claims no auth, no tests — both exist). Trust the code over README.