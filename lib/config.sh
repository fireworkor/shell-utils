#!/bin/bash
# 配置管理

CONF_FILE="$SCRIPT_DIR/config/versions.conf"

load_config() {
    if [ -f "$CONF_FILE" ]; then
        source "$CONF_FILE"
    fi
}

get_config() {
    local key=$1
    grep "^$key=" "$CONF_FILE" 2>/dev/null | cut -d'=' -f2
}

set_config() {
    local key=$1
    local value=$2
    mkdir -p "$(dirname "$CONF_FILE")"
    if grep -q "^$key=" "$CONF_FILE" 2>/dev/null; then
        sed -i "s/^$key=.*/$key=$value/" "$CONF_FILE"
    else
        echo "$key=$value" >> "$CONF_FILE"
    fi
}

list_config() {
    if [ -f "$CONF_FILE" ]; then
        cat "$CONF_FILE"
    else
        echo "配置文件不存在"
    fi
}
