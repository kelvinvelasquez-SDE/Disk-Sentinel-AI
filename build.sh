#!/bin/bash
set -e

# Activate venv
source venv/bin/activate

# Install PyInstaller
echo "📦 Instalando PyInstaller..."
pip install pyinstaller

# Clean previous builds
rm -rf build dist

# Build
echo "🔨 Compilando binario (Single File)..."
# --add-data "src/templates:src/templates" copies the templates folder into the bundle
# --add-data "src/static:src/static" (if it existed)
# --hidden-import to ensure all deps are found if needed (sklearn usually needs help)

pyinstaller --noconfirm --onefile --windowed --name DiskSentinel \
    --add-data "src/templates:src/templates" \
    --hidden-import "sklearn.utils._cython_blas" \
    --hidden-import "sklearn.neighbors.typedefs" \
    --hidden-import "sklearn.neighbors.quad_tree" \
    --hidden-import "sklearn.tree" \
    --hidden-import "sklearn.tree._utils" \
    run.py

echo "✅ Construcción completada."
echo "📂 Binario disponible en: dist/DiskSentinel"
echo "ℹ️  Nota: Asegúrate de copiar 'config.json' en la misma carpeta que el binario."
