#!/bin/bash

# ============================================
# OpenClaw Content Factory 卸载脚本
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
OC_HOME="$HOME/.openclaw"
OC_CFG="$OC_HOME/openclaw.json"

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
REPO_DIR="$HOME/.openclaw/openclaw-content-factory"
WORKSPACE_REPO_DIR="$HOME/.openclaw/workspace/openclaw-content-factory"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       🗑️  OpenClaw Content Factory 卸载程序              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 检查工作目录是否存在
if [ ! -d "$WORKSPACE_DIR" ]; then
    print_warning "工作目录不存在: $WORKSPACE_DIR"
    print_info "可能未安装或已被卸载"
fi

# 显示将要删除的内容
echo "⚠️  以下内容将被处理:"
echo ""
if [ -d "$WORKSPACE_DIR" ]; then
    echo "  📁 工作目录: $WORKSPACE_DIR"
    CONFIG_COUNT=$(find "$WORKSPACE_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    MEMORY_COUNT=$(find "$WORKSPACE_DIR/memory" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "     - 配置文件: $CONFIG_COUNT 个"
    echo "     - 日记记录: $MEMORY_COUNT 个"
fi
if [ -f "$OC_CFG" ]; then
    echo "  📄 Agent 注册: content (将从 openclaw.json 移除)"
fi
if [ -d "$REPO_DIR" ]; then
    echo "  📦 Git 仓库: $REPO_DIR"
fi
if [ -d "$WORKSPACE_REPO_DIR" ]; then
    echo "  📦 工作区仓库: $WORKSPACE_REPO_DIR"
fi
echo ""

# 选择卸载模式
echo "请选择卸载模式:"
echo ""
echo "  1) 完全卸载 - 删除所有配置和日记"
echo "  2) 保留日记 - 仅删除配置文件，保留 memory 目录"
echo "  3) 仅移除注册 - 仅从 openclaw.json 移除 Agent，保留文件"
echo "  4) 退出"
echo ""
read -p "请输入选项 (1-4): " -n 1 -r
echo ""

case $REPLY in
    1)
        UNINSTALL_MODE="full"
        ;;
    2)
        UNINSTALL_MODE="keep_memory"
        ;;
    3)
        UNINSTALL_MODE=" unregister_only"
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

# 确认卸载
echo ""
print_warning "此操作不可逆，请确认!"
read -p "确定要继续卸载吗? (yes/no): " -r
echo ""

if [[ ! $REPLY == "yes" ]]; then
    print_info "已取消卸载"
    exit 0
fi

# ── 移除 Agent 注册 ─────────────────────────────────────
unregister_agent() {
    print_info "移除 Agent 注册..."

    if [ ! -f "$OC_CFG" ]; then
        print_warning "未找到 $OC_CFG，跳过 Agent 移除"
        return
    fi

    python3 << 'PYEOF'
import json, pathlib, sys

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'

try:
    cfg = json.loads(cfg_path.read_text())
except Exception as e:
    print(f'  ! 读取配置失败: {e}')
    sys.exit(1)

agents_cfg = cfg.get('agents', {})
agents_list = agents_cfg.get('list', [])
# bindings 是顶级字段，不在 agents 下面
bindings_list = cfg.get('bindings', [])

# 移除 content agent (from list)
original_count = len(agents_list)
agents_list = [a for a in agents_list if a.get('id') != 'content']
removed_count = original_count - len(agents_list)

if removed_count > 0:
    agents_cfg['list'] = agents_list
    print(f'  ✓ 已移除 content agent (list)')
else:
    print(f'  ~ content agent 不存在于 list，无需移除')

# 移除 content agent 绑定的群组 (from bindings - 顶级字段)
original_bindings_count = len(bindings_list)
new_bindings = [b for b in bindings_list if b.get('agentId') != 'content']
removed_bindings_count = original_bindings_count - len(new_bindings)

if removed_bindings_count > 0:
    cfg['bindings'] = new_bindings
    print(f'  ✓ 已移除 {removed_bindings_count} 个群组绑定')
else:
    print(f'  ~ 无群组绑定需要移除')

# 保存配置
if removed_count > 0 or removed_bindings_count > 0:
    cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
PYEOF

    print_success "Agent 注册已移除"
}

# ── 删除配置文件 ─────────────────────────────────────
remove_config_files() {
    print_info "删除配置文件..."

    REQUIRED_FILES=("AGENTS.md" "SOUL.md" "USER.md" "TOOLS.md" "SOP_CONTENT.md" "HEARTBEAT.md" "MEMORY.md")

    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$WORKSPACE_DIR/$file" ]; then
            rm "$WORKSPACE_DIR/$file"
            print_info "  已删除: $file"
        fi
    done

    print_success "配置文件已删除"
}

# ── 删除整个工作目录 ─────────────────────────────────────
remove_workspace() {
    print_info "删除工作目录..."

    if [ -d "$WORKSPACE_DIR" ]; then
        rm -rf "$WORKSPACE_DIR"
        print_success "工作目录已删除: $WORKSPACE_DIR"
    else
        print_warning "工作目录不存在"
    fi
}

# ── 删除 Git 仓库目录 ─────────────────────────────────────
remove_repo() {
    print_info "删除 Git 仓库目录..."

    if [ -d "$REPO_DIR" ]; then
        rm -rf "$REPO_DIR"
        print_success "Git 仓库目录已删除: $REPO_DIR"
    else
        print_warning "Git 仓库目录不存在: $REPO_DIR"
    fi

    if [ -d "$WORKSPACE_REPO_DIR" ]; then
        rm -rf "$WORKSPACE_REPO_DIR"
        print_success "工作区仓库目录已删除: $WORKSPACE_REPO_DIR"
    else
        print_warning "工作区仓库目录不存在: $WORKSPACE_REPO_DIR"
    fi
}

# ── 仅删除配置文件，保留 memory ─────────────────────────────────────
remove_config_keep_memory() {
    print_info "删除配置文件（保留 memory 目录）..."

    REQUIRED_FILES=("AGENTS.md" "SOUL.md" "USER.md" "TOOLS.md" "SOP_CONTENT.md" "HEARTBEAT.md" "MEMORY.md")

    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$WORKSPACE_DIR/$file" ]; then
            rm "$WORKSPACE_DIR/$file"
            print_info "  已删除: $file"
        fi
    done

    # 检查 memory 目录是否保留
    if [ -d "$WORKSPACE_DIR/memory" ]; then
        print_success "配置文件已删除，memory 目录已保留"
    fi
}

# ── 清理备份文件（可选）─────────────────────────────────────
cleanup_backups() {
    print_info "检查备份文件..."

    BACKUP_COUNT=$(find "$OC_HOME" -maxdepth 1 -name "workspace-content_backup_*" -type d 2>/dev/null | wc -l | tr -d ' ')

    if [ "$BACKUP_COUNT" -gt 0 ]; then
        echo ""
        echo "发现 $BACKUP_COUNT 个备份目录:"
        find "$OC_HOME" -maxdepth 1 -name "workspace-content_backup_*" -type d 2>/dev/null | while read dir; do
            echo "  - $(basename "$dir")"
        done
        echo ""
        read -p "是否同时删除这些备份? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            find "$OC_HOME" -maxdepth 1 -name "workspace-content_backup_*" -type d -exec rm -rf {} \;
            print_success "备份文件已清理"
        fi
    fi
}

# ── 执行卸载逻辑 ─────────────────────────────────────
case $UNINSTALL_MODE in
    "full")
        unregister_agent
        remove_workspace
        remove_repo
        cleanup_backups
        ;;
    "keep_memory")
        unregister_agent
        remove_config_keep_memory
        ;;
    "unregister_only")
        unregister_agent
        ;;
esac

echo ""
print_success "✅ 卸载完成!"
echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""

case $UNINSTALL_MODE in
    "full")
        echo "📦 所有内容已完全移除"
        ;;
    "keep_memory")
        echo "📦 配置文件已移除，日记保留在:"
        echo "   $WORKSPACE_DIR/memory/"
        echo ""
        echo "   如需彻底删除，请运行: rm -rf $WORKSPACE_DIR"
        ;;
    "unregister_only")
        echo "📦 Agent 注册已移除，文件保留在:"
        echo "   $WORKSPACE_DIR/"
        echo ""
        echo "   如需重新启用，请运行: ./install.sh"
        ;;
esac

echo ""
echo "🙏 感谢使用 OpenClaw Content Factory"
echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""