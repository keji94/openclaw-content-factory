#!/bin/bash

# ============================================
# OpenClaw Content Factory 安装脚本
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

# 检查 OpenClaw 工作目录（使用专属 workspace-content，不影响主 workspace）
WORKSPACE_DIR="$HOME/.openclaw/workspace-content"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       🏭 OpenClaw Content Factory 安装程序               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 检查是否已存在工作目录
if [ -d "$WORKSPACE_DIR" ]; then
    print_warning "检测到已存在工作目录: $WORKSPACE_DIR"
    read -p "是否备份现有配置并继续? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "安装已取消"
        exit 0
    fi
    
    # 备份现有配置
    BACKUP_DIR="$HOME/.openclaw/$(basename "$WORKSPACE_DIR")_backup_$(date +%Y%m%d_%H%M%S)"
    print_info "备份现有配置到: $BACKUP_DIR"
    cp -r "$WORKSPACE_DIR" "$BACKUP_DIR"
fi

# 创建工作目录
print_info "创建工作目录..."
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR/memory"

# 复制配置文件
print_info "复制配置文件..."
cp -r "$SCRIPT_DIR/config/"* "$WORKSPACE_DIR/"

# 检查配置文件是否复制成功
REQUIRED_FILES=("AGENTS.md" "SOUL.md" "USER.md" "TOOLS.md" "SOP_CONTENT.md" "HEARTBEAT.md" "MEMORY.md")
MISSING_FILES=0

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$WORKSPACE_DIR/$file" ]; then
        print_error "缺少配置文件: $file"
        MISSING_FILES=1
    fi
done

if [ $MISSING_FILES -eq 1 ]; then
    print_error "配置文件不完整，请检查 config 目录"
    exit 1
fi

# 创建 memory 目录
print_info "创建 memory 目录..."
mkdir -p "$WORKSPACE_DIR/memory"

# 设置权限
print_info "设置文件权限..."
chmod 644 "$WORKSPACE_DIR"/*.md

# 创建今日日记文件
TODAY=$(date +%Y-%m-%d)
touch "$WORKSPACE_DIR/memory/$TODAY.md"


# ── Step 2: 注册 Agents ─────────────────────────────────────
register_agents() {
  print_info "注册内容工厂Agent..."

  # 备份配置
  if [ -f "$OC_CFG" ]; then
    cp "$OC_CFG" "$OC_CFG.bak.content-$(date +%Y%m%d-%H%M%S)"
    print_info "已备份配置: $OC_CFG.bak.*"
  else
    print_warning "未找到 $OC_CFG，跳过 Agent 注册"
    return
  fi

  python3 << 'PYEOF'
import json, pathlib, sys

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'
cfg = json.loads(cfg_path.read_text())

AGENTS = [
  {"id": "content"}
]

agents_cfg = cfg.setdefault('agents', {})
agents_list = agents_cfg.get('list', [])
existing_ids = {a['id'] for a in agents_list}

added = 0
for ag in AGENTS:
    ag_id = ag['id']
    ws = str(pathlib.Path.home() / f'.openclaw/workspace-{ag_id}')
    if ag_id not in existing_ids:
        entry = {'id': ag_id, 'workspace': ws, **{k:v for k,v in ag.items() if k!='id'}}
        agents_list.append(entry)
        added += 1
        print(f'  + added: {ag_id}')
    else:
        print(f'  ~ exists: {ag_id} (skipped)')

agents_cfg['list'] = agents_list
cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
print(f'Done: {added} agents added')
PYEOF

  print_success "Agents 注册完成"
}

# 调用注册函数
register_agents

echo ""
print_success "✅ 安装完成!"
echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""
echo "📁 配置文件已安装到: $WORKSPACE_DIR"
echo ""
echo "🚀 接下来的步骤:"
echo ""
echo "1. 打开 ArkClaw 或 OpenClaw"
echo ""
echo "2. 发送以下提示词导入配置:"
echo ""
echo "   接下来我会发多份配置文件给你，需要配置到你项目文件夹里："
echo ""
for file in "${REQUIRED_FILES[@]}"; do
    echo "   - $file"
done
echo ""
echo "3. 然后把以下文件内容依次发给 AI:"
echo "   $WORKSPACE_DIR/AGENTS.md"
echo "   $WORKSPACE_DIR/SOUL.md"
echo "   $WORKSPACE_DIR/USER.md"
echo "   $WORKSPACE_DIR/TOOLS.md"
echo "   $WORKSPACE_DIR/SOP_CONTENT.md"
echo "   $WORKSPACE_DIR/HEARTBEAT.md"
echo "   $WORKSPACE_DIR/MEMORY.md"
echo ""
echo "4. 验证配置是否成功:"
echo ""
echo "   我刚刚给你发了一套配置文件，请现在按顺序读取以下文件并确认加载成功："
echo "   AGENTS.md / SOUL.md / USER.md / TOOLS.md / SOP_CONTENT.md / HEARTBEAT.md / MEMORY.md"
echo ""
echo "   读完之后告诉我："
echo "   1. 你现在的角色是什么"
echo "   2. 你能操作哪些飞书功能"
echo "   3. 内容生产流程有几个阶段，分别叫什么"
echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""

print_success "🎉 开始使用你的 AI 内容工厂吧!"
