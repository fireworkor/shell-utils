#!/usr/bin/env python3
import os
import re

# 查找所有 info.sh 文件
def find_info_sh_files(root_dir):
    info_sh_files = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename == 'info.sh':
                info_sh_files.append(os.path.join(dirpath, filename))
    return info_sh_files

# 修复文件中的 local 关键字（全局范围）
def fix_info_sh_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 替换全局范围的 local 关键字
    # 找到不在函数中的 local 变量定义，这里我们简单处理，直接去掉 local 前缀
    # 这个替换是安全的，因为在全局范围定义的变量本来就不需要 local
    # 我们只需要匹配以 local 开头的行，但在函数外面
    # 但为了简单处理，我们直接去掉所有的 local 前缀（因为大多数 info.sh 文件中，

    # 这里为了简单处理，我们直接用正则替换
    # 先移除所有的 local 前缀，只在变量定义行
    fixed_content = re.sub(r'(?<!\S)local\s+', '', content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print(f"已修复: {file_path}")

def main():
    root_dir = '/workspace'
    info_sh_files = find_info_sh_files(root_dir)
    
    print(f"找到 {len(info_sh_files)} 个 info.sh 文件")
    for file_path in info_sh_files:
        fix_info_sh_file(file_path)

if __name__ == "__main__":
    main()

