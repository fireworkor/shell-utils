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
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.utils import formatdate
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

# =========================================
# 邮件预警模块
# =========================================

def init_alert_db():
    """初始化预警配置表"""
    conn = get_db()
    conn.execute('''
        CREATE TABLE IF NOT EXISTS alert_config (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            smtp_host TEXT DEFAULT '',
            smtp_port INTEGER DEFAULT 465,
            smtp_user TEXT DEFAULT '',
            smtp_pass TEXT DEFAULT '',
            smtp_ssl INTEGER DEFAULT 1,
            sender_name TEXT DEFAULT '运维工具',
            receivers TEXT DEFAULT '',
            enabled INTEGER DEFAULT 0
        )
    ''')
    conn.execute('''
        CREATE TABLE IF NOT EXISTS alert_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            module TEXT NOT NULL UNIQUE,
            enabled INTEGER DEFAULT 0,
            on_success INTEGER DEFAULT 0,
            on_fail INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    # 插入默认预警规则
    default_rules = [
        ('healthcheck', 0, 0, 1),
        ('security', 0, 0, 1),
        ('backup', 0, 0, 1),
        ('restore', 0, 0, 1),
        ('daily', 0, 0, 1),
    ]
    for rule in default_rules:
        conn.execute('INSERT OR IGNORE INTO alert_rules (module, enabled, on_success, on_fail) VALUES (?, ?, ?, ?)', rule)
    conn.commit()
    conn.close()

def get_alert_config():
    """获取邮件配置"""
    conn = get_db()
    row = conn.execute('SELECT * FROM alert_config ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()
    if row:
        return dict(row)
    return {'smtp_host': '', 'smtp_port': 465, 'smtp_user': '', 'smtp_pass': '', 'smtp_ssl': 1, 'sender_name': '运维工具', 'receivers': '', 'enabled': 0}

def get_alert_rules():
    """获取预警规则"""
    conn = get_db()
    rows = conn.execute('SELECT * FROM alert_rules').fetchall()
    conn.close()
    return [dict(row) for row in rows]

def send_alert_email(module, title, content, success=True):
    """发送预警邮件"""
    config = get_alert_config()
    if not config.get('enabled') or not config.get('smtp_host'):
        return False
    
    rules = get_alert_rules()
    rule = next((r for r in rules if r['module'] == module), None)
    if not rule or not rule.get('enabled'):
        return False
    
    # 检查是否需要发送
    if success and not rule.get('on_success'):
        return False
    if not success and not rule.get('on_fail'):
        return False
    
    receivers = config.get('receivers', '')
    if not receivers:
        return False
    
    try:
        msg = MIMEMultipart()
        status = '✅ 成功' if success else '❌ 异常'
        msg['Subject'] = f'[运维预警] [{status}] {title}'
        msg['From'] = f"{config.get('sender_name', '运维工具')} <{config.get('smtp_user', '')}>"
        msg['To'] = receivers
        msg['Date'] = formatdate(localtime=True)
        
        html = f"""
        <html><body style="font-family: Arial, sans-serif; padding: 20px;">
        <h2 style="color: {'#27ae60' if success else '#e74c3c'};">{status} {title}</h2>
        <table style="border-collapse: collapse; width: 100%; margin-top: 16px;">
            <tr><td style="padding: 8px; border: 1px solid #ddd; background: #f8f9fa; width: 100px;">模块</td>
                <td style="padding: 8px; border: 1px solid #ddd;">{module}</td></tr>
            <tr><td style="padding: 8px; border: 1px solid #ddd; background: #f8f9fa;">状态</td>
                <td style="padding: 8px; border: 1px solid #ddd;">{status}</td></tr>
            <tr><td style="padding: 8px; border: 1px solid #ddd; background: #f8f9fa;">时间</td>
                <td style="padding: 8px; border: 1px solid #ddd;">{time.strftime('%Y-%m-%d %H:%M:%S')}</td></tr>
            <tr><td style="padding: 8px; border: 1px solid #ddd; background: #f8f9fa;">服务器</td>
                <td style="padding: 8px; border: 1px solid #ddd;">{os.uname().nodename}</td></tr>
        </table>
        <h3 style="margin-top: 20px;">详细输出：</h3>
        <pre style="background: #f4f4f4; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 13px; white-space: pre-wrap;">{content[:3000]}</pre>
        <hr style="margin-top: 20px; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px;">此邮件由运维工具管理平台自动发送</p>
        </body></html>
        """
        
        msg.attach(MIMEText(html, 'html', 'utf-8'))
        
        if config.get('smtp_ssl'):
            server = smtplib.SMTP_SSL(config['smtp_host'], config.get('smtp_port', 465), timeout=10)
        else:
            server = smtplib.SMTP(config['smtp_host'], config.get('smtp_port', 25), timeout=10)
        
        if config.get('smtp_user') and config.get('smtp_pass'):
            server.login(config['smtp_user'], config['smtp_pass'])
        
        server.sendmail(config['smtp_user'], receivers.split(','), msg.as_string())
        server.quit()
        print(f'[Alert] 邮件已发送: {title}')
        return True
    except Exception as e:
        print(f'[Alert] 邮件发送失败: {str(e)}')
        return False

# 启动时初始化
init_alert_db()

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
    data = request.json or {}
    target = data.get('target', 'all')
    
    try:
        cmd = [f'{SCRIPT_DIR}/healthcheck/healthcheck.sh']
        if target and target != 'all':
            cmd.append(target)
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        output = result.stdout + result.stderr
        success = result.returncode == 0
        
        # 发送预警邮件
        send_alert_email('healthcheck', f'健康检查 ({target})', output, success)
        
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr,
            'alert_sent': True
        })
    except subprocess.TimeoutExpired:
        send_alert_email('healthcheck', f'健康检查超时 ({target})', '执行超时', False)
        return jsonify({'success': False, 'error': '超时'})
    except Exception as e:
        send_alert_email('healthcheck', f'健康检查异常 ({target})', str(e), False)
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/security', methods=['POST'])
def security():
    data = request.json or {}
    target = data.get('target', 'all')
    
    try:
        cmd = [f'{SCRIPT_DIR}/security-baseline/security-baseline.sh']
        if target and target != 'all':
            cmd.append(target)
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        output = result.stdout + result.stderr
        success = result.returncode == 0
        
        # 发送预警邮件
        send_alert_email('security', f'安全扫描 ({target})', output, success)
        
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr,
            'alert_sent': True
        })
    except subprocess.TimeoutExpired:
        send_alert_email('security', f'安全扫描超时 ({target})', '执行超时', False)
        return jsonify({'success': False, 'error': '超时'})
    except Exception as e:
        send_alert_email('security', f'安全扫描异常 ({target})', str(e), False)
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/daily', methods=['POST'])
def daily_check():
    try:
        result = subprocess.run([f'{SCRIPT_DIR}/daily-check.sh'], 
                              capture_output=True, text=True, timeout=120)
        output = result.stdout + result.stderr
        success = result.returncode == 0
        send_alert_email('daily', '日常巡检', output, success)
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr,
            'alert_sent': True
        })
    except subprocess.TimeoutExpired:
        send_alert_email('daily', '日常巡检超时', '执行超时', False)
        return jsonify({'success': False, 'error': '超时'})
    except Exception as e:
        send_alert_email('daily', '日常巡检异常', str(e), False)
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
        output = result.stdout + result.stderr
        success = result.returncode == 0
        send_alert_email('backup', f'数据备份 ({target})', output, success)
        return jsonify({
            'success': success,
            'output': result.stdout,
            'error': result.stderr,
            'alert_sent': True
        })
    except subprocess.TimeoutExpired:
        send_alert_email('backup', f'备份超时 ({target})', '执行超时', False)
        return jsonify({'success': False, 'error': '备份超时'})
    except Exception as e:
        send_alert_email('backup', f'备份异常 ({target})', str(e), False)
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
        output = result.stdout + result.stderr
        success = result.returncode == 0
        send_alert_email('restore', f'数据恢复 ({target})', output, success)
        return jsonify({
            'success': success,
            'output': result.stdout,
            'error': result.stderr,
            'alert_sent': True
        })
    except subprocess.TimeoutExpired:
        send_alert_email('restore', f'恢复超时 ({target})', '执行超时', False)
        return jsonify({'success': False, 'error': '恢复超时'})
    except Exception as e:
        send_alert_email('restore', f'恢复异常 ({target})', str(e), False)
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
        'webui': [os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logs', 'webui.log')],
    }
    
    paths = log_paths.get(service, ['/var/log/messages'])
    
    # 找到第一个存在的日志文件
    log_path = None
    for p in paths:
        # 支持通配符
        import glob
        matches = glob.glob(p)
        if matches:
            log_path = matches[0]
            break
    
    if not log_path:
        return jsonify({'success': False, 'error': f'未找到 {service} 的日志文件'})
    
    try:
        result = subprocess.run(['tail', '-100', log_path], 
                              capture_output=True, text=True)
        return jsonify({'success': True, 'data': result.stdout, 'file': log_path})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/logs/list')
def list_logs():
    """获取所有可用的日志类型"""
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

@app.route('/api/alert/config')
def api_get_alert_config():
    """获取邮件预警配置"""
    config = get_alert_config()
    config['smtp_pass'] = '●●●●●●' if config.get('smtp_pass') else ''
    return jsonify(config)

@app.route('/api/alert/config', methods=['POST'])
def api_save_alert_config():
    """保存邮件预警配置"""
    data = request.json
    conn = get_db()
    conn.execute('DELETE FROM alert_config')
    conn.execute('''
        INSERT INTO alert_config (smtp_host, smtp_port, smtp_user, smtp_pass, smtp_ssl, sender_name, receivers, enabled)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        data.get('smtp_host', ''),
        data.get('smtp_port', 465),
        data.get('smtp_user', ''),
        data.get('smtp_pass', ''),
        data.get('smtp_ssl', 1),
        data.get('sender_name', '运维工具'),
        data.get('receivers', ''),
        data.get('enabled', 0)
    ))
    conn.commit()
    conn.close()
    return jsonify({'success': True})

@app.route('/api/alert/rules')
def api_get_alert_rules():
    """获取预警规则"""
    return jsonify(get_alert_rules())

@app.route('/api/alert/rules', methods=['POST'])
def api_save_alert_rules():
    """保存预警规则"""
    data = request.json
    rules = data.get('rules', [])
    conn = get_db()
    for rule in rules:
        conn.execute('''
            UPDATE alert_rules SET enabled = ?, on_success = ?, on_fail = ? WHERE module = ?
        ''', (rule.get('enabled', 0), rule.get('on_success', 0), rule.get('on_fail', 1), rule.get('module')))
    conn.commit()
    conn.close()
    return jsonify({'success': True})

@app.route('/api/alert/test', methods=['POST'])
def api_test_alert():
    """发送测试邮件"""
    config = get_alert_config()
    if not config.get('smtp_host') or not config.get('smtp_user'):
        return jsonify({'success': False, 'error': '请先配置SMTP信息'})
    
    success = send_alert_email('test', '测试邮件', '这是一封测试邮件，如果您收到此邮件，说明邮件预警配置正确。', True)
    return jsonify({'success': success, 'error': '' if success else '发送失败，请检查配置'})

@app.route('/api/healthcheck/options')
def healthcheck_options():
    """获取健康检查支持的软件列表"""
    # 从脚本目录动态获取
    options = []
    for item in os.listdir(SCRIPT_DIR):
        item_path = os.path.join(SCRIPT_DIR, item)
        if os.path.isdir(item_path) and item not in ['lib', 'config', 'uninstall', 'examples', 
                                                      'security-baseline', 'kubernetes', 
                                                      'docker-compose-templates', 'docker-manager',
                                                      'webui', 'healthcheck', 'backup']:
            script_file = os.path.join(item_path, f'{item}.sh')
            if os.path.isfile(script_file):
                display_name = item.replace('-', ' ').replace('_', ' ').title()
                options.append({'value': item, 'label': display_name})
    return jsonify(sorted(options, key=lambda x: x['label']))

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
