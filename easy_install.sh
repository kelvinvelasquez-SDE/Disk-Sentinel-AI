#!/bin/bash

echo "📦 Instalando Disk Sentinel AI (Modo Simple)..."

# 1. Create Folder
INSTALL_DIR="$HOME/DiskSentinel_App"
mkdir -p "$INSTALL_DIR"

# 2. Move Binary (assuming we run this where the binary is)
cp dist/DiskSentinel "$INSTALL_DIR/"
cp config.json "$INSTALL_DIR/"

# 3. Create Desktop Launcher (optional but nice)
cat > "$HOME/Desktop/DiskSentinel.desktop" <<EOL
[Desktop Entry]
Name=Disk Sentinel AI
Comment=Monitor de Disco Inteligente
Exec=$INSTALL_DIR/DiskSentinel
Icon=utilities-system-monitor
Terminal=true
Type=Application
EOL

chmod +x "$HOME/Desktop/DiskSentinel.desktop"
chmod +x "$INSTALL_DIR/DiskSentinel"

echo "✅ Instalación completada!"
echo "➡️  Ahora tienes un acceso directo 'Disk Sentinel AI' en tu escritorio."
echo "➡️  O puedes ejecutarlo desde: $INSTALL_DIR/DiskSentinel"
