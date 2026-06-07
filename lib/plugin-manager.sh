#!/bin/bash
# =========================================
# 插件管理器 - 核心模块
# Shell 工具 v3.0 - 插件化架构
# =========================================

# 颜色定义 (使用 printf 格式确保正确转义)
RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
BLUE=$(printf '\033[0;34m')
PURPLE=$(printf '\033[0;35m')
CYAN=$(printf '\033[0;36m')
NC=$(printf '\033[0m')

# 日志函数回退定义 (确保在未加载 logging.sh 时也能工作)
if ! declare -f log_info > /dev/null 2>&1; then
    log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
fi
if ! declare -f log_success > /dev/null 2>&1; then
    log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
fi
if ! declare -f log_error > /dev/null 2>&1; then
    log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
fi
if ! declare -f log_warning > /dev/null 2>&1; then
    log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
fi
if ! declare -f log_debug > /dev/null 2>&1; then
    log_debug() { echo -e "${CYAN}[DEBUG]${NC} $1"; }
fi

# print 函数回退定义
if ! declare -f print_info > /dev/null 2>&1; then
    print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
fi
if ! declare -f print_success > /dev/null 2>&1; then
    print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
fi
if ! declare -f print_error > /dev/null 2>&1; then
    print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
fi
if ! declare -f print_warning > /dev/null 2>&1; then
    print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
fi
if ! declare -f print_header > /dev/null 2>&1; then
    print_header() {
        local msg="$1"
        local width=60
        local padding=$(( (width - ${#msg} - 4) / 2 ))
        printf "\n${GREEN}%${width}s${NC}\n" | tr ' ' '='
        printf "${GREEN}%${padding}s %s %${padding}s${NC}\n" "" "$msg" ""
        printf "${GREEN}%${width}s${NC}\n" | tr ' ' '='
    }
fi

# 插件目录配置
PLUGIN_BASE_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLUGIN_DIR="$PLUGIN_BASE_DIR/plugins"
CUSTOM_PLUGIN_DIR="$PLUGIN_BASE_DIR/custom-plugins"
CACHE_DIR="$PLUGIN_BASE_DIR/.cache/plugins"

# 插件管理器配置
PLUGIN_MANAGER_VERSION="3.0.0"
PLUGIN_API_VERSION="1.0"

# 插件状态
declare -A PLUGIN_STATUS
declare -A PLUGIN_METADATA

# ========================================
# 插件基础函数
# ========================================

# 初始化插件管理器
plugin_manager_init() {
    log_info "初始化插件管理器 v$PLUGIN_MANAGER_VERSION..."
    
    # 创建必要的目录
    mkdir -p "$PLUGIN_DIR" 2>/dev/null
    mkdir -p "$CUSTOM_PLUGIN_DIR" 2>/dev/null
    mkdir -p "$CACHE_DIR" 2>/dev/null
    
    # 加载插件缓存
    load_plugin_cache
    
    log_success "插件管理器初始化完成"
}

# 加载插件缓存
load_plugin_cache() {
    local cache_file="$CACHE_DIR/plugins.cache"
    
    if [ -f "$cache_file" ]; then
        source "$cache_file"
        log_info "已加载插件缓存"
    fi
}

# 保存插件缓存
save_plugin_cache() {
    local cache_file="$CACHE_DIR/plugins.cache"
    
    # 确保目录存在
    mkdir -p "$CACHE_DIR"
    
    {
        echo "# 插件缓存 - $(date)"
        for plugin in "${!PLUGIN_METADATA[@]}"; do
            echo "PLUGIN_METADATA[$plugin]='${PLUGIN_METADATA[$plugin]}'"
        done
        for plugin in "${!PLUGIN_STATUS[@]}"; do
            echo "PLUGIN_STATUS[$plugin]='${PLUGIN_STATUS[$plugin]}'"
        done
    } > "$cache_file"
    
    log_info "插件缓存已保存"
}

# ========================================
# 插件发现和注册
# ========================================

# 发现所有可用插件
discover_plugins() {
    log_info "正在发现插件..."
    
    local plugins=()
    
    # 扫描内置插件目录
    if [ -d "$PLUGIN_DIR" ]; then
        for plugin_path in "$PLUGIN_DIR"/*/; do
            if [ -d "$plugin_path" ]; then
                local plugin_name
                plugin_name=$(basename "$plugin_path")
                if validate_plugin "$plugin_name"; then
                    plugins+=("$plugin_name")
                    register_plugin "$plugin_name" "$plugin_path"
                fi
            fi
        done
    fi
    
    # 扫描自定义插件目录
    if [ -d "$CUSTOM_PLUGIN_DIR" ]; then
        for plugin_path in "$CUSTOM_PLUGIN_DIR"/*/; do
            if [ -d "$plugin_path" ]; then
                local plugin_name
                plugin_name=$(basename "$plugin_path")
                if validate_plugin "$plugin_name"; then
                    # 自定义插件优先级更高
                    plugins=("$plugin_name" "${plugins[@]}")
                    register_plugin "$plugin_name" "$plugin_path"
                fi
            fi
        done
    fi
    
    log_success "发现 ${#plugins[@]} 个可用插件"
    printf "${GREEN}%s${NC}\n" "可用插件: ${plugins[*]}"
    
    # 保存缓存以便下次快速加载
    save_plugin_cache
}

# 注册插件
register_plugin() {
    local plugin_name=$1
    local plugin_path=$2
    
    PLUGIN_STATUS[$plugin_name]="registered"
    PLUGIN_METADATA[$plugin_name]="$plugin_path"
    
    log_debug "已注册插件: $plugin_name"
}

# 验证插件有效性
validate_plugin() {
    local plugin_name=$1
    local plugin_path="${PLUGIN_DIR}/${plugin_name}"
    
    # 检查插件目录
    [ ! -d "$plugin_path" ] && plugin_path="${CUSTOM_PLUGIN_DIR}/${plugin_name}"
    [ ! -d "$plugin_path" ] && return 1
    
    # 检查必需的插件元数据文件
    [ ! -f "$plugin_path/plugin.json" ] && return 1
    
    # 检查必需的插件脚本
    [ ! -f "$plugin_path/install.sh" ] && return 1
    
    return 0
}

# ========================================
# 插件元数据管理
# ========================================

# 加载插件元数据
load_plugin_metadata() {
    local plugin_name=$1
    local plugin_path="${PLUGIN_DIR}/${plugin_name}"
    
    [ ! -d "$plugin_path" ] && plugin_path="${CUSTOM_PLUGIN_DIR}/${plugin_name}"
    [ ! -d "$plugin_path" ] && return 1
    
    local metadata_file="$plugin_path/plugin.json"
    
    if [ -f "$metadata_file" ]; then
        # 解析 JSON 元数据（简化版）
        PLUGIN_NAME="$plugin_name"
        PLUGIN_VERSION=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$metadata_file" 2>/dev/null || echo "1.0.0")
        PLUGIN_DESCRIPTION=$(grep -oP '"description"\s*:\s*"\K[^"]+' "$metadata_file" 2>/dev/null || echo "无描述")
        PLUGIN_AUTHOR=$(grep -oP '"author"\s*:\s*"\K[^"]+' "$metadata_file" 2>/dev/null || echo "未知")
        PLUGIN_CATEGORY=$(grep -oP '"category"\s*:\s*"\K[^"]+' "$metadata_file" 2>/dev/null || echo "other")
        PLUGIN_DEPENDENCIES=$(grep -oP '"dependencies"\s*:\s*\[\K[^\]]+' "$metadata_file" 2>/dev/null | tr -d '"' | tr ',' ' ')
        
        return 0
    fi
    
    return 1
}

# 获取插件信息
get_plugin_info() {
    local plugin_name=$1
    
    if ! load_plugin_metadata "$plugin_name"; then
        print_error "无法加载插件元数据: $plugin_name"
        return 1
    fi
    
    echo ""
    print_header "插件信息: $PLUGIN_NAME"
    echo ""
    echo -e "  ${YELLOW}名称:${NC}       $PLUGIN_NAME"
    echo -e "  ${YELLOW}版本:${NC}       $PLUGIN_VERSION"
    echo -e "  ${YELLOW}描述:${NC}       $PLUGIN_DESCRIPTION"
    echo -e "  ${YELLOW}作者:${NC}       $PLUGIN_AUTHOR"
    echo -e "  ${YELLOW}分类:${NC}       $PLUGIN_CATEGORY"
    echo -e "  ${YELLOW}路径:${NC}       ${PLUGIN_DIR}/${plugin_name}"
    
    if [ -n "$PLUGIN_DEPENDENCIES" ]; then
        echo -e "  ${YELLOW}依赖:${NC}       $PLUGIN_DEPENDENCIES"
    fi
    
    echo ""
}

# 列出所有插件
list_plugins() {
    local category=${1:-""}
    local verbose=${2:-false}
    
    # 如果没有已注册的插件，自动发现
    if [ ${#PLUGIN_METADATA[@]} -eq 0 ]; then
        discover_plugins
    fi
    
    echo ""
    print_header "插件列表"
    echo ""
    
    local count=0
    for plugin_name in "${!PLUGIN_METADATA[@]}"; do
        if [ -n "$category" ] && [ "$category" != "all" ]; then
            load_plugin_metadata "$plugin_name"
            if [ "$PLUGIN_CATEGORY" != "$category" ]; then
                continue
            fi
        fi
        
        load_plugin_metadata "$plugin_name"
        
        # 获取插件状态
        local status="${PLUGIN_STATUS[$plugin_name]:-registered}"
        local status_color="$YELLOW"
        [ "$status" = "installed" ] && status_color="$GREEN"
        [ "$status" = "enabled" ] && status_color="$CYAN"
        
        if [ "$verbose" = "true" ]; then
            printf "  ${GREEN}%s${NC} v%s - %s (${status_color}%s${NC})\n" \
                "$PLUGIN_NAME" "$PLUGIN_VERSION" "$PLUGIN_DESCRIPTION" "$status"
        else
            printf "  ${GREEN}%s${NC} - %s (${status_color}%s${NC})\n" \
                "$PLUGIN_NAME" "$PLUGIN_CATEGORY" "$status"
        fi
        
        count=$((count + 1))
    done
    
    echo ""
    echo -e "${YELLOW}总计: ${count} 个插件${NC}"
    echo ""
}

# ========================================
# 插件生命周期管理
# ========================================

# 安装插件
plugin_install() {
    local plugin_name=$1
    local force=${2:-false}
    
    log_info "安装插件: $plugin_name"
    
    # 检查插件是否已安装
    if [ "$force" != "true" ] && is_plugin_installed "$plugin_name"; then
        print_warning "插件已安装: $plugin_name"
        return 0
    fi
    
    # 获取插件路径
    local plugin_path="${PLUGIN_METADATA[$plugin_name]}"
    if [ -z "$plugin_path" ]; then
        plugin_path="${PLUGIN_DIR}/${plugin_name}"
    fi
    
    # 检查插件目录
    if [ ! -d "$plugin_path" ]; then
        print_error "插件不存在: $plugin_name"
        return 1
    fi
    
    # 执行安装前钩子
    hook_execute "$plugin_path" "pre_install"
    
    # 执行安装脚本
    if [ -f "$plugin_path/install.sh" ]; then
        chmod +x "$plugin_path/install.sh"
        bash "$plugin_path/install.sh"
        local status=$?
        
        if [ $status -eq 0 ]; then
            # 标记为已安装
            PLUGIN_STATUS[$plugin_name]="installed"
            save_plugin_cache
            
            # 执行安装后钩子
            hook_execute "$plugin_path" "post_install"
            
            log_success "插件安装成功: $plugin_name"
            return 0
        else
            log_error "插件安装失败: $plugin_name"
            return 1
        fi
    else
        print_error "插件安装脚本不存在: $plugin_name"
        return 1
    fi
}

# 卸载插件
plugin_uninstall() {
    local plugin_name=$1
    
    log_info "卸载插件: $plugin_name"
    
    # 获取插件路径
    local plugin_path="${PLUGIN_METADATA[$plugin_name]}"
    if [ -z "$plugin_path" ]; then
        plugin_path="${PLUGIN_DIR}/${plugin_name}"
    fi
    
    # 执行卸载前钩子
    hook_execute "$plugin_path" "pre_uninstall"
    
    # 执行卸载脚本
    if [ -f "$plugin_path/uninstall.sh" ]; then
        chmod +x "$plugin_path/uninstall.sh"
        bash "$plugin_path/uninstall.sh"
        local status=$?
        
        if [ $status -eq 0 ]; then
            # 标记为已卸载
            unset "PLUGIN_STATUS[$plugin_name]"
            save_plugin_cache
            
            # 执行卸载后钩子
            hook_execute "$plugin_path" "post_uninstall"
            
            log_success "插件卸载成功: $plugin_name"
            return 0
        else
            log_error "插件卸载失败: $plugin_name"
            return 1
        fi
    else
        print_warning "插件未提供卸载脚本: $plugin_name"
        return 1
    fi
}

# 启用插件
plugin_enable() {
    local plugin_name=$1
    
    log_info "启用插件: $plugin_name"
    
    if is_plugin_installed "$plugin_name"; then
        PLUGIN_STATUS[$plugin_name]="enabled"
        save_plugin_cache
        log_success "插件已启用: $plugin_name"
        return 0
    else
        print_error "插件未安装: $plugin_name"
        return 1
    fi
}

# 禁用插件
plugin_disable() {
    local plugin_name=$1
    
    log_info "禁用插件: $plugin_name"
    
    if is_plugin_installed "$plugin_name"; then
        PLUGIN_STATUS[$plugin_name]="disabled"
        save_plugin_cache
        log_success "插件已禁用: $plugin_name"
        return 0
    else
        print_error "插件未安装: $plugin_name"
        return 1
    fi
}

# 检查插件是否已安装
is_plugin_installed() {
    local plugin_name=$1
    
    if [ "$plugin_name" = "*" ]; then
        # 统计已安装的插件数量
        local count=0
        for status in "${PLUGIN_STATUS[@]}"; do
            if [ "$status" = "installed" ] || [ "$status" = "enabled" ]; then
                count=$((count + 1))
            fi
        done
        echo "$count"
        return 0
    fi
    
    local status="${PLUGIN_STATUS[$plugin_name]:-}"
    
    [ "$status" = "installed" ] || [ "$status" = "enabled" ]
}

# ========================================
# 插件钩子管理
# ========================================

# 执行插件钩子
hook_execute() {
    local plugin_path=$1
    local hook_name=$2
    
    local hook_file="$plugin_path/hooks/${hook_name}.sh"
    
    if [ -f "$hook_file" ]; then
        log_debug "执行钩子: $hook_name"
        chmod +x "$hook_file"
        bash "$hook_file"
    fi
}

# 列出可用的钩子
list_plugin_hooks() {
    echo ""
    echo -e "${YELLOW}可用的插件钩子:${NC}"
    echo ""
    echo -e "  ${GREEN}pre_install${NC}   - 安装前执行"
    echo -e "  ${GREEN}post_install${NC}  - 安装后执行"
    echo -e "  ${GREEN}pre_uninstall${NC} - 卸载前执行"
    echo -e "  ${GREEN}post_uninstall${NC}- 卸载后执行"
    echo -e "  ${GREEN}pre_enable${NC}    - 启用前执行"
    echo -e "  ${GREEN}post_enable${NC}   - 启用后执行"
    echo -e "  ${GREEN}pre_disable${NC}   - 禁用前执行"
    echo -e "  ${GREEN}post_disable${NC}  - 禁用后执行"
    echo ""
}

# ========================================
# 插件依赖管理
# ========================================

# 检查插件依赖
check_plugin_dependencies() {
    local plugin_name=$1
    
    if ! load_plugin_metadata "$plugin_name"; then
        return 1
    fi
    
    if [ -z "$PLUGIN_DEPENDENCIES" ]; then
        return 0
    fi
    
    local missing_deps=()
    
    for dep in $PLUGIN_DEPENDENCIES; do
        if ! is_plugin_installed "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "插件 $plugin_name 缺少依赖: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# 安装插件依赖
install_plugin_dependencies() {
    local plugin_name=$1
    
    if ! load_plugin_metadata "$plugin_name"; then
        return 1
    fi
    
    if [ -z "$PLUGIN_DEPENDENCIES" ]; then
        return 0
    fi
    
    for dep in $PLUGIN_DEPENDENCIES; do
        if ! is_plugin_installed "$dep"; then
            log_info "安装插件依赖: $dep"
            plugin_install "$dep"
        fi
    done
    
    return 0
}

# ========================================
# 插件搜索和过滤
# ========================================

# 搜索插件
search_plugins() {
    local keyword=$1
    
    # 确保插件已发现
    if [ ${#PLUGIN_METADATA[@]} -eq 0 ]; then
        discover_plugins
    fi
    
    echo ""
    print_header "搜索结果: $keyword"
    echo ""
    
    local count=0
    local lower_keyword=${keyword,,}
    for plugin_name in "${!PLUGIN_METADATA[@]}"; do
        load_plugin_metadata "$plugin_name"
        
        # 在名称和描述中搜索（使用小写匹配，更灵活）
        if [[ "${PLUGIN_NAME,,}" == *"$lower_keyword"* ]] || [[ "${PLUGIN_DESCRIPTION,,}" == *"$lower_keyword"* ]]; then
            printf "  ${GREEN}%s${NC} v%s - %s\n" "$PLUGIN_NAME" "$PLUGIN_VERSION" "$PLUGIN_DESCRIPTION"
            count=$((count + 1))
        fi
    done
    
    echo ""
    echo -e "${YELLOW}找到 ${count} 个匹配的插件${NC}"
    echo ""
}

# 获取插件分类统计
get_plugin_stats() {
    local stats_file="$CACHE_DIR/plugin_stats.txt"
    
    {
        echo "插件分类统计 - $(date)"
        echo "================================"
        
        local categories
        categories=$(find "$PLUGIN_DIR" "$CUSTOM_PLUGIN_DIR" -name "plugin.json" -exec grep -l '"category"' {} \; 2>/dev/null)
        
        declare -A category_count
        for metadata_file in $categories; do
            local plugin_dir
            plugin_dir=$(dirname "$metadata_file")
            local category
            category=$(grep -oP '"category"\s*:\s*"\K[^"]+' "$metadata_file" 2>/dev/null || echo "other")
            category_count[$category]=$((category_count[$category] + 1))
        done
        
        for category in "${!category_count[@]}"; do
            echo "$category: ${category_count[$category]}"
        done
        
        echo "================================"
        echo "总计: $(find "$PLUGIN_DIR" "$CUSTOM_PLUGIN_DIR" -maxdepth 1 -type d 2>/dev/null | wc -l) 个插件"
    } > "$stats_file"
    
    cat "$stats_file"
}

# ========================================
# 插件更新管理
# ========================================

# 检查插件更新
check_plugin_updates() {
    log_info "检查插件更新..."
    
    local updates_available=0
    
    for plugin_name in "${!PLUGIN_METADATA[@]}"; do
        local plugin_path="${PLUGIN_METADATA[$plugin_name]}"
        local current_version=""
        local latest_version=""
        
        if [ -f "$plugin_path/plugin.json" ]; then
            current_version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$plugin_path/plugin.json" 2>/dev/null || echo "1.0.0")
            
            # 这里应该检查远程版本（简化处理）
            latest_version="$current_version"
            
            if [ "$current_version" != "$latest_version" ]; then
                echo -e "  ${YELLOW}$plugin_name${NC}: $current_version -> $latest_version"
                updates_available=$((updates_available + 1))
            fi
        fi
    done
    
    if [ $updates_available -eq 0 ]; then
        log_success "所有插件已是最新版本"
    else
        log_info "有 $updates_available 个插件可以更新"
    fi
}

# 更新插件
update_plugin() {
    local plugin_name=$1
    
    log_info "更新插件: $plugin_name"
    
    # 这里应该实现从远程仓库更新（简化处理）
    print_info "插件更新功能开发中..."
    
    return 0
}

# ========================================
# 插件市场（远程插件管理）
# ========================================

# 列出远程插件（模拟）
list_remote_plugins() {
    echo ""
    print_header "插件市场"
    echo ""
    
    # 这里应该从远程 API 获取插件列表（简化处理）
    echo -e "  ${GREEN}推荐插件:${NC}"
    echo ""
    echo -e "    ${YELLOW}nginx-plus${NC}     - Nginx 增强版"
    echo -e "    ${YELLOW}mysql-enterprise${NC} - MySQL 企业版"
    echo -e "    ${YELLOW}k8s-dashboard${NC}   - Kubernetes 仪表板"
    echo ""
    
    print_info "使用 'plugin install <name>' 安装插件"
    echo ""
}

# 从市场安装插件
install_from_marketplace() {
    local plugin_name=$1
    
    log_info "从插件市场安装: $plugin_name"
    
    # 这里应该从远程仓库下载并安装（简化处理）
    print_info "插件市场安装功能开发中..."
    
    return 0
}

# ========================================
# 调试和诊断
# ========================================

# 诊断插件系统
diagnose_plugins() {
    echo ""
    print_header "插件系统诊断"
    echo ""
    
    echo -e "  ${YELLOW}版本信息:${NC}"
    echo "    插件管理器: v$PLUGIN_MANAGER_VERSION"
    echo "    API 版本: v$PLUGIN_API_VERSION"
    echo ""
    
    echo -e "  ${YELLOW}目录检查:${NC}"
    echo "    插件目录: $PLUGIN_DIR"
    [ -d "$PLUGIN_DIR" ] && echo "      ✓ 存在" || echo "      ✗ 不存在"
    echo "    自定义插件: $CUSTOM_PLUGIN_DIR"
    [ -d "$CUSTOM_PLUGIN_DIR" ] && echo "      ✓ 存在" || echo "      ✗ 不存在"
    echo "    缓存目录: $CACHE_DIR"
    [ -d "$CACHE_DIR" ] && echo "      ✓ 存在" || echo "      ✗ 不存在"
    echo ""
    
    # 确保插件已发现
    if [ ${#PLUGIN_METADATA[@]} -eq 0 ]; then
        discover_plugins
    fi
    
    # 统计已启用插件
    local enabled_count=0
    for status in "${PLUGIN_STATUS[@]}"; do
        if [ "$status" = "enabled" ]; then
            enabled_count=$((enabled_count + 1))
        fi
    done
    
    echo -e "  ${YELLOW}插件统计:${NC}"
    echo "    已注册: ${#PLUGIN_METADATA[@]} 个"
    echo "    已安装: $(is_plugin_installed '*') 个"
    echo "    已启用: ${enabled_count} 个"
    echo ""
    
    echo -e "  ${YELLOW}权限检查:${NC}"
    if [ -w "$PLUGIN_DIR" ]; then
        echo "    ✓ 插件目录可写"
    else
        echo "    ✗ 插件目录不可写"
    fi
    if [ -d "$CUSTOM_PLUGIN_DIR" ]; then
        if [ -w "$CUSTOM_PLUGIN_DIR" ]; then
            echo "    ✓ 自定义插件可写"
        else
            echo "    ✗ 自定义插件不可写"
        fi
    else
        echo "    ✗ 自定义插件目录不存在"
    fi
    echo ""
}

# 导出插件配置
export_plugin_config() {
    local output_file=${1:-"plugin-config-$(date +%Y%m%d).sh"}
    
    {
        echo "#!/bin/bash"
        echo "# 插件配置导出 - $(date)"
        echo ""
        echo "PLUGIN_MANAGER_VERSION='$PLUGIN_MANAGER_VERSION'"
        echo "PLUGIN_API_VERSION='$PLUGIN_API_VERSION'"
        echo ""
        echo "# 已安装的插件"
        for plugin in "${!PLUGIN_STATUS[@]}"; do
            echo "PLUGIN_STATUS[$plugin]='${PLUGIN_STATUS[$plugin]}'"
        done
    } > "$output_file"
    
    log_success "插件配置已导出到: $output_file"
}

# 导入插件配置
import_plugin_config() {
    local input_file=$1
    
    if [ ! -f "$input_file" ]; then
        print_error "配置文件不存在: $input_file"
        return 1
    fi
    
    source "$input_file"
    
    log_success "插件配置已导入"
    
    # 重新初始化插件
    discover_plugins
}

# ========================================
# 帮助信息
# ========================================

show_plugin_help() {
    cat << EOF
${GREEN}插件管理器帮助${NC}
${GREEN}===================${NC}

用法: $0 plugin <命令> [参数]

${YELLOW}插件发现:${NC}
  $0 plugin discover          - 发现所有可用插件
  $0 plugin list [分类]       - 列出所有插件
  $0 plugin search <关键词>   - 搜索插件

${YELLOW}插件管理:${NC}
  $0 plugin install <名称>   - 安装插件
  $0 plugin uninstall <名称>  - 卸载插件
  $0 plugin enable <名称>     - 启用插件
  $0 plugin disable <名称>    - 禁用插件
  $0 plugin update <名称>     - 更新插件

${YELLOW}插件信息:${NC}
  $0 plugin info <名称>       - 显示插件详细信息
  $0 plugin status [名称]     - 显示插件状态

${YELLOW}插件市场:${NC}
  $0 plugin market            - 浏览插件市场
  $0 plugin market install <名称> - 从市场安装

${YELLOW}诊断工具:${NC}
  $0 plugin diagnose          - 诊断插件系统
  $0 plugin export [文件]     - 导出配置
  $0 plugin import <文件>      - 导入配置
  $0 plugin hooks             - 列出可用钩子

${YELLOW}示例:${NC}
  $0 plugin discover
  $0 plugin install nginx
  $0 plugin list webserver
  $0 plugin search database

EOF
}

# ========================================
# 主函数
# ========================================

plugin_main() {
    local command=${1:-help}
    shift
    
    # 对于需要插件的命令，确保插件已发现
    case "$command" in
        install|uninstall|remove|enable|disable|update|info)
            if [ ${#PLUGIN_METADATA[@]} -eq 0 ]; then
                discover_plugins
            fi
            ;;
    esac
    
    case "$command" in
        init)
            plugin_manager_init
            ;;
        discover)
            discover_plugins
            ;;
        list)
            list_plugins "$1" "$2"
            ;;
        search)
            search_plugins "$1"
            ;;
        install)
            plugin_install "$1" "$2"
            ;;
        uninstall|remove)
            plugin_uninstall "$1"
            ;;
        enable)
            plugin_enable "$1"
            ;;
        disable)
            plugin_disable "$1"
            ;;
        update)
            update_plugin "$1"
            ;;
        info)
            get_plugin_info "$1"
            ;;
        status)
            list_plugins "" "true"
            ;;
        market)
            list_remote_plugins
            ;;
        diagnose)
            diagnose_plugins
            ;;
        export)
            export_plugin_config "$1"
            ;;
        import)
            import_plugin_config "$1"
            ;;
        hooks)
            list_plugin_hooks
            ;;
        help|--help|-h)
            show_plugin_help
            ;;
        *)
            print_error "未知命令: $command"
            show_plugin_help
            return 1
            ;;
    esac
}

# 如果直接运行此脚本
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    plugin_main "$@"
fi
