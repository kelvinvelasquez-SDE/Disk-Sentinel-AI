from flask import Flask, render_template, jsonify, request
from flask_httpauth import HTTPBasicAuth
from werkzeug.security import generate_password_hash, check_password_hash
import os
import json
from .monitor import DiskMonitorIA

monitor = DiskMonitorIA()
auth = HTTPBasicAuth()

def get_users():
    try:
        with open('config.json', 'r') as f:
            config = json.load(f)
            return config.get('users', {
                "admin": generate_password_hash("admin")
            })
    except:
        return {"admin": generate_password_hash("admin")}

@auth.verify_password
def verify_password(username, password):
    users = get_users()
    if username in users and check_password_hash(users.get(username), password):
        return username
    return None

def create_app(template_folder=None):
    if template_folder is None:
        template_folder = os.path.abspath('src/templates')
        
    app = Flask(__name__, template_folder=template_folder)

    @app.route('/')
    @auth.login_required
    def index():
        return render_template('dashboard.html', user=auth.current_user())

    @app.route('/api/current')
    @auth.login_required
    def api_current():
        # Now returns a list of disks
        disks = monitor.get_disk_usage()
        return jsonify({"disks": disks})

    @app.route('/api/prediction')
    @auth.login_required
    def api_prediction():
        mountpoint = request.args.get('mountpoint')
        if not mountpoint:
            # If no mountpoint specified, try to predict for the first disk or return error
            disks = monitor.get_disk_usage()
            if disks:
                mountpoint = disks[0]['mountpoint']
            else:
                 return jsonify({'message': 'No se encontraron discos'})

        date, model, msg = monitor.predict_exhaustion(mountpoint)
        return jsonify({
            'mountpoint': mountpoint,
            'exhaustion_date': date.isoformat() if date else None,
            'message': msg
        })

    @app.route('/api/history')
    @auth.login_required
    def api_history():
        df = monitor.get_history_df()
        mountpoint = request.args.get('mountpoint')
        
        if mountpoint:
            df = df[df['mountpoint'] == mountpoint]
        
        # Optimize JSON output
        result = df.tail(500).to_dict(orient='records')
        return jsonify(result)

    @app.route('/api/settings', methods=['GET', 'POST'])
    @auth.login_required
    def api_settings():
        config_path = 'config.json'
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
        except:
            return jsonify({'error': 'Config not found'}), 500

        if request.method == 'POST':
            data = request.json
            
            # Update specific fields if present
            if 'critical_threshold' in data:
                try:
                    config['critical_threshold'] = int(data['critical_threshold'])
                except ValueError:
                    pass
            
            if 'alert_email' in data:
                if 'alerts' not in config: config['alerts'] = {}
                config['alerts']['email'] = str(data['alert_email'])

            # Save
            with open(config_path, 'w') as f:
                json.dump(config, f, indent=4)
            
            return jsonify({'status': 'saved', 'config': config})
        
        # GET
        return jsonify({
            'critical_threshold': config.get('critical_threshold', 85),
            'alert_email': config.get('alerts', {}).get('email', '')
        })
        
    return app
