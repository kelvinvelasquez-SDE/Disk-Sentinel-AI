#!/bin/bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Iniciando instalación de Disk Sentinel AI...${NC}"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 no encontrado. Por favor instálalo primero."
    exit 1
fi

# Create venv
if [ ! -d "venv" ]; then
    echo -e "${BLUE}📦 Creando entorno virtual...${NC}"
    python3 -m venv venv
fi

# Install dependencies
echo -e "${BLUE}⬇️ Instalando dependencias...${NC}"
./venv/bin/pip install pandas numpy scikit-learn matplotlib psutil flask flask-httpauth schedule werkzeug

# Create Default Users (generating password hash)
echo -e "${BLUE}🔐 Configurando seguridad...${NC}"
if ! grep -q "pbkdf2" config.json; then
    # Generate a hash for 'admin' (default password)
    HASH=$(./venv/bin/python3 -c "from werkzeug.security import generate_password_hash; print(generate_password_hash('admin'))")
    # Replace in config (simple sed, assuming structure)
    sed -i "s/\"pbkdf2:sha256:600000\$Z4x...\"/\"$HASH\"/" config.json
    echo "⚠️ Usuario por defecto: admin / admin (¡Deverías cambiar esto!)"
fi

# Make run executable
chmod +x run.py

# Create Systemd Service
echo -e "${BLUE}⚙️ Generando servicio systemd...${NC}"
SERVICE_path=$(pwd)
cat > disk-monitor.service <<EOL
[Unit]
Description=Disk Sentinel AI Monitor
After=network.target

[Service]
User=$USER
WorkingDirectory=$SERVICE_path
ExecStart=$SERVICE_path/venv/bin/python3 $SERVICE_path/run.py
Restart=always

[Install]
WantedBy=multi-user.target
EOL

echo -e "${GREEN}✅ Instalación completada!${NC}"
echo -e "Para iniciar manualmente: ${BLUE}./venv/bin/python3 run.py${NC}"
echo -e "Para instalar como servicio: ${BLUE}sudo mv disk-monitor.service /etc/systemd/system/ && sudo systemctl enable --now disk-monitor${NC}"
