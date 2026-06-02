#!/bin/bash

# =========================================
# 脚本仓库升级工具
# 支持从 GitHub 自动更新脚本
# =========================================

# 设置错误处理，但不使用 set -e，因为我们需要更好的控制
set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_URL="https://github.com/fireworkor/shell-utils.git"
REPO_BRANCH="master"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

check_dependencies() {
    log_info "检查依赖..."
    
    local missing_deps=()
    
    if ! command -v git &>/dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v curl &>/dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v tar &>/dev/null; then
        missing_deps+=("tar")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        log_info "请安装: ${missing_deps[*]}"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

get_current_version() {
    # 优先从 .version 文件获取
    if [ -f "$SCRIPT_DIR/.version" ]; then
        cat "$SCRIPT_DIR/.version"
    # 其次从 git 获取
    elif [ -d "$SCRIPT_DIR/.git" ]; then
        git -C "$SCRIPT_DIR" describe --tags --always 2>/dev/null || \
        git -C "$SCRIPT_DIR" log --oneline -1 2>/dev/null | awk '{print $1}'
    else
        echo "unknown"
    fi
}

get_latest_version() {
    # 优先从远程 tags 获取
    local latest_tag
    latest_tag=$(curl -s --connect-timeout 10 https://api.github.com/repos/fireworkor/shell-utils/tags 2>/dev/null | grep '"name"' | head -1 | awk -F'"' '{print $4}')
    
    if [ -n "$latest_tag" ]; then
        echo "$latest_tag"
        return
    fi
    
    # 如果没有 tag，从远程分支最新 commit 获取
    local latest_commit
    latest_commit=$(curl -s --connect-timeout 10 "https://api.github.com/repos/fireworkor/shell-utils/commits/${REPO_BRANCH}" 2>/dev/null | grep '"sha"' | head -1 | awk -F'"' '{print $4}')
    
    echo "${latest_commit:-unknown}"
}

check_for_updates() {
    log_info "检查更新..."
    
    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)
    
    log_info "当前版本: $current_version"
    log_info "最新版本: $latest_version"
    
    if [ "$latest_version" = "unknown" ]; then
        log_warn "无法获取最新版本信息"
        return 1
    fi
    
    if [ "$current_version" = "$latest_version" ]; then
        log_success "当前已是最新版本"
        return 0
    fi
    
    log_warn "发现新版本: $latest_version"
    return 2
}

backup_current() {
    local backup_dir="$SCRIPT_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    
    log_info "备份当前脚本到: $backup_dir"
    
    mkdir -p "$backup_dir"
    
    cp -r "$SCRIPT_DIR"/* "$backup_dir/" 2>/dev/null || true
    rm -rf "$backup_dir/.git" 2>/dev/null || true
    
    if [ -d "$backup_dir" ]; then
        log_success "备份完成"
        echo "$backup_dir"
    else
        log_error "备份失败"
        return 1
    fi
}

download_update() {
    log_info "下载更新..."
    
    local tmp_dir=$(mktemp -d)
    
    git clone --depth=1 --branch "$REPO_BRANCH" "$REPO_URL" "$tmp_dir/shell-utils"
    
    if [ -d "$tmp_dir/shell-utils" ]; then
        log_success "下载完成"
        echo "$tmp_dir/shell-utils"
    else
        log_error "下载失败"
        return 1
    fi
}

apply_update() {
    local source_dir=$1
    
    log_info "应用更新..."
    
    # 复制所有文件，保留配置文件
    rsync -av --exclude='config/' --exclude='.git/' --exclude='backup_*' \
          "$source_dir/" "$SCRIPT_DIR/"
    
    # 更新版本文件
    if [ -f "$source_dir/.version" ]; then
        cp "$source_dir/.version" "$SCRIPT_DIR/.version"
    fi
    
    # 更新权限
    find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;
    
    log_success "更新应用完成"
}

rollback_update() {
    local backup_dir=$1
    
    log_info "回滚到备份: $backup_dir"
    
    if [ ! -d "$backup_dir" ]; then
        log_error "备份目录不存在"
        return 1
    fi
    
    rsync -av "$backup_dir/" "$SCRIPT_DIR/"
    
    log_success "回滚完成"
}

show_update_history() {
    log_info "更新历史:"
    
    if [ -d "$SCRIPT_DIR/.git" ]; then
        git log --oneline -10
    else
        log_info "未使用 git 管理"
    fi
}

main() {
    local action="${1:-check}"
    
    case "$action" in
        check)
            check_dependencies
            check_for_updates
            exit $?
            ;;
        
        update)
            check_dependencies
            
            check_for_updates
            local status=$?
            
            if [ $status -eq 0 ]; then
                exit 0
            fi
            
            if [ $status -eq 1 ]; then
                exit 1
            fi
            
            read -p "是否继续更新? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                log_info "取消更新"
                exit 0
            fi
            
            local backup_dir=$(backup_current)
            local source_dir=$(download_update)
            
            if [ -z "$source_dir" ]; then
                log_error "下载失败，回滚..."
                rollback_update "$backup_dir"
                exit 1
            fi
            
            apply_update "$source_dir"
            
            log_success "更新完成！"
            log_info "新版本功能已生效"
            ;;
        
        force-update)
            check_dependencies
            
            log_warn "强制更新，将覆盖所有修改！"
            read -p "确认强制更新? (yes/no): " confirm
            if [ "$confirm" != "yes" ]; then
                log_info "取消更新"
                exit 0
            fi
            
            backup_current
            local source_dir=$(download_update)
            
            if [ -n "$source_dir" ]; then
                apply_update "$source_dir"
                log_success "强制更新完成！"
            fi
            ;;
        
        rollback)
            local backup_dir=$(ls -dt "$SCRIPT_DIR/backup_"* 2>/dev/null | head -1)
            
            if [ -z "$backup_dir" ]; then
                log_error "没有找到备份目录"
                exit 1
            fi
            
            log_info "找到最近备份: $backup_dir"
            rollback_update "$backup_dir"
            ;;
        
        history)
            show_update_history
            ;;
        
        version)
            local current=$(get_current_version)
            local latest=$(get_latest_version)
            echo "当前版本: $current"
            echo "最新版本: $latest"
            ;;
        
        *)
            echo "用法: $0 [check|update|force-update|rollback|history|version]"
            echo ""
            echo "选项:"
            echo "  check         - 检查更新"
            echo "  update        - 执行更新"
            echo "  force-update  - 强制更新（覆盖所有修改）"
            echo "  rollback      - 回滚到最近备份"
            echo "  history       - 显示更新历史"
            echo "  version       - 显示版本信息"
            exit 1
            ;;
    esac
}

main "$@"
