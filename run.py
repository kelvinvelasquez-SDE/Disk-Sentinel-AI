#!/usr/bin/env python3
import threading
import time
import schedule
import webbrowser
import sys
import os
import argparse
from src.web import create_app
from src.monitor import DiskMonitorIA

# Fix for PyInstaller to find templates/static
if getattr(sys, 'frozen', False):
    template_folder = os.path.join(sys._MEIPASS, 'src', 'templates')
    static_folder = os.path.join(sys._MEIPASS, 'src', 'static')
    app = create_app(template_folder=template_folder) # We need to update create_app to accept this
else:
    app = create_app()

def run_scheduler():
    monitor = DiskMonitorIA()
    # Run once immediately
    monitor.check_and_alert()
    
    # Schedule every hour
    schedule.every(1).hours.do(monitor.check_and_alert)
    
    print("⏰ Scheduler iniciado. Monitoreo activo.")
    while True:
        schedule.run_pending()
        time.sleep(60)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Disk Sentinel AI')
    parser.add_argument('--service', action='store_true', help='Run in service mode (no browser)')
    args = parser.parse_args()

    port = 9097
    url = f"http://localhost:{port}"

    # Start scheduler in background thread
    scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
    scheduler_thread.start()
    
    # Open Browser if not in service mode
    if not args.service:
        print(f"🚀 Iniciando Disk Sentinel AI...")
        print(f"🌍 Abriendo interfaz en {url}")
        threading.Timer(1.5, lambda: webbrowser.open(url)).start()
    else:
        print("🚀 Disk Sentinel running in SERVICE MODE (Background)")

    app.run(host='0.0.0.0', port=port, debug=False, use_reloader=False)
