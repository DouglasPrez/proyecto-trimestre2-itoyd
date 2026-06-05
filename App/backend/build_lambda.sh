#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# build_lambda.sh — Empaqueta el backend FastAPI para AWS Lambda (Python 3.12)
#
# Uso (desde la RAÍZ del repositorio):
#   bash App/backend/build_lambda.sh
#
# O desde App/backend/:
#   bash build_lambda.sh
#
# Resultado:
#   infra/modules/compute/app.zip
# ---------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DIST="$SCRIPT_DIR/dist"
OUT="$REPO_ROOT/infra/modules/compute/app.zip"

echo "==> Limpiando dist anterior..."
rm -rf "$DIST"
mkdir -p "$DIST"

# ---------------------------------------------------------------------------
# Instalar dependencias para Lambda Linux x86_64 / Python 3.12
# Paso 1: pydantic-core (único paquete con extensión Rust — necesita wheel Linux)
# ---------------------------------------------------------------------------
echo "==> Descargando pydantic-core (wheel Linux x86_64)..."
pip3 install \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.12 \
  --only-binary=:all: \
  --no-cache-dir \
  --retries 5 \
  --timeout 120 \
  "pydantic-core==2.23.4" \
  -t "$DIST" \
  --quiet

# ---------------------------------------------------------------------------
# Paso 2: resto de dependencias — puro Python, se instalan localmente sin problema
# uvicorn se excluye: no se necesita en Lambda (mangum hace esa parte)
# boto3/botocore se excluyen: preinstalados en el runtime Lambda Python 3.12
# ---------------------------------------------------------------------------
echo "==> Instalando dependencias puras en Python..."
pip3 install \
  --no-cache-dir \
  --retries 3 \
  --timeout 60 \
  fastapi==0.115.0 \
  sqlalchemy==2.0.35 \
  pydantic==2.9.2 \
  pydantic-settings==2.6.1 \
  python-jose==3.3.0 \
  passlib==1.7.4 \
  python-multipart==0.0.12 \
  aiofiles==24.1.0 \
  python-dateutil==2.9.0 \
  mangum==0.19.0 \
  -t "$DIST" \
  --quiet

# ---------------------------------------------------------------------------
# Eliminar paquetes preinstalados en Lambda (ahorran ~70 MB)
# ---------------------------------------------------------------------------
echo "==> Removiendo paquetes del runtime Lambda..."
rm -rf \
  "$DIST"/boto3* \
  "$DIST"/botocore* \
  "$DIST"/s3transfer* \
  "$DIST"/jmespath* \
  "$DIST"/urllib3* \
  "$DIST"/six* \
  2>/dev/null || true

# ---------------------------------------------------------------------------
# Copiar código de la aplicación y entry point
# ---------------------------------------------------------------------------
echo "==> Copiando app y entry point..."
cp -r "$SCRIPT_DIR/app/"       "$DIST/app/"
cp    "$SCRIPT_DIR/lambda_entry.py" "$DIST/index.py"

# ---------------------------------------------------------------------------
# Crear el zip
# ---------------------------------------------------------------------------
echo "==> Creando zip..."
rm -f "$OUT"
cd "$DIST"
zip -r9 "$OUT" . \
  --exclude "*.pyc" \
  --exclude "*/__pycache__/*" \
  --exclude "*.dist-info/*" \
  --exclude "*.egg-info/*" \
  --exclude "*.pyi" \
  > /dev/null

SIZE=$(du -sh "$OUT" | cut -f1)
echo ""
echo "✓ Lambda package listo: $OUT  ($SIZE)"
echo ""
echo "Siguiente paso — desde la RAÍZ del repositorio:"
echo "  cd infra && terraform apply -var-file=envs/dev/dev.tfvars"
