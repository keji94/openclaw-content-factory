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


# ── Step 2: 注册 Agents & 绑定群组 ─────────────────────────────────────
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

  # 获取飞书群组 ID（可选）
  local chat_id="${FEISHU_CHAT_ID:-}"
  if [ -n "$chat_id" ]; then
    print_info "检测到飞书群组 ID: $chat_id"
  fi

  python3 << PYEOF
import json, pathlib, sys, os

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'
cfg = json.loads(cfg_path.read_text())

# 注册 Agent
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

# 绑定飞书群组（如果提供了 chat_id）
chat_id = os.environ.get('FEISHU_CHAT_ID', '')
if chat_id:
    bindings = cfg.setdefault('bindings', [])
    # 检查是否已存在该群组绑定
    existing_binding = any(
        b.get('agentId') == 'content' and
        b.get('match', {}).get('peer', {}).get('id') == chat_id
        for b in bindings
    )
    if not existing_binding:
        binding = {
            "agentId": "content",
            "match": {
                "channel": "feishu",
                "peer": {"kind": "group", "id": chat_id}
            }
        }
        bindings.append(binding)
        print(f'  + bound: feishu group {chat_id} -> content')
    else:
        print(f'  ~ binding exists: {chat_id} (skipped)')

cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
print(f'Done: {added} agents added')
PYEOF

  print_success "Agents 注册完成"
}

# 调用注册函数
register_agents

# ── Step 3: 创建 Agent 状态目录 (agentDir) ─────────────────────────────────
create_agent_dirs() {
  print_info "创建 Agent 状态目录 (agentDir)..."

  # 定义需要创建 agentDir 的 Agent 列表
  local AGENT_IDS=("content")

  for agent_id in "${AGENT_IDS[@]}"; do
    local AGENT_DIR="$HOME/.openclaw/agents/$agent_id/agent"

    # 创建 agent 目录
    mkdir -p "$AGENT_DIR"

    # 创建 auth-profiles.json（存储 API 密钥、OAuth 令牌等凭证）
    local AUTH_PROFILES="$AGENT_DIR/auth-profiles.json"
    if [ ! -f "$AUTH_PROFILES" ]; then
      echo '{}' > "$AUTH_PROFILES"
      print_info "  创建: $AUTH_PROFILES"
    else
      print_info "  已存在: $AUTH_PROFILES (跳过)"
    fi

    # 创建 models.json（存储 Agent 可用的模型列表和配置）
    local MODELS_JSON="$AGENT_DIR/models.json"
    if [ ! -f "$MODELS_JSON" ]; then
      echo '{}' > "$MODELS_JSON"
      print_info "  创建: $MODELS_JSON"
    else
      print_info "  已存在: $MODELS_JSON (跳过)"
    fi

    # 设置权限（敏感文件）
    chmod 600 "$AUTH_PROFILES" "$MODELS_JSON"
  done

  print_success "Agent 状态目录创建完成"
}

# 调用创建函数
create_agent_dirs

# ── Step 4: 安装本地 Skills ─────────────────────────────────
install_local_skills() {
  print_info "安装本地 Skills..."

  local SKILLS_SRC="$SCRIPT_DIR/config/skills"
  local SKILLS_DEST="$WORKSPACE_DIR/skills"

  if [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$SKILLS_DEST"

    local skill_count=0
    for skill_dir in "$SKILLS_SRC"/*; do
      if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        cp -r "$skill_dir" "$SKILLS_DEST/"
        print_info "  安装: $skill_name"
        skill_count=$((skill_count + 1))
      fi
    done

    if [ $skill_count -gt 0 ]; then
      print_success "本地 Skills 安装完成 ($skill_count 个)"
    else
      print_warning "未找到有效的 Skill 目录"
    fi
  else
    print_warning "未找到本地 Skills 目录: $SKILLS_SRC"
  fi
}

# 调用安装函数
install_local_skills

# ── Step 5: 配置 API Keys ─────────────────────────────────
configure_api_keys() {
  print_info "配置 API Keys..."

  local ENV_FILE="$HOME/.openclaw/.env"
  local AUTH_PROFILES="$HOME/.openclaw/agents/content/agent/auth-profiles.json"
  local SKILLS_DIR="$WORKSPACE_DIR/skills"

  # 定义需要的 API Keys（名称:描述:存放位置）
  # 存放位置: "global" = ~/.openclaw/.env, "skill:目录名" = skills/目录名/.env
  local API_KEY_CONFIGS=(
    "TAVILY_API_KEY:Tavily 搜索:global"
    "SILICONFLOW_API_KEY:硅基流动 API:skill:yzfly-douyin-mcp-server-douyin-video"
  )

  local has_keys=0

  for item in "${API_KEY_CONFIGS[@]}"; do
    key_name="${item%%:*}"
    rest="${item#*:}"
    key_desc="${rest%%:*}"
    key_location="${rest#*:}"

    key_value="${!key_name}"

    if [ -n "$key_value" ]; then
      has_keys=1
      print_info "  检测到 $key_desc ($key_name)"

      # 根据存放位置写入不同文件
      if [ "$key_location" = "global" ]; then
        # 写入全局 .env
        write_env_key "$ENV_FILE" "$key_name" "$key_value"
        print_info "    → $ENV_FILE"
      else
        # 写入 skill 目录下的 .env
        skill_name="${key_location#skill:}"
        skill_env_file="$SKILLS_DIR/$skill_name/.env"
        write_env_key "$skill_env_file" "$key_name" "$key_value"
        print_info "    → $skill_env_file"
      fi
    fi
  done

  if [ $has_keys -eq 1 ]; then
    # 设置权限
    [ -f "$ENV_FILE" ] && chmod 600 "$ENV_FILE"

    # 更新 auth-profiles.json
    if [ -f "$AUTH_PROFILES" ]; then
      python3 << 'PYEOF'
import json
import os
from pathlib import Path

auth_file = Path.home() / ".openclaw" / "agents" / "content" / "agent" / "auth-profiles.json"

try:
    data = json.loads(auth_file.read_text())
except:
    data = {}

# 确保 api_keys 字段存在
if "api_keys" not in data:
    data["api_keys"] = {}

# 从环境变量读取并更新
for key_name in ["TAVILY_API_KEY", "SILICONFLOW_API_KEY"]:
    value = os.environ.get(key_name)
    if value:
        data["api_keys"][key_name] = value

auth_file.write_text(json.dumps(data, ensure_ascii=False, indent=2))
print("  ✓ auth-profiles.json 已更新")
PYEOF
      print_success "API Keys 已记录到 auth-profiles.json"
    fi
  else
    print_warning "未检测到 API Keys 环境变量"
    echo ""
    echo "  可通过以下方式配置 API Keys:"
    echo ""
    echo "    TAVILY_API_KEY=xxx SILICONFLOW_API_KEY=xxx ./install.sh"
    echo ""
    echo "  或在安装后编辑对应的 .env 文件"
  fi
}

# 写入单个 key 到 .env 文件
write_env_key() {
  local env_file="$1"
  local key_name="$2"
  local key_value="$3"

  # 确保目录存在
  mkdir -p "$(dirname "$env_file")"
  touch "$env_file"

  # 检查是否已存在，存在则更新，不存在则添加
  if grep -q "^${key_name}=" "$env_file" 2>/dev/null; then
    # 兼容 macOS 和 Linux 的 sed
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|^${key_name}=.*|${key_name}=${key_value}|" "$env_file"
    else
      sed -i "s|^${key_name}=.*|${key_name}=${key_value}|" "$env_file"
    fi
  else
    echo "${key_name}=${key_value}" >> "$env_file"
  fi

  chmod 600 "$env_file"
}

# 调用配置函数
configure_api_keys

echo ""
print_success "✅ 安装完成!"
echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""
echo "📁 配置文件已安装到: $WORKSPACE_DIR"
echo "📁 Agent 状态目录: $HOME/.openclaw/agents/content/agent/"
echo "📁 Skills 目录: $WORKSPACE_DIR/skills/"
print_success "🎉 开始使用你的 AI 内容工厂吧!"
