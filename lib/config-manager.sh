#!/bin/bash
# 集中配置管理系统
# 提供统一的配置加载、验证和导出功能

# 配置目录
CONFIG_DIR="/etc/shell-utils"
CONFIG_FILE="$CONFIG_DIR/config.conf"
BACKUP_DIR="$CONFIG_DIR/backups"

# 默认配置
declare -A DEFAULT_CONFIG=(
    ["LOG_LEVEL"]="INFO"
    ["LOG_DIR"]="/var/log/shell-utils"
    ["BACKUP_DIR"]="/var/backups/shell-utils"
    ["LOCK_DIR"]="/var/run/shell-utils"
    ["MAX_LOG_SIZE"]="10485760"
    ["MAX_BACKUP_AGE_DAYS"]="30"
    ["ENABLE_EMAIL_ALERT"]="false"
    ["ENABLE_SLACK_ALERT"]="false"
    ["ENABLE_WEBHOOK"]="false"
    ["DEFAULT_TIMEOUT"]="300"
    ["MAX_PARALLEL_JOBS"]="4"
)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 初始化配置目录
init_config_dir() {
    mkdir -p "$CONFIG_DIR" 2>/dev/null
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    mkdir -p "${DEFAULT_CONFIG[LOG_DIR]}" 2>/dev/null
    mkdir -p "${DEFAULT_CONFIG[BACKUP_DIR]}" 2>/dev/null
    mkdir -p "${DEFAULT_CONFIG[LOCK_DIR]}" 2>/dev/null
}

# 加载配置
load_config() {
    local config_file="${1:-$CONFIG_FILE}"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${YELLOW}配置文件不存在，创建默认配置...${NC}"
        create_default_config
        return 1
    fi
    
    # 读取配置
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        
        # 去除首尾空格
        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # 导出变量
        export "CONFIG_$key=$value"
    done < "$config_file"
    
    # 应用默认值
    for key in "${!DEFAULT_CONFIG[@]}"; do
        local config_var="CONFIG_$key"
        if [ -z "${!config_var}" ]; then
            export "$config_var=${DEFAULT_CONFIG[$key]}"
        fi
    done
    
    return 0
}

# 创建默认配置
create_default_config() {
    init_config_dir
    
    cat > "$CONFIG_FILE" <<EOF
# Shell Utils 集中配置文件
# 由配置管理系统自动生成

# 日志配置
LOG_LEVEL=INFO
LOG_DIR=/var/log/shell-utils
MAX_LOG_SIZE=10485760

# 备份配置
BACKUP_DIR=/var/backups/shell-utils
MAX_BACKUP_AGE_DAYS=30

# 锁文件配置
LOCK_DIR=/var/run/shell-utils

# 告警配置
ENABLE_EMAIL_ALERT=false
ENABLE_SLACK_ALERT=false
ENABLE_WEBHOOK=false

# 执行配置
DEFAULT_TIMEOUT=300
MAX_PARALLEL_JOBS=4

# 高级配置
DEBUG_MODE=false
STRICT_MODE=false
EOF
    
    echo -e "${GREEN}✓ 默认配置文件已创建: $CONFIG_FILE${NC}"
}

# 保存配置
save_config() {
    local config_file="${1:-$CONFIG_FILE}"
    
    init_config_dir
    
    cat > "$config_file" <<EOF
# Shell Utils 集中配置文件
# 手动编辑时请注意格式

# 日志配置
LOG_LEVEL=${CONFIG_LOG_LEVEL:-INFO}
LOG_DIR=${CONFIG_LOG_DIR:-/var/log/shell-utils}
MAX_LOG_SIZE=${CONFIG_MAX_LOG_SIZE:-10485760}

# 备份配置
BACKUP_DIR=${CONFIG_BACKUP_DIR:-/var/backups/shell-utils}
MAX_BACKUP_AGE_DAYS=${CONFIG_MAX_BACKUP_AGE_DAYS:-30}

# 锁文件配置
LOCK_DIR=${CONFIG_LOCK_DIR:-/var/run/shell-utils}

# 告警配置
ENABLE_EMAIL_ALERT=${CONFIG_ENABLE_EMAIL_ALERT:-false}
ENABLE_SLACK_ALERT=${CONFIG_ENABLE_SLACK_ALERT:-false}
ENABLE_WEBHOOK=${CONFIG_ENABLE_WEBHOOK:-false}

# 执行配置
DEFAULT_TIMEOUT=${CONFIG_DEFAULT_TIMEOUT:-300}
MAX_PARALLEL_JOBS=${CONFIG_MAX_PARALLEL_JOBS:-4}

# 高级配置
DEBUG_MODE=${CONFIG_DEBUG_MODE:-false}
STRICT_MODE=${CONFIG_STRICT_MODE:-false}
EOF
    
    echo -e "${GREEN}✓ 配置已保存: $config_file${NC}"
}

# 验证配置
validate_config() {
    local errors=0
    
    echo -e "${BLUE}验证配置文件...${NC}"
    echo ""
    
    # 验证日志级别
    if [[ ! "$CONFIG_LOG_LEVEL" =~ ^(DEBUG|INFO|WARN|ERROR)$ ]]; then
        echo -e "${RED}✗ LOG_LEVEL 无效: $CONFIG_LOG_LEVEL${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ LOG_LEVEL: $CONFIG_LOG_LEVEL${NC}"
    fi
    
    # 验证目录是否存在
    for dir_var in LOG_DIR BACKUP_DIR LOCK_DIR; do
        local dir_var_name="CONFIG_$dir_var"
        local dir="${!dir_var_name}"
        
        if [ ! -d "$dir" ]; then
            echo -e "${YELLOW}⚠ $dir_var 目录不存在: $dir${NC}"
            echo -e "  ${BLUE}创建目录...${NC}"
            mkdir -p "$dir" 2>/dev/null
            if [ -d "$dir" ]; then
                echo -e "${GREEN}✓ 已创建: $dir${NC}"
            else
                echo -e "${RED}✗ 无法创建目录: $dir${NC}"
                errors=$((errors + 1))
            fi
        else
            echo -e "${GREEN}✓ $dir_var: $dir${NC}"
        fi
    done
    
    # 验证数值配置
    if [ "$CONFIG_MAX_LOG_SIZE" -lt 1024 ] 2>/dev/null; then
        echo -e "${RED}✗ MAX_LOG_SIZE 太小${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ MAX_LOG_SIZE: $CONFIG_MAX_LOG_SIZE${NC}"
    fi
    
    if [ "$CONFIG_MAX_BACKUP_AGE_DAYS" -lt 1 ] 2>/dev/null; then
        echo -e "${RED}✗ MAX_BACKUP_AGE_DAYS 必须大于0${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ MAX_BACKUP_AGE_DAYS: $CONFIG_MAX_BACKUP_AGE_DAYS${NC}"
    fi
    
    if [ "$CONFIG_DEFAULT_TIMEOUT" -lt 10 ] 2>/dev/null; then
        echo -e "${RED}✗ DEFAULT_TIMEOUT 太小${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ DEFAULT_TIMEOUT: $CONFIG_DEFAULT_TIMEOUT${NC}"
    fi
    
    if [ "$CONFIG_MAX_PARALLEL_JOBS" -lt 1 ] 2>/dev/null; then
        echo -e "${RED}✗ MAX_PARALLEL_JOBS 必须大于0${NC}"
        errors=$((errors + 1))
    else
        echo -e "${GREEN}✓ MAX_PARALLEL_JOBS: $CONFIG_MAX_PARALLEL_JOBS${NC}"
    fi
    
    # 验证布尔配置
    for bool_var in ENABLE_EMAIL_ALERT ENABLE_SLACK_ALERT ENABLE_WEBHOOK DEBUG_MODE STRICT_MODE; do
        local config_var="CONFIG_$bool_var"
        local value="${!config_var}"
        
        if [[ ! "$value" =~ ^(true|false)$ ]]; then
            echo -e "${RED}✗ $bool_var 无效: $value${NC}"
            errors=$((errors + 1))
        else
            echo -e "${GREEN}✓ $bool_var: $value${NC}"
        fi
    done
    
    echo ""
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✓ 配置验证通过！${NC}"
        return 0
    else
        echo -e "${RED}✗ 配置验证失败，发现 $errors 个错误${NC}"
        return 1
    fi
}

# 备份配置
backup_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}✗ 配置文件不存在${NC}"
        return 1
    fi
    
    init_config_dir
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/config_$timestamp.conf"
    
    cp "$CONFIG_FILE" "$backup_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 配置已备份: $backup_file${NC}"
        
        # 清理旧备份
        cleanup_old_backups
        
        return 0
    else
        echo -e "${RED}✗ 备份失败${NC}"
        return 1
    fi
}

# 清理旧备份
cleanup_old_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then
        return 0
    fi
    
    local max_age="${CONFIG_MAX_BACKUP_AGE_DAYS:-30}"
    local count_before=$(find "$BACKUP_DIR" -name "config_*.conf" | wc -l)
    
    find "$BACKUP_DIR" -name "config_*.conf" -mtime "+$max_age" -delete 2>/dev/null
    
    local count_after=$(find "$BACKUP_DIR" -name "config_*.conf" | wc -l)
    local deleted=$((count_before - count_after))
    
    if [ $deleted -gt 0 ]; then
        echo -e "${YELLOW}已清理 $deleted 个旧备份文件${NC}"
    fi
}

# 列出备份
list_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}备份目录不存在${NC}"
        return 1
    fi
    
    local backups=($(find "$BACKUP_DIR" -name "config_*.conf" -type f | sort -r))
    
    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${YELLOW}没有配置备份${NC}"
        return 1
    fi
    
    echo -e "${BLUE}可用配置备份:${NC}"
    echo ""
    
    for i in "${!backups[@]}"; do
        local backup="${backups[$i]}"
        local size=$(du -h "$backup" | cut -f1)
        local date=$(date -r "$backup" '+%Y-%m-%d %H:%M:%S')
        
        echo -e "  ${GREEN}$((i+1))${NC}. $(basename "$backup")"
        echo -e "      大小: $size | 日期: $date"
        echo ""
    done
}

# 恢复配置
restore_config() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        echo -e "${YELLOW}请指定要恢复的备份文件${NC}"
        echo ""
        list_backups
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}✗ 备份文件不存在: $backup_file${NC}"
        return 1
    fi
    
    # 备份当前配置
    backup_config
    
    # 恢复配置
    cp "$backup_file" "$CONFIG_FILE"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 配置已恢复: $CONFIG_FILE${NC}"
        echo -e "${BLUE}重新加载配置...${NC}"
        load_config
        return 0
    else
        echo -e "${RED}✗ 恢复失败${NC}"
        return 1
    fi
}

# 导出配置
export_config() {
    local output_file="${1:-$CONFIG_FILE.exports.json}"
    
    init_config_dir
    
    cat > "$output_file" <<EOF
{
  "config_version": "1.0",
  "export_date": "$(date -Iseconds)",
  "settings": {
    "log_level": "${CONFIG_LOG_LEVEL:-INFO}",
    "log_dir": "${CONFIG_LOG_DIR:-/var/log/shell-utils}",
    "max_log_size": ${CONFIG_MAX_LOG_SIZE:-10485760},
    "backup_dir": "${CONFIG_BACKUP_DIR:-/var/backups/shell-utils}",
    "max_backup_age_days": ${CONFIG_MAX_BACKUP_AGE_DAYS:-30},
    "lock_dir": "${CONFIG_LOCK_DIR:-/var/run/shell-utils}",
    "enable_email_alert": ${CONFIG_ENABLE_EMAIL_ALERT:-false},
    "enable_slack_alert": ${CONFIG_ENABLE_SLACK_ALERT:-false},
    "enable_webhook": ${CONFIG_ENABLE_WEBHOOK:-false},
    "default_timeout": ${CONFIG_DEFAULT_TIMEOUT:-300},
    "max_parallel_jobs": ${CONFIG_MAX_PARALLEL_JOBS:-4},
    "debug_mode": ${CONFIG_DEBUG_MODE:-false},
    "strict_mode": ${CONFIG_STRICT_MODE:-false}
  }
}
EOF
    
    echo -e "${GREEN}✓ 配置已导出: $output_file${NC}"
}

# 显示配置
show_config() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  当前配置${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${YELLOW}日志配置:${NC}"
    echo "  LOG_LEVEL: ${CONFIG_LOG_LEVEL:-INFO}"
    echo "  LOG_DIR: ${CONFIG_LOG_DIR:-/var/log/shell-utils}"
    echo "  MAX_LOG_SIZE: ${CONFIG_MAX_LOG_SIZE:-10485760} bytes"
    echo ""
    echo -e "${YELLOW}备份配置:${NC}"
    echo "  BACKUP_DIR: ${CONFIG_BACKUP_DIR:-/var/backups/shell-utils}"
    echo "  MAX_BACKUP_AGE_DAYS: ${CONFIG_MAX_BACKUP_AGE_DAYS:-30} days"
    echo ""
    echo -e "${YELLOW}告警配置:${NC}"
    echo "  ENABLE_EMAIL_ALERT: ${CONFIG_ENABLE_EMAIL_ALERT:-false}"
    echo "  ENABLE_SLACK_ALERT: ${CONFIG_ENABLE_SLACK_ALERT:-false}"
    echo "  ENABLE_WEBHOOK: ${CONFIG_ENABLE_WEBHOOK:-false}"
    echo ""
    echo -e "${YELLOW}执行配置:${NC}"
    echo "  DEFAULT_TIMEOUT: ${CONFIG_DEFAULT_TIMEOUT:-300} seconds"
    echo "  MAX_PARALLEL_JOBS: ${CONFIG_MAX_PARALLEL_JOBS:-4}"
    echo ""
    echo -e "${YELLOW}高级配置:${NC}"
    echo "  DEBUG_MODE: ${CONFIG_DEBUG_MODE:-false}"
    echo "  STRICT_MODE: ${CONFIG_STRICT_MODE:-false}"
    echo ""
}

# 主函数
main() {
    local action="${1:-show}"
    
    init_config_dir
    load_config
    
    case "$action" in
        show)
            show_config
            ;;
        validate)
            validate_config
            ;;
        backup)
            backup_config
            ;;
        restore)
            restore_config "$2"
            ;;
        export)
            export_config "$2"
            ;;
        save)
            save_config
            ;;
        list-backups)
            list_backups
            ;;
        help|*)
            echo "用法: $0 {show|validate|backup|restore|export|save|list-backups|help}"
            echo ""
            echo "命令:"
            echo "  show          - 显示当前配置"
            echo "  validate      - 验证配置有效性"
            echo "  backup        - 备份当前配置"
            echo "  restore FILE  - 从备份恢复配置"
            echo "  export [FILE] - 导出配置为 JSON 格式"
            echo "  save          - 保存当前配置"
            echo "  list-backups  - 列出可用备份"
            echo "  help          - 显示帮助信息"
            ;;
    esac
}

# 如果直接运行此脚本
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
