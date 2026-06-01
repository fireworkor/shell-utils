#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
运维工具 Web UI
基于 Flask 的可视化管理界面
"""

import os
import subprocess
import json
import re
from flask import Flask, render_template, request, jsonify, redirect, url_for
from flask_socketio import SocketIO, emit
import threading
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app, cors_allowed_origins="*")

SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 存储安装日志
install_logs = {}

# 安装任务队列
install_queue = []
install_queue_running = False
install_queue_lock = threading.Lock()

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
    # 动态获取系统中所有启用的服务
    try:
        result = subprocess.run(
            ['systemctl', 'list-unit-files', '--type=service', '--state=enabled', '--no-pager'],
            capture_output=True, text=True
        )
        service_list = []
        for line in result.stdout.strip().split('\n')[1:]:  # 跳过表头
            parts = line.split()
            if len(parts) >= 1:
                name = parts[0].replace('.service', '')
                service_list.append({'name': name, 'status': get_service_status(name)})
        return jsonify(service_list)
    except Exception as e:
        # 回退到基础服务列表
        fallback = [
            {'name': 'nginx', 'status': get_service_status('nginx')},
            {'name': 'mysqld', 'status': get_service_status('mysqld')},
            {'name': 'mariadb', 'status': get_service_status('mariadb')},
            {'name': 'redis', 'status': get_service_status('redis')},
            {'name': 'docker', 'status': get_service_status('docker')},
            {'name': 'sshd', 'status': get_service_status('sshd')},
            {'name': 'firewalld', 'status': get_service_status('firewalld')},
            {'name': 'crond', 'status': get_service_status('crond')},
        ]
        return jsonify(fallback)

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
        # 使用不带 -h 的 free 命令，以便准确计算百分比
        result = subprocess.run(['free'], capture_output=True, text=True)
        lines = result.stdout.split('\n')
        mem_line = None
        for line in lines:
            if line.startswith('Mem:'):
                mem_line = line
                break
        
        if mem_line:
            parts = list(filter(None, mem_line.split()))
            total = int(parts[1])
            used = int(parts[2])
            percent = (used / total) * 100
            
            # 同时获取带单位的输出用于显示
            result_h = subprocess.run(['free', '-h'], capture_output=True, text=True)
            return jsonify({
                'success': True, 
                'data': result_h.stdout,
                'percent': round(percent, 1),
                'total': total,
                'used': used
            })
        
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
                                                      'docker-compose-templates', 'docker-manager',
                                                      'webui', 'healthcheck', 'backup']:
            script_file = os.path.join(item_path, f'{item}.sh')
            if os.path.isfile(script_file):
                software_list.append(item)
    return jsonify(sorted(software_list))

# 软件检测映射
software_check_map = {
    'nginx': {'cmd': 'nginx -v', 'stderr': True},
    'mysql': {'cmd': 'mysql -V', 'stderr': False},
    'mariadb': {'cmd': 'mysql -V', 'stderr': False},
    'redis': {'cmd': 'redis-server --version', 'stderr': False},
    'php': {'cmd': 'php -v', 'stderr': False},
    'python': {'cmd': 'python3 -V', 'stderr': True},
    'node': {'cmd': 'node -v', 'stderr': False},
    'docker': {'cmd': 'docker --version', 'stderr': False},
    'java': {'cmd': 'java -version', 'stderr': True},
    'go': {'cmd': 'go version', 'stderr': False},
    'git': {'cmd': 'git --version', 'stderr': False},
    'vim': {'cmd': 'vim --version', 'stderr': False},
    'curl': {'cmd': 'curl --version', 'stderr': False},
    'wget': {'cmd': 'wget --version', 'stderr': False},
    'tmux': {'cmd': 'tmux -V', 'stderr': False},
    'htop': {'cmd': 'htop --version', 'stderr': False},
    'iftop': {'cmd': 'iftop -h', 'stderr': True},
    'nethogs': {'cmd': 'nethogs -V', 'stderr': False},
    'telnet': {'cmd': 'telnet --help', 'stderr': True},
    'net-tools': {'cmd': 'ifconfig --version', 'stderr': True},
    'iptraf': {'cmd': 'iptraf-ng -V', 'stderr': False},
    'lsof': {'cmd': 'lsof -v', 'stderr': True},
    'tree': {'cmd': 'tree --version', 'stderr': False},
    'jq': {'cmd': 'jq --version', 'stderr': False},
    'vsftpd': {'cmd': 'vsftpd -v', 'stderr': True},
    'samba': {'cmd': 'smbd --version', 'stderr': False},
    'nfs': {'cmd': 'rpcinfo -p', 'stderr': False},
    'kubernetes': {'cmd': 'kubectl version --client', 'stderr': False},
    'jenkins': {'cmd': 'java -jar /usr/share/jenkins/jenkins.war --version 2>/dev/null || echo "Not found"', 'stderr': False},
    'gitlab': {'cmd': 'gitlab-ctl version 2>/dev/null || echo "Not found"', 'stderr': False},
    'harbor': {'cmd': 'docker ps -q -f name=harbor 2>/dev/null || echo "Not found"', 'stderr': False},
}

@app.route('/api/software/status')
def software_status():
    # 先获取所有可用的软件
    available_software = []
    for item in os.listdir(SCRIPT_DIR):
        item_path = os.path.join(SCRIPT_DIR, item)
        if os.path.isdir(item_path) and item not in ['lib', 'config', 'uninstall', 'examples', 
                                                      'security-baseline', 'kubernetes', 
                                                      'docker-compose-templates', 'docker-manager',
                                                      'webui', 'healthcheck', 'backup']:
            script_file = os.path.join(item_path, f'{item}.sh')
            if os.path.isfile(script_file):
                available_software.append(item)
    
    status_list = []
    for software in available_software:
        # 尝试用预定义的检测命令
        check_info = software_check_map.get(software)
        if check_info:
            try:
                result = subprocess.run(check_info['cmd'], shell=True, 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    output = result.stderr.strip() if check_info['stderr'] else result.stdout.strip()
                    # 提取版本号
                    version_match = re.search(r'(\d+\.\d+(?:\.\d+)?)', output)
                    version = version_match.group(1) if version_match else output[:50]
                    status_list.append({'name': software, 'status': 'installed', 'version': version})
                else:
                    status_list.append({'name': software, 'status': 'not_installed', 'version': ''})
            except:
                status_list.append({'name': software, 'status': 'not_installed', 'version': ''})
        else:
            # 尝试通用检测 - 检查命令是否存在
            try:
                result = subprocess.run(['which', software], capture_output=True, text=True)
                if result.returncode == 0:
                    # 尝试获取版本
                    version = ''
                    for version_cmd in ['--version', '-v', '-V', 'version']:
                        try:
                            cmd = [software, version_cmd]
                            ver_result = subprocess.run(cmd, capture_output=True, text=True, timeout=3)
                            if ver_result.returncode == 0:
                                output = ver_result.stdout or ver_result.stderr
                                version_match = re.search(r'(\d+\.\d+(?:\.\d+)?)', output)
                                version = version_match.group(1) if version_match else output[:50]
                                if version:
                                    break
                        except:
                            continue
                    status_list.append({'name': software, 'status': 'installed', 'version': version})
                else:
                    status_list.append({'name': software, 'status': 'not_installed', 'version': ''})
            except:
                status_list.append({'name': software, 'status': 'not_installed', 'version': ''})
    
    return jsonify(status_list)

@app.route('/api/software/install', methods=['POST'])
def install_software():
    data = request.json
    software = data.get('software')
    version = data.get('version', '')
    task_id = f'install_{software}_{int(time.time())}'
    
    def run_install():
        try:
            cmd = [f'{SCRIPT_DIR}/main.sh', 'install', software]
            if version:
                cmd.append(version)
            
            install_logs[task_id] = []
            
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, 
                                     text=True, bufsize=1, universal_newlines=True)
            
            for line in iter(process.stdout.readline, ''):
                if line:
                    install_logs[task_id].append(line.rstrip())
                    socketio.emit('install_log', {'task_id': task_id, 'line': line.rstrip()})
            
            process.wait()
            
            success = process.returncode == 0
            socketio.emit('install_complete', {
                'task_id': task_id, 
                'success': success,
                'logs': install_logs[task_id]
            })
            
            return success
            
        except Exception as e:
            error_msg = str(e)
            install_logs[task_id].append(f'Error: {error_msg}')
            socketio.emit('install_complete', {
                'task_id': task_id, 
                'success': False, 
                'error': error_msg,
                'logs': install_logs[task_id]
            })
            return False
    
    # 在后台线程中运行安装
    thread = threading.Thread(target=run_install)
    thread.start()
    
    return jsonify({'success': True, 'task_id': task_id})

@app.route('/api/software/uninstall', methods=['POST'])
def uninstall_software():
    data = request.json
    software = data.get('software')
    task_id = f'uninstall_{software}_{int(time.time())}'
    
    if not software:
        return jsonify({'success': False, 'error': '请指定要卸载的软件'})
    
    def run_uninstall():
        try:
            install_logs[task_id] = []
            
            def emit_log(line):
                install_logs[task_id].append(line.rstrip())
                socketio.emit('install_log', {'task_id': task_id, 'line': line.rstrip()})
            
            emit_log(f'开始卸载 {software}...')
            
            # 检查卸载脚本
            uninstall_script = os.path.join(SCRIPT_DIR, 'uninstall', 'uninstall.sh')
            if not os.path.isfile(uninstall_script):
                emit_log('未找到卸载脚本，尝试通过包管理器卸载...')
                # 尝试通过包管理器卸载
                pkg_map = {
                    'nginx': 'nginx', 'mysql': 'mysql-server', 'mariadb': 'mariadb-server',
                    'redis': 'redis-server', 'php': 'php', 'python': 'python3',
                    'nodejs': 'nodejs', 'docker': 'docker-ce', 'java': 'java',
                    'mongodb': 'mongodb-org', 'postgresql': 'postgresql',
                    'vsftpd': 'vsftpd', 'samba': 'samba', 'nfs': 'nfs-kernel-server',
                }
                pkg_name = pkg_map.get(software, software)
                
                for cmd in [
                    ['yum', 'remove', '-y', pkg_name],
                    ['dnf', 'remove', '-y', pkg_name],
                    ['apt', 'remove', '-y', pkg_name],
                ]:
                    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                           text=True, bufsize=1, universal_newlines=True)
                    for line in iter(process.stdout.readline, ''):
                        if line:
                            emit_log(line.rstrip())
                    process.wait()
                    if process.returncode == 0:
                        break
            else:
                cmd = ['bash', uninstall_script, software]
                process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                         text=True, bufsize=1, universal_newlines=True)
                for line in iter(process.stdout.readline, ''):
                    if line:
                        emit_log(line.rstrip())
                process.wait()
            
            success = process.returncode == 0
            socketio.emit('install_complete', {
                'task_id': task_id,
                'success': success,
                'logs': install_logs[task_id]
            })
        except Exception as e:
            error_msg = str(e)
            install_logs[task_id].append(f'Error: {error_msg}')
            socketio.emit('install_complete', {
                'task_id': task_id,
                'success': False,
                'error': error_msg,
                'logs': install_logs[task_id]
            })
    
    thread = threading.Thread(target=run_uninstall)
    thread.start()
    
    return jsonify({'success': True, 'task_id': task_id})

@app.route('/api/software/queue')
def install_queue_status():
    """获取安装队列状态"""
    return jsonify({
        'queue': [{'software': item['software'], 'task_id': item['task_id'], 'status': item['status']} 
                  for item in install_queue],
        'running': install_queue_running
    })

def process_install_queue():
    """处理安装任务队列"""
    global install_queue_running
    with install_queue_lock:
        if install_queue_running:
            return
        install_queue_running = True
    
    while True:
        with install_queue_lock:
            if not install_queue:
                install_queue_running = False
                break
            task = install_queue.pop(0)
            task['status'] = 'running'
        
        # 执行安装
        try:
            cmd = [f'{SCRIPT_DIR}/main.sh', 'install', task['software']]
            if task.get('version'):
                cmd.append(task['version'])
            
            install_logs[task['task_id']] = []
            
            process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                     text=True, bufsize=1, universal_newlines=True)
            
            for line in iter(process.stdout.readline, ''):
                if line:
                    install_logs[task['task_id']].append(line.rstrip())
                    socketio.emit('install_log', {'task_id': task['task_id'], 'line': line.rstrip()})
            
            process.wait()
            
            success = process.returncode == 0
            task['status'] = 'done'
            socketio.emit('install_complete', {
                'task_id': task['task_id'],
                'success': success,
                'logs': install_logs[task['task_id']]
            })
        except Exception as e:
            task['status'] = 'done'
            socketio.emit('install_complete', {
                'task_id': task['task_id'],
                'success': False,
                'error': str(e),
                'logs': install_logs.get(task['task_id'], [])
            })
    
    with install_queue_lock:
        install_queue_running = False

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
        return jsonify({'success': False, 'error': str(e)}

@app.route('/api/restore', methods=['POST'])
def restore():
    data = request.json
    target = data.get('target', '')
    backup_file = data.get('backup_file', '')
    
    if not target or not backup_file:
        return jsonify({'success': False, 'error': '请指定恢复目标和备份文件'})
    
    try:
        cmd = [f'{SCRIPT_DIR}/backup/backup.sh', 'restore', target, backup_file]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        return jsonify({
            'success': result.returncode == 0,
            'output': result.stdout,
            'error': result.stderr
        })
    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'error': '恢复超时'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/backup/list')
def backup_list():
    backup_dir = '/var/backups/shell-utils'
    backups = {}
    
    try:
        if os.path.isdir(backup_dir):
            for subdir in os.listdir(backup_dir):
                sub_path = os.path.join(backup_dir, subdir)
                if os.path.isdir(sub_path):
                    files = []
                    for f in sorted(os.listdir(sub_path), reverse=True):
                        fpath = os.path.join(sub_path, f)
                        if os.path.isfile(fpath):
                            stat = os.stat(fpath)
                            files.append({
                                'name': f,
                                'path': fpath,
                                'size': round(stat.st_size / 1024, 1),  # KB
                                'time': time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(stat.st_mtime))
                            })
                    if files:
                        backups[subdir] = files[:20]  # 最多显示20个
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})
    
    return jsonify({'success': True, 'data': backups})

@app.route('/api/update/check')
def check_update():
    try:
        result = subprocess.run([f'{SCRIPT_DIR}/update.sh', 'check'], 
                              capture_output=True, text=True)
        return jsonify({'success': True, 'output': result.stdout})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/update/run', methods=['POST'])
def run_update():
    try:
        result = subprocess.run([f'{SCRIPT_DIR}/update.sh', 'update'], 
                              capture_output=True, text=True, timeout=300,
                              input='yes\n')
        success = result.returncode == 0
        
        # 升级成功后自动重启WebUI
        if success:
            try:
                pid_file = os.path.join(SCRIPT_DIR, 'webui', 'pid.txt')
                if os.path.isfile(pid_file):
                    with open(pid_file) as f:
                        old_pid = f.read().strip()
                    if old_pid:
                        os.kill(int(old_pid), 9)
                    os.remove(pid_file)
            except:
                pass
            
            # 延迟重启
            def restart_webui():
                time.sleep(2)
                subprocess.Popen([f'{SCRIPT_DIR}/webui/start.sh'],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
            thread = threading.Thread(target=restart_webui)
            thread.start()
            
            return jsonify({
                'success': True,
                'output': result.stdout + '\n\n✅ 升级完成，WebUI 正在重启...',
                'restart': True
            })
        
        return jsonify({
            'success': False,
            'output': result.stdout,
            'error': result.stderr
        })
    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'error': '升级超时'})
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

@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True, allow_unsafe_werkzeug=True)
