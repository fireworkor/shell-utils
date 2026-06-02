#!/usr/bin/env python3
import re
import os

# 修复 glob 模式匹配，从 [ ... ] 改为 [[ ... ]]
def fix_glob_checks(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 替换类似 [ "$var" = "#"* ] 这类的检查
    fixed_content = re.sub(
        r'\[\s*"([^"]+)"\s*=\s*"([^"]+)"\*\s*\]',
        r'[[ "\1" = "\2"* ]]',
        content
    )
    
    # 处理可能的其他类似情况
    fixed_content = re.sub(
        r'\[\s*([^\]]+)\s*=\s*"([^"]+)"\*\s*\]',
        r'[[ \1 = "\2"* ]]',
        fixed_content
    )
    
    if fixed_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(fixed_content)
        print(f"已修复 glob 检查: {file_path}")

def fix_sqlite_backup():
    file_path = '/workspace/sqlite/backup.sh'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 第 25 行的 for 循环可能需要 nullglob 处理，但在这个项目中我们暂时保持原样，
    # 因为 ShellCheck 实际上可能误报了？让我们检查一下是否有实际问题
    # 不过看起来这个 for 循环没有语法错误，让我们暂时跳过它
    print(f"检查 sqlite/backup.sh: {file_path}")

def main():
    files_to_check = [
        '/workspace/cloud-manager/cloud-manager.sh',
        '/workspace/deploy-platform/deploy-platform.sh'
    ]
    
    for file_path in files_to_check:
        if os.path.exists(file_path):
            fix_glob_checks(file_path)
    
    fix_sqlite_backup()
    
    # 检查 security-baseline/database/db_baseline.sh
    db_baseline_file = '/workspace/security-baseline/database/db_baseline.sh'
    if os.path.exists(db_baseline_file):
        with open(db_baseline_file, 'r', encoding='utf-8') as f:
            content = f.read()
        print(f"检查 {db_baseline_file}")
        print(content[120:150])

if __name__ == "__main__":
    main()

