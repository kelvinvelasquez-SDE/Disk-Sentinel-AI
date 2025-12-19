#!/bin/bash

# Check root
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Por favor, ejecuta como root (sudo ./install_service_linux.sh)"
  exit
fi

echo "==================================================="
echo "   Disk Sentinel AI - Instalación PROFESIONAL"
echo "==================================================="

APP_DIR="/opt/DiskSentinel"
BIN_SOURCE="./dist/DiskSentinel"
CONF_SOURCE="./config.json"
SERVICE_FILE="/etc/systemd/system/disksentinel.service"

# 1. Verify Build
if [ ! -f "$BIN_SOURCE" ]; then
    echo "⚠️  No se encuentra el binario '$BIN_SOURCE'."
    echo "    Ejecuta primero ./build.sh"
    exit 1
fi

# 2. Stop existing service if running
systemctl stop disksentinel 2>/dev/null

# 3. Create Install Directory
echo "📂 Creando directorio en $APP_DIR..."
mkdir -p "$APP_DIR"

# 4. Copy Files
echo "📦 Copiando archivos..."
cp "$BIN_SOURCE" "$APP_DIR/DiskSentinel"
cp "$CONF_SOURCE" "$APP_DIR/config.json"
chmod +x "$APP_DIR/DiskSentinel"

# 5. Create Service User (Security)
if ! id "disksentinel" &>/dev/null; then
    echo "👤 Creando usuario de sistema 'disksentinel'..."
    useradd -r -s /bin/false disksentinel
fi
chown -R disksentinel:disksentinel "$APP_DIR"

# 6. Create Systemd Service
echo "⚙️  Configurando Systemd..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Disk Sentinel AI Monitoring Service
After=network.target

[Service]
Type=simple
User=disksentinel
Group=disksentinel
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/DiskSentinel --service
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 7. Enable and Start
echo "🚀 Iniciando servicio..."
systemctl daemon-reload
systemctl enable disksentinel
systemctl start disksentinel

# 8. Create Desktop Shortcut for UI ONLY
echo "🖥️  Creando acceso directo..."
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd $REAL_USER | cut -d: -f6)
DESKTOP_FILE="$USER_HOME/Desktop/DiskSentinel_Dashboard.desktop"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Disk Sentinel Dashboard
Comment=Abrir Panel de Control
Exec=xdg-open http://localhost:9097
Icon=utilities-system-monitor
Terminal=false
StartupNotify=false
Categories=System;Monitor;
EOF

chmod +x "$DESKTOP_FILE"
chown $REAL_USER:$REAL_USER "$DESKTOP_FILE"

echo ""
echo "✅ INSTALACIÓN COMPLETADA EXITOSAMENTE"
echo "   - Servicio: ACTIVO (fondo)"
echo "   - Dashboard: Icono en el escritorio"
echo "   - Estado: systemctl status disksentinel"
echo ""
echo "Ahora puedes reiniciar tu equipo y el monitoreo seguirá funcionando."
