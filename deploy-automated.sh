#!/bin/bash
# 自动化 GitHub 部署脚本（使用环境变量）

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   自动化 GitHub 部署脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查必要的环境变量
if [ -z "$GH_TOKEN" ]; then
    echo -e "${RED}错误：请设置 GH_TOKEN 环境变量${NC}"
    echo ""
    echo "使用方法："
    echo "  export GH_TOKEN=your_github_personal_access_token"
    echo "  export GH_USERNAME=your_github_username"
    echo "  export GH_REPO_NAME=shell-utils  # 可选"
    echo "  export GH_VISIBILITY=public       # 可选: public 或 private"
    echo "  ./deploy-automated.sh"
    echo ""
    echo "获取 GitHub Token："
    echo "  访问 https://github.com/settings/tokens/new"
    echo "  选择 repo 权限，创建后复制 token"
    exit 1
fi

if [ -z "$GH_USERNAME" ]; then
    echo -e "${RED}错误：请设置 GH_USERNAME 环境变量${NC}"
    exit 1
fi

# 设置默认值
GH_REPO_NAME=${GH_REPO_NAME:-shell-utils}
GH_VISIBILITY=${GH_VISIBILITY:-public}
GH_DESCRIPTION=${GH_DESCRIPTION:-Shell 工具函数集合}

echo -e "${YELLOW}配置信息：${NC}"
echo "  用户名: $GH_USERNAME"
echo "  仓库名: $GH_REPO_NAME"
echo "  可见性: $GH_VISIBILITY"
echo ""

# 使用 token 认证
echo -e "${BLUE}正在认证 GitHub...${NC}"
echo "$GH_TOKEN" | gh auth login --with-token

# 验证认证
if ! gh auth status 2>/dev/null; then
    echo -e "${RED}GitHub 认证失败，请检查您的 token${NC}"
    exit 1
fi

echo -e "${GREEN}GitHub 认证成功！${NC}"
echo ""

# 创建仓库并推送
echo -e "${BLUE}正在创建仓库 '${GH_REPO_NAME}' 并推送代码...${NC}"

if [ "$GH_VISIBILITY" = "private" ]; then
    gh repo create "$GH_REPO_NAME" --private --description "$GH_DESCRIPTION" --source=. --push
else
    gh repo create "$GH_REPO_NAME" --public --description "$GH_DESCRIPTION" --source=. --push
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   部署成功！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "您的仓库地址：${BLUE}https://github.com/${GH_USERNAME}/${GH_REPO_NAME}${NC}"
echo ""
echo -e "现在您可以在浏览器中打开上述链接查看您的代码！"
echo ""
