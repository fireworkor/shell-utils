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
import sqlite3
import hmac
import hashlib
from flask import Flask, render_template, request, jsonify, redirect, url_for
from flask_socketio import SocketIO, emit
import threading
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app, cors_allowed_origins="*")

SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'webui.db')

# =========================================
# SQLite 数据库初始化
# =========================================

def get_db():
    """获取数据库连接"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """初始化数据库表"""
    conn = get_db()
    conn.execute('''
        CREATE TABLE IF NOT EXISTS software_info (
            name TEXT PRIMARY KEY,
            display_name TEXT DEFAULT '',
            ports TEXT DEFAULT '',
            username TEXT DEFAULT '',
            password TEXT DEFAULT '',
            config_path TEXT DEFAULT '',
            log_path TEXT DEFAULT '',
            description TEXT DEFAULT '',
            notes TEXT DEFAULT '',
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # 插入默认软件信息（如果不存在）
    default_software = [
        ('nginx', 'Nginx', '80, 443', '', '', '/etc/nginx/nginx.conf', '/var/log/nginx/', '高性能Web服务器/反向代理', ''),
        ('mysql', 'MySQL', '3306', 'root', '', '/etc/my.cnf', '/var/log/mariadb/', '关系型数据库', ''),
        ('redis', 'Redis', '6379', '', '', '/etc/redis.conf', '/var/log/redis/', '内存键值数据库', ''),
        ('php', 'PHP', '9000', '', '', '/etc/php.ini', '/var/log/php/', 'PHP运行环境', ''),
        ('docker', 'Docker', '2375, 2376', '', '', '/etc/docker/daemon.json', '/var/log/docker/', '容器引擎', ''),
        ('mongodb', 'MongoDB', '27017', '', '', '/etc/mongod.conf', '/var/log/mongodb/', 'NoSQL数据库', ''),
        ('postgresql', 'PostgreSQL', '5432', 'postgres', '', '/etc/postgresql/', '/var/log/postgresql/', '关系型数据库', ''),
        ('java', 'Java', '', '', '', '', '', 'Java运行环境', ''),
        ('nodejs', 'Node.js', '', '', '', '', '', 'JavaScript运行环境', ''),
        ('go', 'Go', '', '', '', '', '', 'Go语言环境', ''),
        ('ftp', 'FTP (vsftpd)', '21, 40000-40100', '', '', '/etc/vsftpd/vsftpd.conf', '/var/log/xferlog', 'FTP文件传输服务', ''),
        ('samba', 'Samba', '139, 445', '', '', '/etc/samba/smb.conf', '/var/log/samba/', 'SMB/CIFS文件共享', ''),
        ('nfs', 'NFS', '111, 2049', '', '', '/etc/exports', '/var/log/nfs/', '网络文件系统', ''),
    ]
    
    for sw in default_software:
        conn.execute('''
            INSERT OR IGNORE INTO software_info (name, display_name, ports, username, password, config_path, log_path, description, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', sw)
    
    conn.commit()
    conn.close()

# 启动时初始化数据库
init_db()

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

# =========================================
# 软件详细信息管理（SQLite）
# =========================================

@app.route('/api/software/info')
def get_software_info():
    """获取所有软件的详细信息，自动同步可用软件"""
    sync_software_info()
    conn = get_db()
    rows = conn.execute('SELECT * FROM software_info ORDER BY name').fetchall()
    conn.close()
    result = [dict(row) for row in rows]
    return jsonify(result)

def sync_software_info():
    """将脚本目录中所有可用软件同步到数据库（不覆盖已有信息）"""
    # 获取所有可用软件
    available = []
    for item in os.listdir(SCRIPT_DIR):
        item_path = os.path.join(SCRIPT_DIR, item)
        if os.path.isdir(item_path) and item not in ['lib', 'config', 'uninstall', 'examples', 
                                                      'security-baseline', 'kubernetes', 
                                                      'docker-compose-templates', 'docker-manager',
                                                      'webui', 'healthcheck', 'backup']:
            script_file = os.path.join(item_path, f'{item}.sh')
            if os.path.isfile(script_file):
                available.append(item)
    
    conn = get_db()
    for name in available:
        # 检查是否已存在
        row = conn.execute('SELECT name FROM software_info WHERE name = ?', (name,)).fetchone()
        if not row:
            # 自动插入，使用默认值
            display_name = name.replace('-', ' ').replace('_', ' ').title()
            conn.execute('''
                INSERT OR IGNORE INTO software_info (name, display_name, ports, username, password, config_path, log_path, description, notes)
                VALUES (?, ?, '', '', '', '', '', '', '')
            ''', (name, display_name))
    conn.commit()
    conn.close()

@app.route('/api/software/info/<name>')
def get_software_detail(name):
    """获取单个软件的详细信息"""
    conn = get_db()
    row = conn.execute('SELECT * FROM software_info WHERE name = ?', (name,)).fetchone()
    conn.close()
    if row:
        return jsonify(dict(row))
    return jsonify({'error': '未找到'}), 404

@app.route('/api/software/info/<name>', methods=['PUT'])
def update_software_info(name):
    """更新软件详细信息"""
    data = request.json
    conn = get_db()
    conn.execute('''
        UPDATE software_info SET
            display_name = COALESCE(?, display_name),
            ports = COALESCE(?, ports),
            username = COALESCE(?, username),
            password = COALESCE(?, password),
            config_path = COALESCE(?, config_path),
            log_path = COALESCE(?, log_path),
            description = COALESCE(?, description),
            notes = COALESCE(?, notes),
            updated_at = CURRENT_TIMESTAMP
        WHERE name = ?
    ''', (
        data.get('display_name'),
        data.get('ports'),
        data.get('username'),
        data.get('password'),
        data.get('config_path'),
        data.get('log_path'),
        data.get('description'),
        data.get('notes'),
        name
    ))
    conn.commit()
    conn.close()
    return jsonify({'success': True})

@app.route('/api/software/info/<name>', methods=['DELETE'])
def delete_software_info(name):
    """删除软件详细信息"""
    conn = get_db()
    conn.execute('DELETE FROM software_info WHERE name = ?', (name,))
    conn.commit()
    conn.close()
    return jsonify({'success': True})

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
        return jsonify({'success': False, 'error': str(e)})

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

# =========================================
# CI/CD GitHub Webhook
# =========================================

# GitHub Webhook Secret，请设置环境变量 WEBHOOK_SECRET 或在此修改
WEBHOOK_SECRET = os.environ.get('WEBHOOK_SECRET', 'shell-utils-webhook-secret')

@app.route('/api/webhook/github', methods=['POST'])
def github_webhook():
    """接收GitHub Webhook推送事件，自动拉取代码并重启WebUI"""
    # 验证签名
    signature = request.headers.get('X-Hub-Signature-256', '')
    if not verify_github_signature(signature, request.data):
        return jsonify({'error': '签名验证失败'}), 403
    
    payload = request.get_json()
    if not payload:
        return jsonify({'error': '无效的请求体'}), 400
    
    # 只处理push事件
    event = request.headers.get('X-GitHub-Event', '')
    if event != 'push':
        return jsonify({'message': f'忽略事件类型: {event}'}), 200
    
    # 获取推送信息
    ref = payload.get('ref', '')
    branch = ref.replace('refs/heads/', '') if ref.startswith('refs/heads/') else ref
    repo_name = payload.get('repository', {}).get('name', '')
    pusher = payload.get('pusher', {}).get('name', '')
    commits = payload.get('commits', [])
    
    # 只处理master分支
    if branch != 'master':
        return jsonify({'message': f'忽略分支: {branch}，仅处理master分支'}), 200
    
    print(f'[Webhook] 收到推送: {repo_name}/{branch} by {pusher}, {len(commits)} 个提交')
    
    # 在后台线程中执行部署
    def deploy():
        try:
            # 1. 拉取最新代码
            print('[Deploy] 开始拉取代码...')
            result = subprocess.run(
                ['git', 'pull', 'origin', 'master'],
                cwd=SCRIPT_DIR,
                capture_output=True, text=True, timeout=60
            )
            if result.returncode != 0:
                print(f'[Deploy] git pull 失败: {result.stderr}')
                return
            
            print(f'[Deploy] 代码更新成功: {result.stdout.strip()}')
            
            # 2. 安装新的Python依赖（如有变化）
            requirements_file = os.path.join(SCRIPT_DIR, 'webui', 'requirements.txt')
            if os.path.isfile(requirements_file):
                subprocess.run(
                    ['python3', '-m', 'pip', 'install', '-r', requirements_file, '-q'],
                    capture_output=True, text=True, timeout=120
                )
            
            # 3. 重启WebUI
            print('[Deploy] 准备重启WebUI...')
            pid_file = os.path.join(SCRIPT_DIR, 'webui', 'pid.txt')
            if os.path.isfile(pid_file):
                try:
                    with open(pid_file) as f:
                        old_pid = int(f.read().strip())
                    os.kill(old_pid, 9)
                    print(f'[Deploy] 已停止旧进程 PID: {old_pid}')
                    os.remove(pid_file)
                except:
                    pass
            
            # 延迟启动新进程
            import time as t
            t.sleep(2)
            start_script = os.path.join(SCRIPT_DIR, 'webui', 'start.sh')
            subprocess.Popen(
                ['bash', start_script],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            print('[Deploy] WebUI 重启命令已执行')
            
        except Exception as e:
            print(f'[Deploy] 部署失败: {str(e)}')
    
    thread = threading.Thread(target=deploy)
    thread.start()
    
    return jsonify({
        'success': True,
        'message': f'部署已触发: {repo_name}/{branch} by {pusher}',
        'branch': branch,
        'commits': len(commits)
    })

def verify_github_signature(signature, payload):
    """验证GitHub Webhook HMAC-SHA256签名"""
    if not WEBHOOK_SECRET or WEBHOOK_SECRET == 'shell-utils-webhook-secret':
        # 未配置密钥时跳过验证（开发模式）
        return True
    
    if not signature:
        return False
    
    sha_name, signature_hash = signature.split('=', 1)
    if sha_name != 'sha256':
        return False
    
    mac = hmac.new(WEBHOOK_SECRET.encode('utf-8'), msg=payload, digestmod=hashlib.sha256)
    expected = 'sha256=' + mac.hexdigest()
    
    return hmac.compare_digest(expected, signature_hash)

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True, allow_unsafe_werkzeug=True)
