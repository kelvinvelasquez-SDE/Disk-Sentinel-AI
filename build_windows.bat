@echo off
echo ===================================================
echo     Disk Sentinel AI - Windows Builder
echo ===================================================

REM Check for Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found! Please install Python 3 and add it to PATH.
    pause
    exit /b 1
)

REM Create Venv if not exists
if not exist "venv" (
    echo [INFO] Creating virtual environment...
    python -m venv venv
)

REM Activate Venv
call venv\Scripts\activate

REM Install Requirements
echo [INFO] Installing dependencies...
pip install pandas numpy scikit-learn matplotlib psutil flask flask-httpauth schedule pyinstaller

REM Build
echo [INFO] Building Executable...
REM Windows uses ; separators for --add-data
pyinstaller --noconfirm --onefile --windowed --name DiskSentinel ^
    --add-data "src/templates;src/templates" ^
    --hidden-import "sklearn.utils._cython_blas" ^
    --hidden-import "sklearn.neighbors.typedefs" ^
    --hidden-import "sklearn.neighbors.quad_tree" ^
    --hidden-import "sklearn.tree" ^
    --hidden-import "sklearn.tree._utils" ^
    run.py

echo.
echo ===================================================
echo [SUCCESS] Build Complete!
echo binary is located in: dist\DiskSentinel.exe
echo ===================================================
pause
