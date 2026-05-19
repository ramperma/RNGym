#!/bin/bash

# Script de actualización para producción - RNGym
# Ruta del proyecto: /var/www/html/rngym

set -e # Detener script si hay errores

echo "=== Iniciando proceso de actualización ==="
cd /var/www/html/rngym

echo "1. Obteniendo últimos cambios del repositorio..."
git pull origin main

echo "2. Actualizando dependencias del Backend..."
cd backend
# Asegurar que el entorno virtual existe
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install -r requirements.txt

echo "3. Ejecutando migraciones de la Base de Datos..."
# La base de datos debe estar configurada en backend/.env (localhost, rngym)
alembic upgrade head
deactivate
cd ..

echo "4. Actualizando dependencias del Panel de Administración..."
cd admin_panel
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install -r requirements.txt
deactivate
cd ..

echo "5. Compilando Flutter Web..."
cd flutter_app
# Generar archivos de plataforma y dependencias
flutter pub get
# Compilar web indicando la URL base del API en producción
flutter build web --dart-define=API_BASE_URL=https://rngym.duckdns.org:8443/api/v1
cd ..

echo "6. Reiniciando servicios de sistema..."
sudo systemctl restart gym-backend
sudo systemctl restart gym-admin

echo "=== Actualización completada con éxito ==="
