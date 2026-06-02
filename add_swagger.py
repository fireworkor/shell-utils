#!/usr/bin/env python3
import os

app_file = '/workspace/webui/app.py'

with open(app_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
swagger_imported = False

for i, line in enumerate(lines):
    new_lines.append(line)
    
    if 'from flask_socketio import SocketIO, emit' in line and not swagger_imported:
        new_lines.append('from flasgger import Swagger\n')
        swagger_imported = True

content = ''.join(new_lines)

content = content.replace(
    'socketio = SocketIO(app, cors_allowed_origins="*", async_mode=\'threading\')',
    '''socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

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

swagger = Swagger(app, config=swagger_config, template=swagger_template)'''
)

with open(app_file, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"已更新: {app_file}")
print("添加了 Swagger 支持")
