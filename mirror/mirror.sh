#!/bin/bash
# 描述：Linux 换源工具 - 支持 CentOS/Ubuntu 更换国内镜像源

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
fi

if [ -f "$SCRIPT_DIR/../lib/logging.sh" ]; then
    source "$SCRIPT_DIR/../lib/logging.sh"
fi

MIRRORS=(
    "aliyun:阿里云"
    "tuna:清华大学"
    "163:网易"
    "ustc:中国科技大学"
    "huawei:华为"
)

show_mirrors() {
    echo -e "${YELLOW}可用镜像源：${NC}"
    echo ""
    for i in "${!MIRRORS[@]}"; do
        key="${MIRRORS[$i]%%:*}"
        desc="${MIRRORS[$i]##*:}"
        echo -e "  ${GREEN}$key${NC} - $desc"
    done
    echo ""
}

backup_source() {
    local backup_dir="/var/backups/mirror"
    mkdir -p "$backup_dir"
    
    case $OS in
        centos)
            if [ -f /etc/yum.repos.d/CentOS-Base.repo ]; then
                cp /etc/yum.repos.d/CentOS-Base.repo "$backup_dir/CentOS-Base.repo.backup.$(date +%Y%m%d%H%M%S)"
                print_info "已备份 CentOS-Base.repo"
            fi
            ;;
        ubuntu|debian)
            if [ -f /etc/apt/sources.list ]; then
                cp /etc/apt/sources.list "$backup_dir/sources.list.backup.$(date +%Y%m%d%H%M%S)"
                print_info "已备份 sources.list"
            fi
            ;;
    esac
}

set_centos_mirror() {
    local mirror=$1
    
    print_header "设置 CentOS $VER 镜像源 - $mirror"
    
    backup_source
    
    case $mirror in
        aliyun)
            cat > /etc/yum.repos.d/CentOS-Base.repo << 'EOF'
[base]
name=CentOS-$releasever - Base - mirrors.aliyun.com
baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-$releasever

[updates]
name=CentOS-$releasever - Updates - mirrors.aliyun.com
baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-$releasever

[extras]
name=CentOS-$releasever - Extras - mirrors.aliyun.com
baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-$releasever

[centosplus]
name=CentOS-$releasever - Plus - mirrors.aliyun.com
baseurl=http://mirrors.aliyun.com/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-$releasever
EOF
            ;;
        tuna)
            cat > /etc/yum.repos.d/CentOS-Base.repo << 'EOF'
[base]
name=CentOS-$releasever - Base - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos/RPM-GPG-KEY-CentOS-$releasever

[updates]
name=CentOS-$releasever - Updates - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos/RPM-GPG-KEY-CentOS-$releasever

[extras]
name=CentOS-$releasever - Extras - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos/RPM-GPG-KEY-CentOS-$releasever

[centosplus]
name=CentOS-$releasever - Plus - mirrors.tuna.tsinghua.edu.cn
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/centos/RPM-GPG-KEY-CentOS-$releasever
EOF
            ;;
        163)
            cat > /etc/yum.repos.d/CentOS-Base.repo << 'EOF'
[base]
name=CentOS-$releasever - Base - 163.com
baseurl=http://mirrors.163.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.163.com/centos/RPM-GPG-KEY-CentOS-$releasever

[updates]
name=CentOS-$releasever - Updates - 163.com
baseurl=http://mirrors.163.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.163.com/centos/RPM-GPG-KEY-CentOS-$releasever

[extras]
name=CentOS-$releasever - Extras - 163.com
baseurl=http://mirrors.163.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.163.com/centos/RPM-GPG-KEY-CentOS-$releasever

[centosplus]
name=CentOS-$releasever - Plus - 163.com
baseurl=http://mirrors.163.com/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.163.com/centos/RPM-GPG-KEY-CentOS-$releasever
EOF
            ;;
        ustc)
            cat > /etc/yum.repos.d/CentOS-Base.repo << 'EOF'
[base]
name=CentOS-$releasever - Base - mirrors.ustc.edu.cn
baseurl=https://mirrors.ustc.edu.cn/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-$releasever

[updates]
name=CentOS-$releasever - Updates - mirrors.ustc.edu.cn
baseurl=https://mirrors.ustc.edu.cn/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-$releasever

[extras]
name=CentOS-$releasever - Extras - mirrors.ustc.edu.cn
baseurl=https://mirrors.ustc.edu.cn/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=https://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-$releasever

[centosplus]
name=CentOS-$releasever - Plus - mirrors.ustc.edu.cn
baseurl=https://mirrors.ustc.edu.cn/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://mirrors.ustc.edu.cn/centos/RPM-GPG-KEY-CentOS-$releasever
EOF
            ;;
        huawei)
            cat > /etc/yum.repos.d/CentOS-Base.repo << 'EOF'
[base]
name=CentOS-$releasever - Base - repo.huaweicloud.com
baseurl=https://repo.huaweicloud.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=https://repo.huaweicloud.com/centos/RPM-GPG-KEY-CentOS-$releasever

[updates]
name=CentOS-$releasever - Updates - repo.huaweicloud.com
baseurl=https://repo.huaweicloud.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=https://repo.huaweicloud.com/centos/RPM-GPG-KEY-CentOS-$releasever

[extras]
name=CentOS-$releasever - Extras - repo.huaweicloud.com
baseurl=https://repo.huaweicloud.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=https://repo.huaweicloud.com/centos/RPM-GPG-KEY-CentOS-$releasever

[centosplus]
name=CentOS-$releasever - Plus - repo.huaweicloud.com
baseurl=https://repo.huaweicloud.com/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://repo.huaweicloud.com/centos/RPM-GPG-KEY-CentOS-$releasever
EOF
            ;;
    esac
    
    if [ "$VER" = "8" ]; then
        dnf makecache
    else
        yum makecache
    fi
    
    print_success "CentOS 镜像源已更换为 $mirror"
}

set_ubuntu_mirror() {
    local mirror=$1
    local codename=$(lsb_release -cs)
    
    print_header "设置 Ubuntu $codename 镜像源 - $mirror"
    
    backup_source
    
    case $mirror in
        aliyun)
            cat > /etc/apt/sources.list << EOF
deb http://mirrors.aliyun.com/ubuntu/ $codename main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $codename main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ $codename-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $codename-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ $codename-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $codename-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ $codename-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ $codename-backports main restricted universe multiverse
EOF
            ;;
        tuna)
            cat > /etc/apt/sources.list << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename main restricted universe multiverse

deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-security main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-security main restricted universe multiverse

deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-updates main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-updates main restricted universe multiverse

deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-backports main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $codename-backports main restricted universe multiverse
EOF
            ;;
        163)
            cat > /etc/apt/sources.list << EOF
deb http://mirrors.163.com/ubuntu/ $codename main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ $codename main restricted universe multiverse

deb http://mirrors.163.com/ubuntu/ $codename-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ $codename-security main restricted universe multiverse

deb http://mirrors.163.com/ubuntu/ $codename-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ $codename-updates main restricted universe multiverse

deb http://mirrors.163.com/ubuntu/ $codename-backports main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ $codename-backports main restricted universe multiverse
EOF
            ;;
        ustc)
            cat > /etc/apt/sources.list << EOF
deb https://mirrors.ustc.edu.cn/ubuntu/ $codename main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ $codename main restricted universe multiverse

deb https://mirrors.ustc.edu.cn/ubuntu/ $codename-security main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ $codename-security main restricted universe multiverse

deb https://mirrors.ustc.edu.cn/ubuntu/ $codename-updates main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ $codename-updates main restricted universe multiverse

deb https://mirrors.ustc.edu.cn/ubuntu/ $codename-backports main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ $codename-backports main restricted universe multiverse
EOF
            ;;
        huawei)
            cat > /etc/apt/sources.list << EOF
deb https://repo.huaweicloud.com/ubuntu/ $codename main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ $codename main restricted universe multiverse

deb https://repo.huaweicloud.com/ubuntu/ $codename-security main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ $codename-security main restricted universe multiverse

deb https://repo.huaweicloud.com/ubuntu/ $codename-updates main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ $codename-updates main restricted universe multiverse

deb https://repo.huaweicloud.com/ubuntu/ $codename-backports main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ $codename-backports main restricted universe multiverse
EOF
            ;;
    esac
    
    apt update
    
    print_success "Ubuntu 镜像源已更换为 $mirror"
}

set_debian_mirror() {
    local mirror=$1
    local codename=$(lsb_release -cs)
    
    print_header "设置 Debian $codename 镜像源 - $mirror"
    
    backup_source
    
    case $mirror in
        aliyun)
            cat > /etc/apt/sources.list << EOF
deb http://mirrors.aliyun.com/debian/ $codename main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ $codename main non-free contrib

deb http://mirrors.aliyun.com/debian-security/ $codename-security main
deb-src http://mirrors.aliyun.com/debian-security/ $codename-security main

deb http://mirrors.aliyun.com/debian/ $codename-updates main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ $codename-updates main non-free contrib
EOF
            ;;
        tuna)
            cat > /etc/apt/sources.list << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename main non-free contrib
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename main non-free contrib

deb https://mirrors.tuna.tsinghua.edu.cn/debian-security/ $codename-security main
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security/ $codename-security main

deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename-updates main non-free contrib
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ $codename-updates main non-free contrib
EOF
            ;;
        ustc)
            cat > /etc/apt/sources.list << EOF
deb https://mirrors.ustc.edu.cn/debian/ $codename main non-free contrib
deb-src https://mirrors.ustc.edu.cn/debian/ $codename main non-free contrib

deb https://mirrors.ustc.edu.cn/debian-security/ $codename-security main
deb-src https://mirrors.ustc.edu.cn/debian-security/ $codename-security main

deb https://mirrors.ustc.edu.cn/debian/ $codename-updates main non-free contrib
deb-src https://mirrors.ustc.edu.cn/debian/ $codename-updates main non-free contrib
EOF
            ;;
        huawei)
            cat > /etc/apt/sources.list << EOF
deb https://repo.huaweicloud.com/debian/ $codename main non-free contrib
deb-src https://repo.huaweicloud.com/debian/ $codename main non-free contrib

deb https://repo.huaweicloud.com/debian-security/ $codename-security main
deb-src https://repo.huaweicloud.com/debian-security/ $codename-security main

deb https://repo.huaweicloud.com/debian/ $codename-updates main non-free contrib
deb-src https://repo.huaweicloud.com/debian/ $codename-updates main non-free contrib
EOF
            ;;
    esac
    
    apt update
    
    print_success "Debian 镜像源已更换为 $mirror"
}

set_mirror() {
    local mirror=$1
    
    if [ -z "$mirror" ]; then
        print_error "请指定镜像源"
        show_mirrors
        exit 1
    fi
    
    check_root
    check_os
    
    case $OS in
        centos)
            set_centos_mirror "$mirror"
            ;;
        ubuntu)
            set_ubuntu_mirror "$mirror"
            ;;
        debian)
            set_debian_mirror "$mirror"
            ;;
        *)
            print_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac
}

show_current_mirror() {
    print_header "当前镜像源"
    
    case $OS in
        centos)
            echo -e "${YELLOW}CentOS 源文件:${NC}"
            grep -E '^baseurl|^name' /etc/yum.repos.d/CentOS-Base.repo | head -5
            ;;
        ubuntu|debian)
            echo -e "${YELLOW}当前源:${NC}"
            head -3 /etc/apt/sources.list
            ;;
    esac
}

main() {
    local command=$1
    shift
    
    case $command in
        list)
            show_mirrors
            ;;
        current)
            show_current_mirror
            ;;
        set)
            set_mirror "$@"
            ;;
        *)
            if [ -z "$command" ]; then
                show_mirrors
                echo "使用方法:"
                echo "  $0 list         - 列出可用镜像源"
                echo "  $0 current      - 查看当前镜像源"
                echo "  $0 set <mirror> - 设置镜像源"
                echo ""
                echo "示例:"
                echo "  $0 set aliyun"
                echo "  $0 set tuna"
            else
                set_mirror "$command"
            fi
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
