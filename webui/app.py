#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
运维工具 Web UI
基于 Flask 的可视化管理界面
"""

import os
import subprocess
import json
from flask import Flask, render_template, request, jsonify, redirect, url_for
from flask_socketio import SocketIO, emit
import threading
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app)

SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/system-info')
def system_info():
    try:
        result = subprocess.run(['bash', '-c', 'hostname && uname -a && uptime'], 
                              capture_output=True, text=True)
        return jsonify({
            'success': True,
            'data': result.stdout
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/services')
def services():
    services = [
        {'name': 'nginx', 'status': get_service_status('nginx')},
        {'name': 'mysql', 'status': get_service_status('mysql')},
        {'name': 'redis', 'status': get_service_status('redis')},
        {'name': 'docker', 'status': get_service_status('docker')},
        {'name': 'sshd', 'status': get_service_status('sshd')},
    ]
    return jsonify(services)

def get_service_status(service):
    try:
        result = subprocess.run(['systemctl', 'is-active', service], 
                              capture_output=True, text=True)
        return result.stdout.strip()
    except:
        return 'unknown'

@app.route('/api/healthcheck', methods=['POST'])
def healthcheck():
    try:
        result = subprocess.run([f'{SCRIPT_DIR}/healthcheck/healthcheck.sh'], 
                              capture_output=True, text=True, timeout=60)
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr
        })
    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'error': '超时'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/security', methods=['POST'])
def security():
    try:
        result = subprocess.run([f'{SCRIPT_DIR}/security-baseline/security-baseline.sh', 'all'], 
                              capture_output=True, text=True, timeout=120)
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr
        })
    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'error': '超时'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/daily', methods=['POST'])
def daily_check():
    try:
        result = subprocess.run([f'{SCRIPT_DIR}/daily-check.sh'], 
                              capture_output=True, text=True, timeout=120)
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr
        })
    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'error': '超时'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/cpu')
def cpu_info():
    try:
        result = subprocess.run(['bash', '-c', 'top -bn1 | grep "Cpu(s)" && mpstat 1 1'], 
                              capture_output=True, text=True)
        return jsonify({'success': True, 'data': result.stdout})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/memory')
def memory_info():
    try:
        result = subprocess.run(['free', '-h'], capture_output=True, text=True)
        return jsonify({'success': True, 'data': result.stdout})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/disk')
def disk_info():
    try:
        result = subprocess.run(['df', '-h'], capture_output=True, text=True)
        return jsonify({'success': True, 'data': result.stdout})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/network')
def network_info():
    try:
        result = subprocess.run(['bash', '-c', 'ip addr show | grep inet && ss -tuln | head -20'], 
                              capture_output=True, text=True)
        return jsonify({'success': True, 'data': result.stdout})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/processes')
def processes():
    try:
        result = subprocess.run(['bash', '-c', 'ps aux --sort=-%mem | head -20'], 
                              capture_output=True, text=True)
        return jsonify({'success': True, 'data': result.stdout})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/software/list')
def list_software():
    software_list = []
    for item in os.listdir(SCRIPT_DIR):
        item_path = os.path.join(SCRIPT_DIR, item)
        if os.path.isdir(item_path) and item not in ['lib', 'config', 'uninstall', 'examples', 
                                                      'security-baseline', 'kubernetes', 
                                                      'docker-compose-templates', 'docker-manager']:
            script_file = os.path.join(item_path, f'{item}.sh')
            if os.path.isfile(script_file):
                software_list.append(item)
    return jsonify(sorted(software_list))

@app.route('/api/software/install', methods=['POST'])
def install_software():
    data = request.json
    software = data.get('software')
    version = data.get('version', '')
    
    try:
        cmd = [f'{SCRIPT_DIR}/main.sh', 'install', software]
        if version:
            cmd.append(version)
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        return jsonify({
            'success': result.returncode == 0,
            'output': result.stdout,
            'error': result.stderr
        })
    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'error': '安装超时'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/software/status')
def software_status():
    software_list = [
        {'name': 'nginx', 'cmd': 'nginx -v'},
        {'name': 'mysql', 'cmd': 'mysql -V'},
        {'name': 'redis', 'cmd': 'redis-server --version'},
        {'name': 'php', 'cmd': 'php -v'},
        {'name': 'python', 'cmd': 'python3 -V'},
        {'name': 'node', 'cmd': 'node -v'},
        {'name': 'docker', 'cmd': 'docker --version'},
        {'name': 'java', 'cmd': 'java -version'},
        {'name': 'go', 'cmd': 'go version'},
    ]
    
    status_list = []
    for item in software_list:
        try:
            result = subprocess.run(item['cmd'].split(), capture_output=True, text=True)
            if result.returncode == 0:
                version = result.stderr.strip() if item['name'] == 'java' else result.stdout.strip()
                status_list.append({'name': item['name'], 'status': 'installed', 'version': version})
            else:
                status_list.append({'name': item['name'], 'status': 'not_installed', 'version': ''})
        except:
            status_list.append({'name': item['name'], 'status': 'not_installed', 'version': ''})
    
    return jsonify(status_list)

@app.route('/api/backup', methods=['POST'])
def backup():
    data = request.json
    target = data.get('target', 'all')
    
    try:
        result = subprocess.run([f'{SCRIPT_DIR}/backup/backup.sh', 'backup', target], 
                              capture_output=True, text=True, timeout=120)
        return jsonify({
            'success': result.returncode == 0,
            'output': result.stdout,
            'error': result.stderr
        })
    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'error': '备份超时'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/update/check')
def check_update():
    try:
        result = subprocess.run([f'{SCRIPT_DIR}/update.sh', 'check'], 
                              capture_output=True, text=True)
        return jsonify({'success': True, 'output': result.stdout})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/service/control', methods=['POST'])
def service_control():
    data = request.json
    action = data.get('action')
    service = data.get('service')
    
    try:
        result = subprocess.run(['systemctl', action, service], 
                              capture_output=True, text=True)
        return jsonify({
            'success': result.returncode == 0,
            'output': result.stdout,
            'error': result.stderr
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/logs/<service>')
def get_logs(service):
    log_paths = {
        'nginx': '/var/log/nginx/access.log',
        'mysql': '/var/log/mariadb/mariadb.log',
        'system': '/var/log/messages',
    }
    
    log_path = log_paths.get(service, '/var/log/messages')
    
    try:
        result = subprocess.run(['tail', '-50', log_path], 
                              capture_output=True, text=True)
        return jsonify({'success': True, 'data': result.stdout})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
