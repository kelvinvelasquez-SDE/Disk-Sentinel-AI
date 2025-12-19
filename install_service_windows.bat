@echo off
setlocal
echo ===================================================
echo   Disk Sentinel AI - Instalacion PROFESIONAL (Windows)
echo ===================================================

REM Check Admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Por favor ejecuta este script como ADMINISTRADOR.
    echo (Clic derecho -> Ejecutar como administrador)
    pause
    exit /b
)

set "INSTALL_DIR=C:\DiskSentinel"
set "BIN_SOURCE=dist\DiskSentinel.exe"
set "CONF_SOURCE=config.json"

REM 1. Verify Build
if not exist "%BIN_SOURCE%" (
    echo [ERROR] No se encuentra %BIN_SOURCE%.
    echo Ejecuta primero build_windows.bat para compilar.
    pause
    exit /b
)

REM 2. Create Directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
echo [INFO] Directorio de instalacion: %INSTALL_DIR%

REM 3. Stop Existing
taskkill /F /IM DiskSentinel.exe >nul 2>&1
schtasks /Delete /TN "DiskSentinelService" /F >nul 2>&1

REM 4. Copy Files
echo [INFO] Copiando archivos...
copy /Y "%BIN_SOURCE%" "%INSTALL_DIR%\DiskSentinel.exe"
if exist "%CONF_SOURCE%" copy /Y "%CONF_SOURCE%" "%INSTALL_DIR%\config.json"

REM 5. Create Task Scheduler Service
echo [INFO] Creando Tarea Programada (Servicio)...
REM This runs on system start, as SYSTEM user (hidden), highest privileges
schtasks /Create /TN "DiskSentinelService" /TR "'%INSTALL_DIR%\DiskSentinel.exe' --service" /SC ONSTART /RU SYSTEM /RL HIGHEST /NP /F

REM 6. Start Immediately
schtasks /Run /TN "DiskSentinelService"

REM 7. Create Desktop Shortcut for UI
echo [INFO] Creando acceso directo al Dashboard...
set "SHORTCUT_SCRIPT=%temp%\CreateShortcut.vbs"
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%SHORTCUT_SCRIPT%"
echo sLinkFile = "%USERPROFILE%\Desktop\Disk Sentinel Dashboard.lnk" >> "%SHORTCUT_SCRIPT%"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%SHORTCUT_SCRIPT%"
echo oLink.TargetPath = "http://localhost:9097" >> "%SHORTCUT_SCRIPT%"
echo oLink.IconLocation = "%INSTALL_DIR%\DiskSentinel.exe,0" >> "%SHORTCUT_SCRIPT%"
echo oLink.Save >> "%SHORTCUT_SCRIPT%"
cscript /nologo "%SHORTCUT_SCRIPT%"
del "%SHORTCUT_SCRIPT%"

echo.
echo ===================================================
echo [EXITO] Instalacion Completada
echo - El servicio iniciara automaticamente con Windows.
echo - Usa el icono "Disk Sentinel Dashboard" para ver el estado.
echo ===================================================
pause
