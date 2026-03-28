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
if [ ! -d "$WORKSPACE_DIR" ]; then
    print_error "未找到工作空间: $WORKSPACE_DIR"
    print_info "请先运行 install.sh 进行安装"
    exit 1
fi

# 拉取最新代码
if [ -d "$SCRIPT_DIR/.git" ]; then
    print_info "拉取最新代码..."
    cd "$SCRIPT_DIR"
    if git pull; then
        print_success "代码已更新到最新版本"
    else
        print_warning "git pull 失败，将使用本地代码继续更新"
    fi
else
    print_warning "当前目录不是 git 仓库，跳过 git pull"
fi

# 显示更新选项
echo ""
echo "请选择更新模式:"
echo ""
echo "  1) 全部更新 - 同步所有文件（保留 memory/ 和 skills/*/.env）"
echo "  2) 查看差异 - 查看文件变更"
echo "  3) 退出"
echo ""
read -p "请输入选项 (1-3): " -n 1 -r
echo ""

case $REPLY in
    1) UPDATE_MODE="all" ;;
    2) UPDATE_MODE="diff" ;;
    3) print_info "已退出"; exit 0 ;;
    *) print_error "无效选项"; exit 1 ;;
esac

# 备份
backup_workspace() {
    local BACKUP_DIR="$OC_HOME/workspace-openclaw-content-factory_backup_$(date +%Y%m%d_%H%M%S)"
    print_info "备份工作空间到: $BACKUP_DIR"
    cp -r "$WORKSPACE_DIR" "$BACKUP_DIR"
    print_success "备份完成"
}

# 执行更新
do_update() {
    print_info "同步文件到工作空间..."

    rsync -a \
        --exclude='.git' \
        --exclude='.idea' \
        --exclude='.vscode' \
        --exclude='.claude' \
        --exclude='node_modules' \
        --exclude='.env' \
        --exclude='.DS_Store' \
        --exclude='Thumbs.db' \
        --exclude='.env.example' \
        --exclude='memory/' \
        "$SCRIPT_DIR/" "$WORKSPACE_DIR/"

    # 同步 skills 目录（保留各 skill 的 .env 和 node_modules）
    if [ -d "$SCRIPT_DIR/skills" ]; then
        for skill_dir in "$SCRIPT_DIR/skills"/*/; do
            [ -d "$skill_dir" ] || continue
            skill_name=$(basename "$skill_dir")
            rsync -a \
                --exclude='.env' \
                --exclude='node_modules' \
                --exclude='__pycache__' \
                "$skill_dir" "$WORKSPACE_DIR/skills/$skill_name/" 2>/dev/null || true
        done
    fi

    # 确保 memory 目录存在
    mkdir -p "$WORKSPACE_DIR/memory"

    # 创建今日日记文件
    TODAY=$(date +%Y-%m-%d)
    touch "$WORKSPACE_DIR/memory/$TODAY.md"

    print_success "文件同步完成"
}

# 查看差异
show_diffs() {
    print_info "查看文件差异..."

    echo ""
    diff -rq \
        --exclude='.git' --exclude='.idea' --exclude='.vscode' --exclude='.claude' \
        --exclude='node_modules' --exclude='.env' --exclude='.DS_Store' --exclude='Thumbs.db' \
        --exclude='.env.example' --exclude='memory' \
        "$SCRIPT_DIR/" "$WORKSPACE_DIR/" 2>/dev/null || true

    echo ""
    read -p "是否继续更新? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_workspace
        do_update
    else
        print_info "已取消更新"
        exit 0
    fi
}

case $UPDATE_MODE in
    "all")
        backup_workspace
        do_update
        ;;
    "diff")
        show_diffs
        ;;
esac

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
