#!/usr/bin/env python3
# 修复 menu.sh 中的 echo 语句，确保都使用 -e 选项

import sys
import re

# 读取完整的文件
with open('menu.sh', 'r', encoding='utf-8') as f:
    content = f.read()

# 定义需要替换的模式
patterns = [
    (r'^(\s*)echo "(\${YELLOW})', r'\1echo -e "\2'),
    (r'^(\s*)echo "  (\${GREEN})', r'\1echo -e "  \2'),
    (r'^(\s*)echo "  (\${YELLOW})', r'\1echo -e "  \2'),
]

# 应用替换
for pattern, replacement in patterns:
    content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

# 确保重复的日志函数被移除（之前有重复）
# 先检查是否有重复的 log_info 定义
if content.count('log_info() {') > 1:
    # 找出重复的位置
    import re
    sections = content.split('\n')
    new_sections = []
    in_log_section = False
    for i, line in enumerate(sections):
        if 'log_info() {' in line and not in_log_section:
            in_log_section = True
            new_sections.append(line)
        elif in_log_section:
            # 跳过直到看到其他内容
            if 'print_header() {' in line or i > len(sections) - 50:
                in_log_section = False
                new_sections.append(line)
            continue
        else:
            new_sections.append(line)
    content = '\n'.join(new_sections)

# 写回文件
with open('menu.sh', 'w', encoding='utf-8') as f:
    f.write(content)

print("已修复 menu.sh 中的 echo 语句")
