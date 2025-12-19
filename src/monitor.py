#!/usr/bin/env python3
import json
import os
import psutil
import smtplib
import socket
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
import matplotlib
# Use Agg backend for non-interactive plotting
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
from typing import Dict, Any, Tuple, Optional, List

class DiskMonitorIA:
    def __init__(self, config_path: str = 'config.json'):
        self.config_path = config_path
        self.config = self.load_config(config_path)
        self.history_file = 'disk_history.csv'
        self.init_history()
        
    def load_config(self, path: str) -> Dict[str, Any]:
        """Loads configuration from JSON file."""
        try:
            with open(path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            return {}
    
    def init_history(self):
        """Initializes disk usage history file."""
        # Check if schema needs update (v1 had no mountpoint)
        reset = False
        if os.path.exists(self.history_file):
            try:
                df = pd.read_csv(self.history_file)
                if 'mountpoint' not in df.columns:
                    print("⚠️ Detectado esquema antiguo. Creando nuevo archivo de historial.")
                    reset = True
            except:
                reset = True
                
        if reset or not os.path.exists(self.history_file):
            df = pd.DataFrame(columns=['timestamp', 'device', 'mountpoint', 'used_percent', 'used_gb', 'free_gb'])
            df.to_csv(self.history_file, index=False)
    
    def get_history_df(self) -> pd.DataFrame:
        """Reads history into a pandas DataFrame."""
        try:
            return pd.read_csv(self.history_file, parse_dates=['timestamp'])
        except Exception:
            return pd.DataFrame(columns=['timestamp', 'device', 'mountpoint', 'used_percent', 'used_gb', 'free_gb'])

    def get_disk_usage(self) -> List[Dict[str, Any]]:
        """Gets current disk usage for all physical partitions."""
        disks = []
        partitions = psutil.disk_partitions(all=False) # all=False tries to ignore pseudo-fs
        
        for p in partitions:
            # Filter snaps and loops aggressively
            if 'loop' in p.device or 'snap' in p.mountpoint:
                continue
                
            try:
                usage = psutil.disk_usage(p.mountpoint)
                disks.append({
                    'timestamp': datetime.now(),
                    'device': p.device,
                    'mountpoint': p.mountpoint,
                    'fstype': p.fstype,
                    'used_percent': usage.percent,
                    'used_gb': round(usage.used / (1024**3), 2),
                    'free_gb': round(usage.free / (1024**3), 2),
                    'total_gb': round(usage.total / (1024**3), 2)
                })
            except PermissionError:
                continue
                
        return disks
    
    def save_reading(self):
        """Saves readings for all disks."""
        current_disks = self.get_disk_usage()
        df = self.get_history_df()
        
        new_rows = []
        for d in current_disks:
            # Drop non-csv fields if any
            row = {k: v for k, v in d.items() if k in df.columns}
            new_rows.append(row)
            
        if new_rows:
            new_df = pd.DataFrame(new_rows)
            df = pd.concat([df, new_df], ignore_index=True)
            
            # Retention policy: keep last 30 days approx per disk
            # Simple approach: keep last 50000 rows total
            if len(df) > 50000:
                df = df.tail(50000)
                
            df.to_csv(self.history_file, index=False)
            
    def predict_exhaustion(self, mountpoint: str) -> Tuple[Optional[datetime], Optional[LinearRegression], str]:
        """Predicts when a SPECIFIC disk will be full."""
        df = self.get_history_df()
        # Filter by mountpoint
        df = df[df['mountpoint'] == mountpoint].copy()
        
        if len(df) < 10:
            return None, None, "Recopilando datos..."
        
        df = df.sort_values('timestamp')
        df['days_since'] = (df['timestamp'] - df['timestamp'].min()).dt.total_seconds() / 86400
        
        X = df['days_since'].values.reshape(-1, 1)
        y = df['used_percent'].values
        
        model = LinearRegression()
        model.fit(X, y)
        
        if model.coef_[0] <= 0:
            return None, None, "Estable"
            
        current_day = X[-1][0]
        critical = self.config.get('critical_threshold', 90)
        
        # Avoid division by zero
        if model.coef_[0] == 0:
             return None, None, "Estable"

        days_to_crit = (critical - model.predict([[current_day]])[0]) / model.coef_[0]
        
        if days_to_crit <= 0:
            return datetime.now(), model, "Crítico"
        if days_to_crit > 1825: # > 5 years
            return None, None, "Largo plazo"
            
        exhaustion_date = datetime.now() + timedelta(days=days_to_crit)
        return exhaustion_date, model, f"~{int(days_to_crit)} días"

    def check_and_alert(self):
        """Checks all disks and alerts if any is critical."""
        # Reload config to get latest thresholds/emails
        self.config = self.load_config(self.config_path)
        self.save_reading()
        # simplified alerting for now - just log to console as the main use is dashboard
        print(f"[{datetime.now()}] Escaneo de discos completado.")
