#!/bin/bash
# 一键部署到 GitHub 脚本

set -e  # 遇到错误立即退出

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Shell 工具函数 - GitHub 部署脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查是否在正确的目录
if [ ! -f "utils.sh" ] || [ ! -f "example.sh" ] || [ ! -f "README.md" ]; then
    echo -e "${RED}错误：请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 检查 Git 是否初始化
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Git 仓库未初始化，正在初始化...${NC}"
    git init
    git config user.name "Shell Utils Bot"
    git config user.email "bot@example.com"
    git add .
    git commit -m "feat: 初始化 Shell 工具函数项目"
fi

# 检查 GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI 未安装，正在安装...${NC}"
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install -y gh
    elif [ -f /etc/redhat-release ]; then
        # RHEL/CentOS
        sudo dnf install -y 'dnf-command(config-manager)'
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo dnf install -y gh
    else
        echo -e "${RED}不支持的操作系统，请手动安装 GitHub CLI${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}GitHub CLI 已就绪${NC}"
echo ""

# 检查是否已登录 GitHub
if ! gh auth status 2>/dev/null; then
    echo -e "${YELLOW}需要登录 GitHub${NC}"
    echo ""
    echo "请选择登录方式："
    echo "1) 使用网页浏览器登录（推荐）"
    echo "2) 使用 Personal Access Token 登录"
    read -p "请输入选项 (1 或 2): " choice

    case $choice in
        1)
            echo ""
            echo -e "${BLUE}正在打开 GitHub 登录页面...${NC}"
            gh auth login
            ;;
        2)
            echo ""
            echo "请访问 https://github.com/settings/tokens/new 创建 Personal Access Token"
            echo "需要的权限：repo (完整仓库访问权限)"
            echo ""
            read -sp "请输入您的 GitHub Personal Access Token: " token
            echo ""
            echo "$token" | gh auth login --with-token
            ;;
        *)
            echo -e "${RED}无效的选项${NC}"
            exit 1
            ;;
    esac

    if ! gh auth status 2>/dev/null; then
        echo -e "${RED}登录失败，请重试${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}GitHub 认证成功！${NC}"
echo ""

# 获取仓库信息
read -p "请输入仓库名称 (默认: shell-utils): " repo_name
repo_name=${repo_name:-shell-utils}

read -p "请输入仓库描述 (默认: Shell 工具函数集合): " repo_description
repo_description=${repo_description:-Shell 工具函数集合}

echo ""
echo "请选择仓库可见性："
echo "1) Public（公开）"
echo "2) Private（私有）"
read -p "请输入选项 (1 或 2, 默认: 1): " visibility_choice

case $visibility_choice in
    2)
        visibility="--private"
        ;;
    *)
        visibility="--public"
        ;;
esac

echo ""
echo -e "${BLUE}正在创建 GitHub 仓库 '${repo_name}'...${NC}"

# 创建仓库并推送
gh repo create "$repo_name" $visibility --description "$repo_description" --source=. --push

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   部署成功！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "您的仓库地址：${BLUE}https://github.com/$(gh api user --jq .login 2>/dev/null || echo "${GH_USERNAME:-unknown}")/${repo_name}${NC}"
echo ""
echo -e "您可以访问上述链接查看您的代码！"
echo ""
