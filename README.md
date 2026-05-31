# Shell 工具函数集合

一个包含常用 Shell 脚本工具函数的项目，提供了日志、文件操作、系统信息、网络检查等功能。

## 功能介绍

### 1. 日志函数
- `log_info` - 输出信息日志（蓝色）
- `log_success` - 输出成功日志（绿色）
- `log_warning` - 输出警告日志（黄色）
- `log_error` - 输出错误日志（红色）

### 2. 文件操作函数
- `create_backup <file>` - 创建文件备份（带时间戳）

### 3. 系统信息函数
- `show_system_info` - 显示系统信息

### 4. 网络函数
- `check_internet` - 检查网络连接

### 5. 进度条函数
- `show_progress <current> <total>` - 显示进度条

### 6. 目录统计函数
- `count_files [dir]` - 统计目录中的文件和目录数量

### 7. 字符串处理函数
- `to_uppercase <string>` - 字符串转大写
- `to_lowercase <string>` - 字符串转小写
- `trim <string>` - 去除字符串首尾空格

### 8. 时间函数
- `wait_seconds <seconds>` - 等待指定秒数，带进度条

### 9. 命令检查函数
- `command_exists <command>` - 检查命令是否已安装

### 10. 压缩解压函数
- `compress_dir <dir> [output]` - 压缩目录为 tar.gz
- `extract_file <file>` - 解压文件（支持 tar.gz, zip, tar.bz2）

### 11. 磁盘使用检查
- `check_disk_usage [threshold]` - 检查磁盘使用情况

### 12. 大文件查找
- `find_large_files [dir] [size]` - 查找指定大小以上的文件

## 使用方法

### 引入脚本
```bash
source utils.sh
# 或
. utils.sh
```

### 运行示例
```bash
./example.sh
```

## 文件说明
- `utils.sh` - 工具函数集合
- `example.sh` - 使用示例
- `README.md` - 项目说明文档

## 许可证
MIT
