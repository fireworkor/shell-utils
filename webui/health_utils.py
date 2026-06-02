#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
健康检查和资源清理工具模块
"""
import os
import sys
import time
import psutil
import gc
from datetime import datetime, timedelta
from utils import logger, WEBUI_DIR


def get_system_health():
    """获取系统健康状态"""
    try:
        health = {}
        
        # CPU 使用率
        health['cpu_percent'] = psutil.cpu_percent(interval=1)
        
        # 内存使用
        mem = psutil.virtual_memory()
        health['memory'] = {
            'percent': mem.percent,
            'used_mb': round(mem.used / 1024 / 1024, 2),
            'total_mb': round(mem.total / 1024 / 1024, 2),
            'available_mb': round(mem.available / 1024 / 1024, 2)
        }
        
        # 磁盘使用
        disk = psutil.disk_usage('/')
        health['disk'] = {
            'percent': disk.percent,
            'used_gb': round(disk.used / 1024 / 1024 / 1024, 2),
            'total_gb': round(disk.total / 1024 / 1024 / 1024, 2)
        }
        
        # 网络 IO
        net = psutil.net_io_counters()
        health['network'] = {
            'bytes_sent_mb': round(net.bytes_sent / 1024 / 1024, 2),
            'bytes_recv_mb': round(net.bytes_recv / 1024 / 1024, 2)
        }
        
        # 进程数
        health['process_count'] = len(list(psutil.process_iter()))
        
        # 正常运行时间
        boot_time = datetime.fromtimestamp(psutil.boot_time())
        uptime = datetime.now() - boot_time
        health['uptime_seconds'] = uptime.total_seconds()
        health['uptime_str'] = str(uptime).split('.')[0]
        
        return {'success': True, 'data': health}
    except Exception as e:
        logger.error(f"获取系统健康状态失败: {e}")
        return {'success': False, 'error': str(e)}


def cleanup_old_logs(max_age_days=7, max_size_mb=100):
    """清理旧日志文件"""
    try:
        logs_dir = os.path.join(WEBUI_DIR, 'logs')
        if not os.path.exists(logs_dir):
            return {'success': True, 'message': '日志目录不存在'}
        
        cleaned_files = []
        now = time.time()
        max_age_seconds = max_age_days * 24 * 60 * 60
        max_size_bytes = max_size_mb * 1024 * 1024
        
        for filename in os.listdir(logs_dir):
            filepath = os.path.join(logs_dir, filename)
            
            if os.path.isfile(filepath):
                stat = os.stat(filepath)
                
                # 检查文件年龄
                if (now - stat.st_mtime) > max_age_seconds:
                    os.remove(filepath)
                    cleaned_files.append({
                        'file': filename,
                        'reason': 'age',
                        'age_days': round((now - stat.st_mtime) / 86400, 1)
                    })
                # 检查文件大小（轮换）
                elif stat.st_size > max_size_bytes:
                    # 备份旧文件
                    backup_path = f"{filepath}.{int(now)}"
                    os.rename(filepath, backup_path)
                    cleaned_files.append({
                        'file': filename,
                        'reason': 'size',
                        'size_mb': round(stat.st_size / 1024 / 1024, 2)
                    })
        
        logger.info(f"清理完成，处理了 {len(cleaned_files)} 个文件")
        return {
            'success': True,
            'cleaned_count': len(cleaned_files),
            'files': cleaned_files
        }
    except Exception as e:
        logger.error(f"清理旧日志失败: {e}")
        return {'success': False, 'error': str(e)}


def force_gc():
    """强制垃圾回收"""
    try:
        gc.collect()
        gc.collect()  # 多次收集以提高效果
        
        # 获取收集统计
        stats = gc.get_stats()
        logger.info(f"垃圾回收完成: {stats}")
        
        return {
            'success': True,
            'stats': stats
        }
    except Exception as e:
        logger.error(f"垃圾回收失败: {e}")
        return {'success': False, 'error': str(e)}


def cleanup_temporary_files():
    """清理临时文件"""
    try:
        cleaned = []
        temp_dirs = ['/tmp', '/var/tmp']
        
        for temp_dir in temp_dirs:
            if not os.path.exists(temp_dir):
                continue
                
            for filename in os.listdir(temp_dir):
                filepath = os.path.join(temp_dir, filename)
                
                try:
                    if os.path.isfile(filepath):
                        stat = os.stat(filepath)
                        # 删除超过24小时的临时文件
                        if time.time() - stat.st_mtime > 86400:
                            os.remove(filepath)
                            cleaned.append(filepath)
                except Exception as e:
                    # 忽略无法删除的文件
                    logger.debug(f"无法删除临时文件 {filepath}: {e}")
        
        logger.info(f"清理了 {len(cleaned)} 个临时文件")
        return {
            'success': True,
            'cleaned_count': len(cleaned),
            'files': cleaned[:50]  # 只返回前50个以避免日志过大
        }
    except Exception as e:
        logger.error(f"清理临时文件失败: {e}")
        return {'success': False, 'error': str(e)}


def check_disk_space(threshold_percent=90):
    """检查磁盘空间"""
    try:
        disk = psutil.disk_usage('/')
        warning = disk.percent >= threshold_percent
        
        return {
            'success': True,
            'percent': disk.percent,
            'warning': warning,
            'message': f"磁盘使用率: {disk.percent}%" + (" - 警告！空间不足" if warning else "")
        }
    except Exception as e:
        logger.error(f"检查磁盘空间失败: {e}")
        return {'success': False, 'error': str(e)}


def run_full_cleanup():
    """执行完整清理"""
    results = {
        'logs': cleanup_old_logs(),
        'temp': cleanup_temporary_files(),
        'gc': force_gc(),
        'disk_check': check_disk_space()
    }
    
    return results

