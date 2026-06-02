#!/usr/bin/env python3
import os

files = [
    '/workspace/cloud-manager/cloud-manager.sh',
    '/workspace/deploy-platform/deploy-platform.sh'
]

for file_path in files:
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 替换错误的 [[ [ "$var"  = "#"* ]]] 为正确的 [[ "$var" = "#"* ]]
        fixed_content = content.replace('[[ [ "$name"  = "#"* ]]]', '[[ "$name" = "#"* ]]')
        fixed_content = fixed_content.replace('[[ [ "$line"  = "#"* ]]]', '[[ "$line" = "#"* ]]')
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(fixed_content)
        
        print(f"已修复: {file_path}")

# 修复 sqlite/backup.sh 的问题
sqlite_backup_file = '/workspace/sqlite/backup.sh'
if os.path.exists(sqlite_backup_file):
    with open(sqlite_backup_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # ShellCheck 认为 for 循环有问题，是因为通配符，我们可以在脚本开头设置 nullglob 或者调整写法
    # 我们在脚本开头添加 shopt -s nullglob
    if 'shopt -s nullglob' not in content:
        lines = content.split('\n')
        # 在 shebang 后添加 nullglob 设置
        for i, line in enumerate(lines):
            if line.startswith('#!/bin/bash'):
                lines.insert(i+1, '\nshopt -s nullglob\n')
                break
        fixed_content = '\n'.join(lines)
        with open(sqlite_backup_file, 'w', encoding='utf-8') as f:
            f.write(fixed_content)
        print(f"已修复: {sqlite_backup_file}")

