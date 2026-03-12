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

# 工作目录
WORKSPACE_DIR="$HOME/.openclaw/workspace-content"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       🔄 OpenClaw Content Factory 配置更新程序           ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 检查工作目录是否存在
if [ ! -d "$WORKSPACE_DIR" ]; then
    print_error "未找到工作目录: $WORKSPACE_DIR"
    print_info "请先运行 install.sh 进行安装"
    exit 1
fi

# 必需的配置文件
REQUIRED_FILES=("AGENTS.md" "SOUL.md" "USER.md" "TOOLS.md" "SOP_CONTENT.md" "HEARTBEAT.md" "MEMORY.md")

# 检查源配置文件是否存在
print_info "检查源配置文件..."
MISSING_SOURCE=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/config/$file" ]; then
        print_error "缺少源配置文件: config/$file"
        MISSING_SOURCE=1
    fi
done

if [ $MISSING_SOURCE -eq 1 ]; then
    print_error "源配置文件不完整，请检查 config 目录"
    exit 1
fi

# 显示更新选项
echo ""
echo "请选择更新模式:"
echo ""
echo "  1) 全部更新 - 更新所有配置文件（保留 memory 目录）"
echo "  2) 选择性更新 - 选择要更新的配置文件"
echo "  3) 查看差异 - 查看新旧配置文件的差异"
echo "  4) 退出"
echo ""
read -p "请输入选项 (1-4): " -n 1 -r
echo ""

case $REPLY in
    1)
        UPDATE_MODE="all"
        ;;
    2)
        UPDATE_MODE="select"
        ;;
    3)
        UPDATE_MODE="diff"
        ;;
    4)
        print_info "已退出"
        exit 0
        ;;
    *)
        print_error "无效选项"
        exit 1
        ;;
esac

# 备份函数
backup_config() {
    BACKUP_DIR="$HOME/.openclaw/workspace-content_backup_$(date +%Y%m%d_%H%M%S)"
    print_info "备份当前配置到: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$WORKSPACE_DIR/$file" ]; then
            cp "$WORKSPACE_DIR/$file" "$BACKUP_DIR/"
        fi
    done
    print_success "备份完成"
}

# 更新文件函数
update_file() {
    local file=$1
    print_info "更新 $file ..."
    cp "$SCRIPT_DIR/config/$file" "$WORKSPACE_DIR/$file"
    print_success "已更新: $file"
}

# 查看差异函数
show_diff() {
    local file=$1
    if [ -f "$WORKSPACE_DIR/$file" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📄 $file 差异:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        if diff -u "$WORKSPACE_DIR/$file" "$SCRIPT_DIR/config/$file" 2>/dev/null; then
            print_info "无差异"
        fi
    else
        print_warning "$file 不存在于目标目录，将被创建"
    fi
}

# 执行更新逻辑
case $UPDATE_MODE in
    "all")
        backup_config
        print_info "开始更新所有配置文件..."
        for file in "${REQUIRED_FILES[@]}"; do
            update_file "$file"
        done
        ;;
    "select")
        backup_config
        echo ""
        echo "请选择要更新的配置文件 (用空格分隔，例如: 1 3 5):"
        echo ""
        i=1
        for file in "${REQUIRED_FILES[@]}"; do
            echo "  $i) $file"
            ((i++))
        done
        echo "  0) 全部选择"
        echo ""
        read -p "请输入: " -a selections

        for sel in "${selections[@]}"; do
            if [ "$sel" -eq 0 ] 2>/dev/null; then
                for file in "${REQUIRED_FILES[@]}"; do
                    update_file "$file"
                done
                break
            elif [ "$sel" -ge 1 ] && [ "$sel" -le ${#REQUIRED_FILES[@]} ] 2>/dev/null; then
                index=$((sel - 1))
                update_file "${REQUIRED_FILES[$index]}"
            fi
        done
        ;;
    "diff")
        print_info "查看配置文件差异..."
        for file in "${REQUIRED_FILES[@]}"; do
            show_diff "$file"
        done
        echo ""
        read -p "是否继续更新? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            backup_config
            for file in "${REQUIRED_FILES[@]}"; do
                update_file "$file"
            done
        else
            print_info "已取消更新"
            exit 0
        fi
        ;;
esac

# 设置文件权限
print_info "设置文件权限..."
chmod 644 "$WORKSPACE_DIR"/*.md 2>/dev/null || true

# 确保 memory 目录存在
if [ ! -d "$WORKSPACE_DIR/memory" ]; then
    print_info "创建 memory 目录..."
    mkdir -p "$WORKSPACE_DIR/memory"
fi

# 创建今日日记文件（如果不存在）
TODAY=$(date +%Y-%m-%d)
if [ ! -f "$WORKSPACE_DIR/memory/$TODAY.md" ]; then
    touch "$WORKSPACE_DIR/memory/$TODAY.md"
    print_info "创建今日日记: $TODAY.md"
fi

echo ""
print_success "✅ 配置更新完成!"
echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""
echo "📁 配置文件位置: $WORKSPACE_DIR"
echo ""
echo "📝 memory 目录已保留，您的日记和记录不受影响"
echo ""
echo "🔄 如需在 AI 中应用新配置，请重新发送配置文件:"
echo ""
echo "   我会发送更新后的配置文件，请按顺序加载："
echo "   AGENTS.md / SOUL.md / USER.md / TOOLS.md / SOP_CONTENT.md / HEARTBEAT.md / MEMORY.md"
echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""