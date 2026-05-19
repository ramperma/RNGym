PYTHON ?= python3
VENV ?= backend/.venv
UVICORN ?= $(VENV)/bin/uvicorn
PIP ?= $(VENV)/bin/pip
ALEMBIC ?= $(VENV)/bin/alembic

.PHONY: backend-install backend-up backend-run backend-check flutter-bootstrap migrate-up migrate-down migrate-create migrate-status

backend-install:
	cd backend && $(PYTHON) -m venv .venv && .venv/bin/pip install -r requirements.txt

backend-up:
	cd backend && docker compose up -d

backend-reset-db:
	cd backend && docker compose down -v && docker compose up -d

backend-run:
	cd backend && .venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

backend-check:
	curl -fsS http://localhost:8000/api/v1/health && echo
	curl -fsS http://localhost:8000/api/v1/exercises && echo
	curl -fsS http://localhost:8000/api/v1/exercises/ex-001 && echo

migrate-up:
	cd backend && .venv/bin/alembic upgrade head

migrate-down:
	cd backend && .venv/bin/alembic downgrade -1

migrate-create:
	cd backend && .venv/bin/alembic revision --message="$(MSG)"

migrate-status:
	cd backend && .venv/bin/alembic current && .venv/bin/alembic history --verbose

.PHONY: test-backend
test-backend:
	cd backend && PYTHONPATH=. .venv/bin/pytest tests/ -v

flutter-bootstrap:
	cd flutter_app && flutter create .
	cd flutter_app && flutter pub get

admin-run:
	cd admin_panel && .venv/bin/streamlit run main.py
