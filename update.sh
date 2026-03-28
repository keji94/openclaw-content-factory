#!/bin/bash

# ============================================
# OpenClaw Content Factory 更新脚本
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
OC_HOME="$HOME/.openclaw"
WORKSPACE_DIR="$OC_HOME/workspace-openclaw-content-factory"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       OpenClaw Content Factory 更新程序                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 检查工作空间是否存在
if [ ! -e "$WORKSPACE_DIR" ] && [ ! -L "$WORKSPACE_DIR" ]; then
    print_error "未找到工作空间: $WORKSPACE_DIR"
    print_info "请先运行 install.sh 进行安装"
    exit 1
fi

# 检查是否为符号链接（workspace 即 git 项目）
if [ -L "$WORKSPACE_DIR" ]; then
    ACTUAL_DIR="$(readlink -f "$WORKSPACE_DIR")"
    print_info "工作空间为符号链接: $ACTUAL_DIR"
else
    ACTUAL_DIR="$WORKSPACE_DIR"
fi

# 拉取最新代码
if [ -d "$ACTUAL_DIR/.git" ]; then
    print_info "拉取最新代码..."
    cd "$ACTUAL_DIR"
    if git pull; then
        print_success "代码已更新到最新版本"
    else
        print_warning "git pull 失败，请检查是否有未提交的本地修改"
        exit 1
    fi
else
    print_error "工作空间不是 git 仓库，无法更新"
    exit 1
fi

# 确保 memory 目录存在
mkdir -p "$WORKSPACE_DIR/memory"
TODAY=$(date +%Y-%m-%d)
touch "$WORKSPACE_DIR/memory/$TODAY.md"

echo ""
print_success "更新完成!"
echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""
echo "  工作空间: $WORKSPACE_DIR"
echo "  memory 目录已保留"
echo ""

# 询问是否重启 Gateway
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "是否立即重启 Gateway 使配置生效? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "正在重启 Gateway..."

    if openclaw gateway restart; then
        print_success "Gateway 重启命令已执行"
    else
        print_error "Gateway 重启命令执行失败"
        print_info "您可以稍后手动执行: openclaw gateway restart"
        exit 1
    fi

    print_info "正在检查 Gateway 状态..."
    MAX_RETRIES=12
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        sleep 5
        RETRY_COUNT=$((RETRY_COUNT + 1))

        if openclaw gateway status 2>/dev/null | grep -q "running\|active\|online"; then
            print_success "Gateway 已成功启动!"
            exit 0
        fi

        print_info "等待 Gateway 启动... ($RETRY_COUNT/$MAX_RETRIES)"
    done

    print_warning "Gateway 状态检查超时，请手动确认: openclaw gateway status"
else
    echo ""
    print_info "您可以稍后手动重启 Gateway:"
    echo ""
    echo "   openclaw gateway restart"
    echo ""
fi

echo "═════════════════════════════════════════════════════════════"
echo ""
