#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
运维工具 Web UI
基于 Flask 和 Flask-SocketIO 的可视化管理平台
"""

import os
import re
import threading
import time
import hmac
import hashlib
import glob
import configparser
from flask import Flask, render_template, request, jsonify
from flask_socketio import SocketIO, emit
from flasgger import Swagger

# 导入自定义模块
from utils import (
    SCRIPT_DIR,
    WEBUI_DIR,
    logger,
    init_database,
    get_db_connection,
    handle_errors,
    safe_subprocess_run
)
from health_utils import (
    get_system_health,
    cleanup_old_logs,
    force_gc,
    cleanup_temporary_files,
    check_disk_space,
    run_full_cleanup
)
from email_alert import (
    get_alert_config,
    get_alert_rules,
    save_alert_config,
    save_alert_rules,
    send_alert_email
)

# 读取配置文件
def load_config():
    """加载配置文件"""
    config_file = os.path.join(WEBUI_DIR, 'config.conf')
    config = {
        'port': int(os.environ.get('PORT', 5000)),
        'host': os.environ.get('HOST', '0.0.0.0'),
        'debug': os.environ.get('FLASK_DEBUG', 'false').lower() == 'true',
        'secret_key': os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production'),
        'webhook_secret': os.environ.get('WEBHOOK_SECRET', 'shell-utils-webhook-secret')
    }
    
    if os.path.exists(config_file):
        try:
            parser = configparser.ConfigParser()
            parser.read(config_file)
            
            if 'webui' in parser:
                section = parser['webui']
                config['port'] = int(section.get('port', config['port']))
                config['host'] = section.get('host', config['host'])
                config['debug'] = section.get('debug', 'false').lower() == 'true'
                config['secret_key'] = section.get('secret_key', config['secret_key'])
                config['webhook_secret'] = section.get('webhook_secret', config['webhook_secret'])
                
            logger.info(f"已加载配置文件: {config_file}")
            logger.info(f"WebUI 将监听 {config['host']}:{config['port']}")
        except Exception as e:
            logger.warning(f"配置文件读取失败: {e}，使用默认值")
    else:
        logger.info(f"配置文件不存在: {config_file}，使用环境变量和默认值")
    
    return config

# 加载配置
WEBUI_CONFIG = load_config()

# 初始化 Flask 应用
app = Flask(__name__)
app.config['SECRET_KEY'] = WEBUI_CONFIG['secret_key']
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

# Swagger 配置
swagger_config = {
    "headers": [],
    "specs": [
        {
            "endpoint": 'apispec',
            "route": '/apispec.json',
            "rule_filter": lambda rule: True,
            "model_filter": lambda tag: True,
        }
    ],
    "static_url_path": "/flasgger_static",
    "swagger_ui": True,
    "specs_route": "/api/docs/"
}

swagger_template = {
    "info": {
        "title": "运维工具 Web UI API",
        "description": "基于 Flask 和 Flask-SocketIO 的可视化管理平台 API",
        "version": "1.0.0"
    },
    "basePath": "/",
    "schemes": ["http", "https"]
}

swagger = Swagger(app, config=swagger_config, template=swagger_template)

# 全局状态
install_logs = {}
install_queue = []
install_queue_running = False
install_queue_lock = threading.Lock()

# GitHub Webhook Secret
WEBHOOK_SECRET = WEBUI_CONFIG['webhook_secret']
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
}

# 初始化
def initialize():
    """应用初始化"""
    logger.info("正在初始化 Web UI...")
    init_database()
    logger.info("Web UI 初始化完成")

initialize()

# ==========================================
# 路由定义
# ==========================================

@app.route('/')
def index():
    """主页"""
    return render_template('index.html')

@app.route('/api/system-info')
@handle_errors
def system_info():
    """系统信息"""
    result = safe_subprocess_run(['bash', '-c', 'hostname && uname -a && uptime'])
    return jsonify({
        'success': True,
        'data': result.stdout
    })

@app.route('/api/services')
@handle_errors
def services():
    """服务列表"""
    try:
        result = safe_subprocess_run(
            ['systemctl', 'list-unit-files', '--type=service', '--state=enabled', '--no-pager']
        )
        service_list = []
        for line in result.stdout.strip().split('\n')[1:]:
            parts = line.split()
            if len(parts) >= 1:
                name = parts[0].replace('.service', '')
                service_list.append({'name': name, 'status': get_service_status(name)})
        return jsonify(service_list)
    except Exception as e:
        logger.warning(f"获取系统服务失败，使用默认列表: {e}")
        fallback = []
        for name in ['nginx', 'mysqld', 'mariadb', 'redis', 'docker', 'sshd', 'firewalld', 'crond']:
            fallback.append({'name': name, 'status': get_service_status(name)})
        return jsonify(fallback)

def get_service_status(service):
    """获取服务状态"""
    try:
        result = safe_subprocess_run(['systemctl', 'is-active', service])
        return result.stdout.strip()
    except:
        return 'unknown'

@app.route('/api/healthcheck', methods=['POST'])
@handle_errors
def healthcheck():
    """健康检查"""
    data = request.json or {}
    target = data.get('target', 'all')
    
    try:
        cmd = [f'{SCRIPT_DIR}/healthcheck/healthcheck.sh']
        if target and target != 'all':
            cmd.append(target)
        
        result = safe_subprocess_run(cmd, timeout=60)
        output = result.stdout + result.stderr
        success = result.returncode == 0
        
        # 发送预警邮件
        send_alert_email('healthcheck', f'健康检查 ({target})', output, success)
        
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr
        })
    except Exception as e:
        send_alert_email('healthcheck', f'健康检查异常 ({target})', str(e), False)
        raise

@app.route('/api/security', methods=['POST'])
@handle_errors
def security():
    """安全基线扫描"""
    data = request.json or {}
    target = data.get('target', 'all')
    
    try:
        cmd = [f'{SCRIPT_DIR}/security-baseline/security-baseline.sh']
        if target and target != 'all':
            cmd.append(target)
        
        result = safe_subprocess_run(cmd, timeout=120)
        output = result.stdout + result.stderr
        success = result.returncode == 0
        
        # 发送预警邮件
        send_alert_email('security', f'安全扫描 ({target})', output, success)
        
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr
        })
    except Exception as e:
        send_alert_email('security', f'安全扫描异常 ({target})', str(e), False)
        raise

@app.route('/api/daily', methods=['POST'])
@handle_errors
def daily_check():
    """日常巡检"""
    try:
        result = safe_subprocess_run([f'{SCRIPT_DIR}/daily-check.sh'], timeout=120)
        output = result.stdout + result.stderr
        success = result.returncode == 0
        
        send_alert_email('daily', '日常巡检', output, success)
        
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr
        })
    except Exception as e:
        send_alert_email('daily', '日常巡检异常', str(e), False)
        raise

@app.route('/api/cpu')
@handle_errors
def cpu_info():
    """CPU信息"""
    result = safe_subprocess_run(['bash', '-c', 'top -bn1 | grep "Cpu(s)" && mpstat 1 1'])
    return jsonify({'success': True, 'data': result.stdout})

@app.route('/api/memory')
@handle_errors
def memory_info():
    """内存信息"""
    result = safe_subprocess_run(['free'])
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
        
        result_h = safe_subprocess_run(['free', '-h'])
        return jsonify({
            'success': True,
            'data': result_h.stdout,
            'percent': round(percent, 1),
            'total': total,
            'used': used
        })
    
    return jsonify({'success': True, 'data': result.stdout})

@app.route('/api/disk')
@handle_errors
def disk_info():
    """磁盘信息"""
    result = safe_subprocess_run(['df', '-h'])
    return jsonify({'success': True, 'data': result.stdout})

@app.route('/api/network')
@handle_errors
def network_info():
    """网络信息"""
    result = safe_subprocess_run(['bash', '-c', 'ip addr show | grep inet && ss -tuln | head -20'])
    return jsonify({'success': True, 'data': result.stdout})

@app.route('/api/processes')
@handle_errors
def processes():
    """进程信息"""
    result = safe_subprocess_run(['bash', '-c', 'ps aux --sort=-%mem | head -20'])
    return jsonify({'success': True, 'data': result.stdout})

# ==========================================
# 软件管理
# ==========================================

def get_available_software():
    """获取可用软件列表"""
    software_list = []
    for item in os.listdir(SCRIPT_DIR):
        item_path = os.path.join(SCRIPT_DIR, item)
        if os.path.isdir(item_path) and item not in [
            'lib', 'config', 'uninstall', 'examples',
            'security-baseline', 'kubernetes',
            'docker-compose-templates', 'docker-manager',
            'webui', 'healthcheck', 'backup'
        ]:
            script_file = os.path.join(item_path, f'{item}.sh')
            if os.path.isfile(script_file):
                software_list.append(item)
    return sorted(software_list)

@app.route('/api/software/list')
@handle_errors
def list_software():
    """软件列表"""
    return jsonify(get_available_software())

@app.route('/api/software/status')
@handle_errors
def software_status():
    """软件状态"""
    available_software = get_available_software()
    status_list = []
    
    for software in available_software:
        check_info = software_check_map.get(software)
        if check_info:
            try:
                result = safe_subprocess_run(check_info['cmd'], shell=True, timeout=5)
                if result.returncode == 0:
                    output = result.stderr.strip() if check_info['stderr'] else result.stdout.strip()
                    version_match = re.search(r'(\d+\.\d+(?:\.\d+)?)', output)
                    version = version_match.group(1) if version_match else output[:50]
                    status_list.append({'name': software, 'status': 'installed', 'version': version})
                else:
                    status_list.append({'name': software, 'status': 'not_installed', 'version': ''})
            except:
                status_list.append({'name': software, 'status': 'not_installed', 'version': ''})
        else:
            try:
                result = safe_subprocess_run(['which', software], timeout=3)
                if result.returncode == 0:
                    version = ''
                    for version_cmd in ['--version', '-v', '-V', 'version']:
                        try:
                            cmd = [software, version_cmd]
                            ver_result = safe_subprocess_run(cmd, timeout=3)
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

def sync_software_info():
    """同步软件信息到数据库"""
    available = get_available_software()
    
    with get_db_connection() as conn:
        for name in available:
            row = conn.execute('SELECT name FROM software_info WHERE name = ?', (name,)).fetchone()
            if not row:
                display_name = name.replace('-', ' ').replace('_', ' ').title()
                conn.execute('''
                    INSERT OR IGNORE INTO software_info (name, display_name, ports, username, password, config_path, log_path, description, notes)
                    VALUES (?, ?, '', '', '', '', '', '', '')
                ''', (name, display_name))
        conn.commit()

@app.route('/api/software/info')
@handle_errors
def get_software_info():
    """获取软件信息"""
    sync_software_info()
    with get_db_connection() as conn:
        rows = conn.execute('SELECT * FROM software_info ORDER BY name').fetchall()
        return jsonify([dict(row) for row in rows])

@app.route('/api/software/info/<name>')
@handle_errors
def get_software_detail(name):
    """获取单个软件详细信息"""
    with get_db_connection() as conn:
        row = conn.execute('SELECT * FROM software_info WHERE name = ?', (name,)).fetchone()
        if row:
            return jsonify(dict(row))
        return jsonify({'error': '未找到'}), 404

@app.route('/api/software/info/<name>', methods=['PUT'])
@handle_errors
def update_software_info(name):
    """更新软件信息"""
    data = request.json
    with get_db_connection() as conn:
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
    return jsonify({'success': True})

@app.route('/api/software/info/<name>', methods=['DELETE'])
@handle_errors
def delete_software_info(name):
    """删除软件信息"""
    with get_db_connection() as conn:
        conn.execute('DELETE FROM software_info WHERE name = ?', (name,))
        conn.commit()
    return jsonify({'success': True})

@app.route('/api/software/install', methods=['POST'])
@handle_errors
def install_software():
    """安装软件"""
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
            
            import subprocess
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
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
            
        except Exception as e:
            error_msg = str(e)
            install_logs[task_id] = install_logs.get(task_id, [])
            install_logs[task_id].append(f'Error: {error_msg}')
            socketio.emit('install_complete', {
                'task_id': task_id,
                'success': False,
                'error': error_msg,
                'logs': install_logs[task_id]
            })
    
    thread = threading.Thread(target=run_install)
    thread.daemon = True
    thread.start()
    
    return jsonify({'success': True, 'task_id': task_id})

@app.route('/api/software/uninstall', methods=['POST'])
@handle_errors
def uninstall_software():
    """卸载软件"""
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
            
            uninstall_script = os.path.join(SCRIPT_DIR, 'uninstall', 'uninstall.sh')
            if not os.path.isfile(uninstall_script):
                emit_log('未找到卸载脚本，尝试通过包管理器卸载...')
                import subprocess
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
                    process = subprocess.Popen(
                        cmd,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        text=True,
                        bufsize=1,
                        universal_newlines=True
                    )
                    for line in iter(process.stdout.readline, ''):
                        if line:
                            emit_log(line.rstrip())
                    process.wait()
                    if process.returncode == 0:
                        break
            else:
                import subprocess
                cmd = ['bash', uninstall_script, software]
                process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    universal_newlines=True
                )
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
            install_logs[task_id] = install_logs.get(task_id, [])
            install_logs[task_id].append(f'Error: {error_msg}')
            socketio.emit('install_complete', {
                'task_id': task_id,
                'success': False,
                'error': error_msg,
                'logs': install_logs[task_id]
            })
    
    thread = threading.Thread(target=run_uninstall)
    thread.daemon = True
    thread.start()
    
    return jsonify({'success': True, 'task_id': task_id})

# ==========================================
# 备份恢复
# ==========================================

@app.route('/api/backup', methods=['POST'])
@handle_errors
def backup():
    """备份"""
    data = request.json
    target = data.get('target', 'all')
    
    try:
        result = safe_subprocess_run([f'{SCRIPT_DIR}/backup/backup.sh', 'backup', target], timeout=120)
        output = result.stdout + result.stderr
        success = result.returncode == 0
        
        send_alert_email('backup', f'数据备份 ({target})', output, success)
        
        return jsonify({
            'success': success,
            'output': result.stdout,
            'error': result.stderr
        })
    except Exception as e:
        send_alert_email('backup', f'备份异常 ({target})', str(e), False)
        raise

@app.route('/api/restore', methods=['POST'])
@handle_errors
def restore():
    """恢复"""
    data = request.json
    target = data.get('target', '')
    backup_file = data.get('backup_file', '')
    
    if not target or not backup_file:
        return jsonify({'success': False, 'error': '请指定恢复目标和备份文件'})
    
    try:
        cmd = [f'{SCRIPT_DIR}/backup/backup.sh', 'restore', target, backup_file]
        result = safe_subprocess_run(cmd, timeout=120)
        output = result.stdout + result.stderr
        success = result.returncode == 0
        
        send_alert_email('restore', f'数据恢复 ({target})', output, success)
        
        return jsonify({
            'success': success,
            'output': result.stdout,
            'error': result.stderr
        })
    except Exception as e:
        send_alert_email('restore', f'恢复异常 ({target})', str(e), False)
        raise

@app.route('/api/backup/list')
@handle_errors
def backup_list():
    """备份列表"""
    backup_dir = '/var/backups/shell-utils'
    backups = {}
    
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
                            'size': round(stat.st_size / 1024, 1),
                            'time': time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(stat.st_mtime))
                        })
                if files:
                    backups[subdir] = files[:20]
    
    return jsonify({'success': True, 'data': backups})

# ==========================================
# 更新管理
# ==========================================

@app.route('/api/update/check')
@handle_errors
def check_update():
    """检查更新"""
    result = safe_subprocess_run([f'{SCRIPT_DIR}/update.sh', 'check'])
    return jsonify({'success': True, 'output': result.stdout})

@app.route('/api/update/run', methods=['POST'])
@handle_errors
def run_update():
    """执行更新"""
    result = safe_subprocess_run(
        [f'{SCRIPT_DIR}/update.sh', 'update'],
        timeout=300,
        input='yes\n'
    )
    success = result.returncode == 0
    
    if success:
        def restart_webui():
            time.sleep(2)
            import subprocess
            subprocess.Popen(
                [f'{WEBUI_DIR}/webui.sh', 'restart'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        
        thread = threading.Thread(target=restart_webui)
        thread.daemon = True
        thread.start()
        
        return jsonify({
            'success': True,
            'output': result.stdout + '\n\n✅ 升级完成，Web UI 正在重启...',
            'restart': True
        })
    
    return jsonify({
        'success': False,
        'output': result.stdout,
        'error': result.stderr
    })

# ==========================================
# 服务控制
# ==========================================

@app.route('/api/service/control', methods=['POST'])
@handle_errors
def service_control():
    """服务控制"""
    data = request.json
    action = data.get('action')
    service = data.get('service')
    
    result = safe_subprocess_run(['systemctl', action, service])
    return jsonify({
        'success': result.returncode == 0,
        'output': result.stdout,
        'error': result.stderr
    })

# ==========================================
# 日志管理
# ==========================================

@app.route('/api/logs/list')
@handle_errors
def list_logs():
    """日志列表"""
    log_services = {
        'nginx': 'Nginx',
        'mysql': 'MySQL/MariaDB',
        'redis': 'Redis',
        'php': 'PHP-FPM',
        'docker': 'Docker',
        'mongodb': 'MongoDB',
        'postgresql': 'PostgreSQL',
        'vsftpd': 'FTP (vsftpd)',
        'samba': 'Samba',
        'sshd': 'SSH',
        'crond': 'Cron 定时任务',
        'firewalld': '防火墙',
        'system': '系统日志',
        'webui': 'WebUI 日志',
    }
    return jsonify(log_services)

@app.route('/api/logs/<service>')
@handle_errors
def get_logs(service):
    """获取日志"""
    log_paths = {
        'nginx': ['/var/log/nginx/access.log', '/var/log/nginx/error.log'],
        'mysql': ['/var/log/mariadb/mariadb.log', '/var/log/mysql/mysqld.log', '/var/log/mysql.log'],
        'redis': ['/var/log/redis/redis.log', '/var/log/redis.log'],
        'php': ['/var/log/php-fpm/error.log', '/var/log/php/error.log'],
        'docker': ['/var/log/docker.log', '/var/log/containers/*.log'],
        'mongodb': ['/var/log/mongodb/mongod.log', '/var/log/mongodb.log'],
        'postgresql': ['/var/log/postgresql/*.log', '/var/log/postgresql.log'],
        'vsftpd': ['/var/log/xferlog', '/var/log/vsftpd.log'],
        'samba': ['/var/log/samba/log.smbd', '/var/log/samba/*.log'],
        'nfs': ['/var/log/nfsd.log', '/var/log/messages'],
        'sshd': ['/var/log/secure', '/var/log/auth.log'],
        'crond': ['/var/log/cron', '/var/log/cron.log'],
        'firewalld': ['/var/log/firewalld'],
        'system': ['/var/log/messages', '/var/log/syslog'],
        'webui': [os.path.join(WEBUI_DIR, 'logs', 'webui.log')],
    }
    
    paths = log_paths.get(service, ['/var/log/messages'])
    log_path = None
    
    for p in paths:
        matches = glob.glob(p)
        if matches:
            log_path = matches[0]
            break
    
    if not log_path:
        return jsonify({'success': False, 'error': f'未找到 {service} 的日志文件'})
    
    result = safe_subprocess_run(['tail', '-100', log_path])
    return jsonify({'success': True, 'data': result.stdout, 'file': log_path})

# ==========================================
# 邮件预警 API
# ==========================================

@app.route('/api/alert/config')
@handle_errors
def api_get_alert_config():
    """获取邮件预警配置"""
    config = get_alert_config()
    config['smtp_pass'] = '●●●●●●' if config.get('smtp_pass') else ''
    return jsonify(config)

@app.route('/api/alert/config', methods=['POST'])
@handle_errors
def api_save_alert_config():
    """保存邮件预警配置"""
    data = request.json
    save_alert_config(data)
    return jsonify({'success': True})

@app.route('/api/alert/rules')
@handle_errors
def api_get_alert_rules():
    """获取预警规则"""
    return jsonify(get_alert_rules())

@app.route('/api/alert/rules', methods=['POST'])
@handle_errors
def api_save_alert_rules():
    """保存预警规则"""
    data = request.json
    rules = data.get('rules', [])
    save_alert_rules(rules)
    return jsonify({'success': True})

@app.route('/api/alert/test', methods=['POST'])
@handle_errors
def api_test_alert():
    """发送测试邮件"""
    config = get_alert_config()
    if not config.get('smtp_host') or not config.get('smtp_user'):
        return jsonify({'success': False, 'error': '请先配置SMTP信息'})
    
    success = send_alert_email('test', '测试邮件', '这是一封测试邮件，如果您收到此邮件，说明邮件预警配置正确。', True)
    return jsonify({'success': success, 'error': '' if success else '发送失败，请检查配置'})

# ==========================================
# 健康检查选项
# ==========================================

@app.route('/api/healthcheck/options')
@handle_errors
def healthcheck_options():
    """健康检查选项"""
    options = []
    available_software = get_available_software()
    for name in available_software:
        display_name = name.replace('-', ' ').replace('_', ' ').title()
        options.append({'value': name, 'label': display_name})
    return jsonify(sorted(options, key=lambda x: x['label']))

# ==========================================
# SocketIO 事件
# ==========================================

@socketio.on('connect')
def handle_connect():
    """客户端连接"""
    logger.info('客户端已连接')

@socketio.on('disconnect')
def handle_disconnect():
    """客户端断开连接"""
    logger.info('客户端已断开连接')


# =========================================
# 系统健康和资源管理 API
# =========================================

@app.route('/api/system/health')
@handle_errors
def api_system_health():
    """获取系统健康状态"""
    return jsonify(get_system_health())


@app.route('/api/cleanup/logs', methods=['POST'])
@handle_errors
def api_cleanup_logs():
    """清理旧日志"""
    data = request.json or {}
    max_age_days = data.get('max_age_days', 7)
    max_size_mb = data.get('max_size_mb', 100)
    return jsonify(cleanup_old_logs(max_age_days=max_age_days, max_size_mb=max_size_mb))


@app.route('/api/cleanup/gc', methods=['POST'])
@handle_errors
def api_force_gc():
    """强制垃圾回收"""
    return jsonify(force_gc())


@app.route('/api/cleanup/temp', methods=['POST'])
@handle_errors
def api_cleanup_temp():
    """清理临时文件"""
    return jsonify(cleanup_temporary_files())


@app.route('/api/system/disk-check')
@handle_errors
def api_disk_check():
    """检查磁盘空间"""
    data = request.json or {}
    threshold = data.get('threshold', 90)
    return jsonify(check_disk_space(threshold_percent=threshold))


@app.route('/api/cleanup/full', methods=['POST'])
@handle_errors
def api_full_cleanup():
    """执行完整清理"""
    return jsonify(run_full_cleanup())

# ==========================================
# GitHub Webhook
# ==========================================

def verify_github_signature(signature, payload):
    """验证 GitHub Webhook 签名"""
    if not WEBHOOK_SECRET or WEBHOOK_SECRET == 'shell-utils-webhook-secret':
        return True
    
    if not signature:
        return False
    
    try:
        sha_name, signature_hash = signature.split('=', 1)
        if sha_name != 'sha256':
            return False
        
        mac = hmac.new(WEBHOOK_SECRET.encode('utf-8'), msg=payload, digestmod=hashlib.sha256)
        expected = 'sha256=' + mac.hexdigest()
        
        return hmac.compare_digest(expected, signature)
    except:
        return False

@app.route('/api/webhook/github', methods=['POST'])
@handle_errors
def github_webhook():
    """GitHub Webhook 处理"""
    signature = request.headers.get('X-Hub-Signature-256', '')
    if not verify_github_signature(signature, request.data):
        return jsonify({'error': '签名验证失败'}), 403
    
    payload = request.get_json()
    if not payload:
        return jsonify({'error': '无效的请求体'}), 400
    
    event = request.headers.get('X-GitHub-Event', '')
    if event != 'push':
        return jsonify({'message': f'忽略事件类型: {event}'}), 200
    
    ref = payload.get('ref', '')
    branch = ref.replace('refs/heads/', '') if ref.startswith('refs/heads/') else ref
    
    if branch != 'master':
        return jsonify({'message': f'忽略分支: {branch}，仅处理master分支'}), 200
    
    repo_name = payload.get('repository', {}).get('name', '')
    pusher = payload.get('pusher', {}).get('name', '')
    
    logger.info(f'收到 GitHub Webhook 推送: {repo_name}/{branch} by {pusher}')
    
    def deploy():
        try:
            logger.info('开始拉取代码...')
            result = safe_subprocess_run(['git', 'pull', 'origin', 'master'], cwd=SCRIPT_DIR, timeout=60)
            
            if result.returncode != 0:
                logger.error(f'git pull 失败: {result.stderr}')
                return
            
            logger.info(f'代码更新成功: {result.stdout.strip()}')
            
            requirements_file = os.path.join(WEBUI_DIR, 'requirements.txt')
            if os.path.isfile(requirements_file):
                safe_subprocess_run(
                    ['python3', '-m', 'pip', 'install', '-r', requirements_file, '-q'],
                    timeout=120
                )
            
            logger.info('准备重启 Web UI...')
            time.sleep(2)
            
            import subprocess
            subprocess.Popen(
                [f'{WEBUI_DIR}/webui.sh', 'restart'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            
            logger.info('Web UI 重启命令已执行')
            
        except Exception as e:
            logger.error(f'部署失败: {str(e)}')
    
    thread = threading.Thread(target=deploy)
    thread.daemon = True
    thread.start()
    
    return jsonify({
        'success': True,
        'message': f'部署已触发: {repo_name}/{branch} by {pusher}',
        'branch': branch
    })


# ==========================================

# ==========================================
# WebUI 配置管理 API
# ==========================================

@app.route('/api/webui/config')
@handle_errors
def get_webui_config():
    """获取 WebUI 配置"""
    config_file = os.path.join(WEBUI_DIR, 'config.conf')
    config_data = {
        'port': WEBUI_CONFIG['port'],
        'host': WEBUI_CONFIG['host'],
        'debug': WEBUI_CONFIG['debug'],
        'config_file': config_file,
        'config_exists': os.path.exists(config_file)
    }
    return jsonify(config_data)

@app.route('/api/webui/config', methods=['POST'])
@handle_errors
def update_webui_config():
    """更新 WebUI 配置"""
    data = request.json
    
    port = data.get('port')
    host = data.get('host')
    debug = data.get('debug')
    
    if port is not None:
        try:
            port = int(port)
            if port < 1 or port > 65535:
                return jsonify({'success': False, 'error': '端口必须在 1-65535 之间'}), 400
        except ValueError:
            return jsonify({'success': False, 'error': '端口必须是数字'}), 400
    
    if host is not None:
        if host not in ['0.0.0.0', '127.0.0.1', 'localhost']:
            return jsonify({'success': False, 'error': '无效的主机地址'}), 400
    
    config_file = os.path.join(WEBUI_DIR, 'config.conf')
    
    # 读取现有配置或创建新配置
    parser = configparser.ConfigParser()
    if os.path.exists(config_file):
        try:
            parser.read(config_file)
        except:
            pass
    
    if 'webui' not in parser:
        parser['webui'] = {}
    
    section = parser['webui']
    
    # 更新配置
    if port is not None:
        section['port'] = str(port)
    if host is not None:
        section['host'] = host
    if debug is not None:
        section['debug'] = 'true' if debug else 'false'
    
    # 写入配置文件
    try:
        with open(config_file, 'w') as f:
            parser.write(f)
        
        logger.info(f'WebUI 配置已更新: port={port}, host={host}, debug={debug}')
        
        # 通知需要重启
        return jsonify({
            'success': True,
            'message': '配置已更新，需要重启 WebUI 才能生效',
            'restart_required': True
        })
    except Exception as e:
        logger.error(f'保存配置失败: {e}')
        return jsonify({'success': False, 'error': f'保存配置失败: {str(e)}'}), 500

@app.route('/api/webui/restart', methods=['POST'])
@handle_errors
def restart_webui():
    """重启 WebUI"""
    try:
        import subprocess
        
        # 记录重启前的端口信息
        old_port = WEBUI_CONFIG['port']
        
        # 使用 webui.sh 脚本重启
        result = subprocess.run(
            [f'{WEBUI_DIR}/webui.sh', 'restart'],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        logger.info('WebUI 重启命令已执行')
        
        return jsonify({
            'success': True,
            'message': 'WebUI 正在重启...',
            'output': result.stdout
        })
    except Exception as e:
        logger.error(f'重启失败: {e}')
        return jsonify({'success': False, 'error': str(e)}), 500

# 主程序入口
# ==========================================

if __name__ == '__main__':
    debug = WEBUI_CONFIG['debug']
    port = WEBUI_CONFIG['port']
    host = WEBUI_CONFIG['host']
    
    logger.info(f'启动 Web UI 服务: {host}:{port}, debug={debug}')
    
    socketio.run(
        app,
        host=host,
        port=port,
        debug=debug,
        allow_unsafe_werkzeug=True
    )
