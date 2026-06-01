#!/bin/bash

# =========================================
# 配置管理
# =========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/versions.conf"

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    else
        return 1
    fi
}

get_config() {
    local key=$1
    local default=${2:-""}
    
    if load_config; then
        echo "${!key:-$default}"
    else
        echo "$default"
    fi
}

set_config() {
    local key=$1
    local value=$2
    
    if [ ! -f "$CONFIG_FILE" ]; then
        touch "$CONFIG_FILE"
    fi
    
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$CONFIG_FILE"
    fi
}

list_config() {
    if load_config; then
        echo -e "${YELLOW}当前配置：${NC}"
        echo ""
        grep -E "^[A-Z_]+=" "$CONFIG_FILE" | while read line; do
            key=$(echo "$line" | cut -d'=' -f1)
            value=$(echo "$line" | cut -d'=' -f2-)
            echo -e "  ${GREEN}$key${NC} = $value"
        done
    else
        echo -e "${RED}配置文件不存在${NC}"
    fi
}
