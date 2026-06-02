#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
邮件预警模块
处理邮件配置和发送功能
"""

import time
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.utils import formatdate
import smtplib

from utils import logger, get_db_connection

def get_alert_config():
    """获取邮件配置"""
    try:
        with get_db_connection() as conn:
            row = conn.execute('SELECT * FROM alert_config ORDER BY id DESC LIMIT 1').fetchone()
            if row:
                return dict(row)
            return {
                'smtp_host': '',
                'smtp_port': 465,
                'smtp_user': '',
                'smtp_pass': '',
                'smtp_ssl': 1,
                'sender_name': '运维工具',
                'receivers': '',
                'enabled': 0
            }
    except Exception as e:
        logger.error(f"获取邮件配置失败: {e}")
        raise

def get_alert_rules():
    """获取预警规则"""
    try:
        with get_db_connection() as conn:
            rows = conn.execute('SELECT * FROM alert_rules').fetchall()
            return [dict(row) for row in rows]
    except Exception as e:
        logger.error(f"获取预警规则失败: {e}")
        raise

def save_alert_config(config):
    """保存邮件配置"""
    try:
        with get_db_connection() as conn:
            conn.execute('DELETE FROM alert_config')
            conn.execute('''
                INSERT INTO alert_config (smtp_host, smtp_port, smtp_user, smtp_pass, smtp_ssl, sender_name, receivers, enabled)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                config.get('smtp_host', ''),
                config.get('smtp_port', 465),
                config.get('smtp_user', ''),
                config.get('smtp_pass', ''),
                config.get('smtp_ssl', 1),
                config.get('sender_name', '运维工具'),
                config.get('receivers', ''),
                config.get('enabled', 0)
            ))
            conn.commit()
            logger.info("邮件配置已保存")
    except Exception as e:
        logger.error(f"保存邮件配置失败: {e}")
        raise

def save_alert_rules(rules):
    """保存预警规则"""
    try:
        with get_db_connection() as conn:
            for rule in rules:
                conn.execute('''
                    UPDATE alert_rules 
                    SET enabled = ?, on_success = ?, on_fail = ?, updated_at = CURRENT_TIMESTAMP 
                    WHERE module = ?
                ''', (
                    rule.get('enabled', 0),
                    rule.get('on_success', 0),
                    rule.get('on_fail', 1),
                    rule.get('module')
                ))
            conn.commit()
            logger.info("预警规则已保存")
    except Exception as e:
        logger.error(f"保存预警规则失败: {e}")
        raise

def send_alert_email(module, title, content, success=True):
    """发送预警邮件"""
    try:
        config = get_alert_config()
        
        # 检查是否启用
        if not config.get('enabled') or not config.get('smtp_host'):
            logger.debug("邮件预警未启用或配置不完整")
            return False
        
        # 检查规则
        rules = get_alert_rules()
        rule = next((r for r in rules if r['module'] == module), None)
        if not rule or not rule.get('enabled'):
            logger.debug(f"模块 {module} 的预警未启用")
            return False
        
        # 检查是否需要发送
        if success and not rule.get('on_success'):
            logger.debug(f"模块 {module} 成功时不发送预警")
            return False
        if not success and not rule.get('on_fail'):
            logger.debug(f"模块 {module} 失败时不发送预警")
            return False
        
        receivers = config.get('receivers', '')
        if not receivers:
            logger.warning("收件人列表为空")
            return False
        
        logger.info(f"准备发送预警邮件: {title}")
        
        msg = MIMEMultipart()
        status_text = '✅ 成功' if success else '❌ 异常'
        msg['Subject'] = f'[运维预警] [{status_text}] {title}'
        msg['From'] = f"{config.get('sender_name', '运维工具')} <{config.get('smtp_user', '')}>"
        msg['To'] = receivers
        msg['Date'] = formatdate(localtime=True)
        
        html = f'''
        <html><body style="font-family: Arial, sans-serif; padding: 20px; max-width: 800px; margin: 0 auto;">
        <h2 style="color: {'#27ae60' if success else '#e74c3c'}; border-bottom: 2px solid {'#27ae60' if success else '#e74c3c'}; padding-bottom: 10px;">
            {status_text} {title}
        </h2>
        <table style="border-collapse: collapse; width: 100%; margin-top: 16px;">
            <tr>
                <td style="padding: 12px; border: 1px solid #ddd; background: #f8f9fa; width: 120px; font-weight: bold;">模块</td>
                <td style="padding: 12px; border: 1px solid #ddd;">{module}</td>
            </tr>
            <tr>
                <td style="padding: 12px; border: 1px solid #ddd; background: #f8f9fa; font-weight: bold;">状态</td>
                <td style="padding: 12px; border: 1px solid #ddd;">{status_text}</td>
            </tr>
            <tr>
                <td style="padding: 12px; border: 1px solid #ddd; background: #f8f9fa; font-weight: bold;">时间</td>
                <td style="padding: 12px; border: 1px solid #ddd;">{time.strftime('%Y-%m-%d %H:%M:%S')}</td>
            </tr>
            <tr>
                <td style="padding: 12px; border: 1px solid #ddd; background: #f8f9fa; font-weight: bold;">服务器</td>
                <td style="padding: 12px; border: 1px solid #ddd;">{os.uname().nodename if hasattr(os, 'uname') else 'Unknown'}</td>
            </tr>
        </table>
        <h3 style="margin-top: 24px; color: #333;">详细输出：</h3>
        <pre style="background: #f4f4f4; padding: 16px; border-radius: 6px; overflow-x: auto; font-size: 13px; white-space: pre-wrap; border: 1px solid #e0e0e0;">{content[:5000]}</pre>
        <hr style="margin-top: 24px; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px; text-align: center;">此邮件由运维工具管理平台自动发送，请勿直接回复</p>
        </body></html>
        '''
        
        msg.attach(MIMEText(html, 'html', 'utf-8'))
        
        # 连接SMTP服务器
        if config.get('smtp_ssl'):
            server = smtplib.SMTP_SSL(config['smtp_host'], config.get('smtp_port', 465), timeout=30)
        else:
            server = smtplib.SMTP(config['smtp_host'], config.get('smtp_port', 25), timeout=30)
            # 尝试STARTTLS
            try:
                server.starttls()
            except:
                pass
        
        # 认证
        if config.get('smtp_user') and config.get('smtp_pass'):
            server.login(config['smtp_user'], config['smtp_pass'])
        
        # 发送邮件
        server.sendmail(config['smtp_user'], [r.strip() for r in receivers.split(',')], msg.as_string())
        server.quit()
        
        logger.info(f"预警邮件发送成功: {title}")
        return True
        
    except Exception as e:
        logger.error(f"邮件发送失败: {str(e)}", exc_info=True)
        return False

