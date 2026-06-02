#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
通用工具模块
包含日志、配置、数据库等通用功能
"""

import os
import sys
import logging
from logging.handlers import RotatingFileHandler
import sqlite3
from contextlib import contextmanager
from functools import wraps
from flask import jsonify

# 全局配置
SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEBUI_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(WEBUI_DIR, 'webui.db')
LOG_DIR = os.path.join(WEBUI_DIR, 'logs')
LOG_FILE = os.path.join(LOG_DIR, 'webui.log')

# 创建日志目录
os.makedirs(LOG_DIR, exist_ok=True)

# 配置日志
def setup_logging():
    """配置日志系统"""
    logger = logging.getLogger('webui')
    logger.setLevel(logging.INFO)
    
    # 避免重复添加handler
    if logger.handlers:
        return logger
    
    # 文件处理器
    file_handler = RotatingFileHandler(
        LOG_FILE,
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5,
        encoding='utf-8'
    )
    file_formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    file_handler.setFormatter(file_formatter)
    
    # 控制台处理器
    console_handler = logging.StreamHandler(sys.stdout)
    console_formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    console_handler.setFormatter(console_formatter)
    
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    
    return logger

logger = setup_logging()

# 数据库上下文管理器
@contextmanager
def get_db_connection():
    """获取数据库连接的上下文管理器"""
    conn = None
    try:
        conn = sqlite3.connect(DB_PATH, timeout=30)
        conn.row_factory = sqlite3.Row
        conn.execute('PRAGMA journal_mode=WAL')  # 启用WAL模式提高并发
        yield conn
    except sqlite3.Error as e:
        logger.error(f"数据库错误: {e}")
        raise
    finally:
        if conn:
            conn.close()

def execute_db_query(query, params=(), fetch=False, commit=False):
    """执行数据库查询的辅助函数"""
    with get_db_connection() as conn:
        cursor = conn.cursor()
        try:
            cursor.execute(query, params)
            if commit:
                conn.commit()
            if fetch:
                return cursor.fetchall()
        except sqlite3.Error as e:
            logger.error(f"查询执行失败: {query}, 错误: {e}")
            raise

def init_database():
    """初始化数据库表"""
    try:
        with get_db_connection() as conn:
            # 软件信息表
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
            
            # 预警配置表
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
                    enabled INTEGER DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # 预警规则表
            conn.execute('''
                CREATE TABLE IF NOT EXISTS alert_rules (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    module TEXT NOT NULL UNIQUE,
                    enabled INTEGER DEFAULT 0,
                    on_success INTEGER DEFAULT 0,
                    on_fail INTEGER DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
                conn.execute('''
                    INSERT OR IGNORE INTO alert_rules (module, enabled, on_success, on_fail)
                    VALUES (?, ?, ?, ?)
                ''', rule)
            
            conn.commit()
            logger.info("数据库初始化完成")
            
    except Exception as e:
        logger.error(f"数据库初始化失败: {e}")
        raise

def handle_errors(f):
    """装饰器：统一处理API错误"""
    @wraps(f)
    def wrapped(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except Exception as e:
            logger.error(f"API错误: {str(e)}", exc_info=True)
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500
    return wrapped

def safe_subprocess_run(cmd, capture_output=True, text=True, timeout=None, **kwargs):
    """安全的subprocess.run封装"""
    import subprocess
    
    logger.debug(f"执行命令: {cmd}")
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=capture_output,
            text=text,
            timeout=timeout,
            **kwargs
        )
        logger.debug(f"命令执行完成，返回码: {result.returncode}")
        return result
    except subprocess.TimeoutExpired as e:
        logger.error(f"命令执行超时: {cmd}")
        raise
    except Exception as e:
        logger.error(f"命令执行失败: {cmd}, 错误: {e}")
        raise

