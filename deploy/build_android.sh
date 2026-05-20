#!/usr/bin/env bash
# =============================================================================
# build_android.sh — Construye la APK de Android de Gym Tracker RN
# =============================================================================
# Uso:
#   ./deploy/build_android.sh [URL_API]
#
# Ejemplos:
#   ./deploy/build_android.sh
#       → Usa la URL de producción por defecto (https://rngym.duckdns.org:8443/api/v1)
#
#   ./deploy/build_android.sh https://rngym.duckdns.org:8443/api/v1
#       → Especifica la URL manualmente
#
#   ./deploy/build_android.sh http://192.168.1.100:8000/api/v1
#       → Para pruebas en red local
# =============================================================================

set -e

# ── Colores ──────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sin color

# ── Configuración ─────────────────────────────────────────────────────────────
FLUTTER_CMD="${FLUTTER_CMD:-/home/ramon/flutter/bin/flutter}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$REPO_DIR/flutter_app"
OUTPUT_DIR="$REPO_DIR/deploy/output"
DEFAULT_API_URL="https://rngym.duckdns.org:8443/api/v1"
API_URL="${1:-$DEFAULT_API_URL}"

# ── Verificaciones previas ────────────────────────────────────────────────────
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
echo -e "${CYAN}   Gym Tracker RN — Build Android APK         ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════${NC}"
echo ""

if [ ! -f "$FLUTTER_CMD" ]; then
    echo -e "${RED}✗ Flutter no encontrado en: $FLUTTER_CMD${NC}"
    echo -e "${YELLOW}  Ajusta la variable FLUTTER_CMD, por ejemplo:"
    echo -e "  FLUTTER_CMD=/usr/bin/flutter ./deploy/build_android.sh${NC}"
    exit 1
fi

echo -e "${CYAN}▶ Flutter:${NC} $FLUTTER_CMD"
echo -e "${CYAN}▶ Proyecto:${NC} $FLUTTER_DIR"
echo -e "${CYAN}▶ API URL:${NC} $API_URL"
echo ""

# ── Instalar dependencias ─────────────────────────────────────────────────────
echo -e "${CYAN}[1/3] Instalando dependencias...${NC}"
cd "$FLUTTER_DIR"
"$FLUTTER_CMD" pub get

# ── Compilar APK ─────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}[2/3] Compilando APK release (esto puede tardar unos minutos)...${NC}"
"$FLUTTER_CMD" build apk \
    --release \
    --dart-define=API_BASE_URL="$API_URL"

# ── Copiar APK al directorio de salida ───────────────────────────────────────
echo ""
echo -e "${CYAN}[3/3] Copiando APK al directorio de salida...${NC}"
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
APK_SOURCE="$FLUTTER_DIR/build/app/outputs/flutter-apk/app-release.apk"
APK_DEST="$OUTPUT_DIR/GymTrackerRN_${TIMESTAMP}.apk"

cp "$APK_SOURCE" "$APK_DEST"

# ── Resumen ───────────────────────────────────────────────────────────────────
APK_SIZE=$(du -sh "$APK_DEST" | cut -f1)
echo ""
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}   ✓ APK compilada correctamente              ${NC}"
echo -e "${GREEN}══════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}▶ Archivo:${NC} $APK_DEST"
echo -e "${GREEN}▶ Tamaño: ${NC} $APK_SIZE"
echo -e "${GREEN}▶ API URL:${NC} $API_URL"
echo ""
echo -e "${YELLOW}Para instalar en tu móvil Android:${NC}"
echo -e "  1. Transfiere el archivo APK al teléfono (USB, email, etc.)"
echo -e "  2. Habilita 'Instalar apps de fuentes desconocidas' en Ajustes"
echo -e "  3. Abre el archivo APK desde el gestor de archivos del móvil"
echo ""
