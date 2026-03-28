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
AGENT_ID="content"
WORKSPACE_NAME="workspace-openclaw-content-factory"
WORKSPACE_DIR="$OC_HOME/$WORKSPACE_NAME"

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

# 获取脚本所在目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 读取配置文件（如果存在）
if [ -f "$SCRIPT_DIR/.env" ]; then
  print_info "读取配置文件: $SCRIPT_DIR/.env"
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       OpenClaw Content Factory 安装程序                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: 创建符号链接指向 git 项目 ─────────────────────────────────────
install_workspace() {
  print_info "安装工作空间..."

  # 如果已存在，提示处理
  if [ -e "$WORKSPACE_DIR" ] || [ -L "$WORKSPACE_DIR" ]; then
    # 检查是否已经是指向当前项目的符号链接
    if [ -L "$WORKSPACE_DIR" ]; then
      local current_target
      current_target="$(readlink -f "$WORKSPACE_DIR")"
      if [ "$current_target" = "$SCRIPT_DIR" ]; then
        print_success "工作空间已是当前项目的符号链接，跳过"
        return
      fi
    fi
    print_warning "检测到已存在工作空间: $WORKSPACE_DIR"
    read -p "是否移除并重新链接? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "安装已取消"
        exit 0
    fi
    rm -rf "$WORKSPACE_DIR"
  fi

  # 创建目标目录
  mkdir -p "$OC_HOME"

  # 创建符号链接指向当前 git 项目
  ln -s "$SCRIPT_DIR" "$WORKSPACE_DIR"
  print_info "符号链接: $WORKSPACE_DIR -> $SCRIPT_DIR"

  # 确保 memory 目录存在
  mkdir -p "$WORKSPACE_DIR/memory"

  # 创建今日日记文件
  TODAY=$(date +%Y-%m-%d)
  touch "$WORKSPACE_DIR/memory/$TODAY.md"

  # 确保 .gitignore 包含 memory/
  if [ -f "$WORKSPACE_DIR/.gitignore" ]; then
    grep -qxF 'memory/' "$WORKSPACE_DIR/.gitignore" 2>/dev/null || echo 'memory/' >> "$WORKSPACE_DIR/.gitignore"
  fi

  print_success "工作空间安装完成（符号链接模式，修改即 git 可见）"
}

install_workspace

# ── Step 1.5: 初始化写作改进系统目录 ─────────────────────────────
init_writing_improvement() {
  print_info "初始化写作改进系统目录..."

  local WI_DIR="$WORKSPACE_DIR/writing-improvement"
  mkdir -p "$WI_DIR/drafts" "$WI_DIR/finals" "$WI_DIR/diffs"

  # 确保 .gitignore 包含 writing-improvement/
  if [ -f "$WORKSPACE_DIR/.gitignore" ]; then
    grep -qxF 'writing-improvement/' "$WORKSPACE_DIR/.gitignore" 2>/dev/null || echo 'writing-improvement/' >> "$WORKSPACE_DIR/.gitignore"
  fi

  print_success "写作改进目录已创建"
}
init_writing_improvement

# ── Step 2: 注册 Agent & 绑定群组 ─────────────────────────────────────
register_agent() {
  print_info "注册 Agent 到 openclaw.json ..."

  if [ ! -f "$OC_CFG" ]; then
    print_warning "未找到 $OC_CFG，跳过 Agent 注册"
    return
  fi

  # 备份配置
  cp "$OC_CFG" "$OC_CFG.bak.content-$(date +%Y%m%d-%H%M%S)"

  local chat_id="${FEISHU_CHAT_ID:-}"

  python3 << PYEOF
import json, pathlib, os

cfg_path = pathlib.Path.home() / '.openclaw' / 'openclaw.json'
cfg = json.loads(cfg_path.read_text())

# 注册 Agent
agents_cfg = cfg.setdefault('agents', {})
agents_list = agents_cfg.get('list', [])
existing_ids = {a['id'] for a in agents_list}

workspace = str(pathlib.Path.home() / '.openclaw' / '$WORKSPACE_NAME')

if '$AGENT_ID' not in existing_ids:
    entry = {'id': '$AGENT_ID', 'workspace': workspace}
    agents_list.append(entry)
    print(f'  + registered agent: $AGENT_ID')
else:
    # 更新已有 agent 的 workspace 路径
    for a in agents_list:
        if a.get('id') == '$AGENT_ID':
            a['workspace'] = workspace
            break
    print(f'  ~ agent $AGENT_ID exists (workspace updated)')

agents_cfg['list'] = agents_list

# 绑定飞书群组
chat_id = os.environ.get('FEISHU_CHAT_ID', '')
if chat_id:
    bindings = cfg.setdefault('bindings', [])
    existing_binding = any(
        b.get('agentId') == '$AGENT_ID' and
        b.get('match', {}).get('peer', {}).get('id') == chat_id
        for b in bindings
    )
    if not existing_binding:
        binding = {
            "agentId": "$AGENT_ID",
            "match": {
                "channel": "feishu",
                "peer": {"kind": "group", "id": chat_id}
            }
        }
        bindings.append(binding)
        print(f'  + bound: feishu group {chat_id} -> $AGENT_ID')
    else:
        print(f'  ~ binding exists: {chat_id} (skipped)')
else:
    print('  ~ no FEISHU_CHAT_ID set, skipping group binding')

cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
print('Done')
PYEOF

  print_success "Agent 注册完成"
}

register_agent

# ── Step 3: 创建 Agent 状态目录 ─────────────────────────────────────
create_agent_dirs() {
  print_info "创建 Agent 状态目录 ..."

  local AGENT_DIR="$OC_HOME/agents/$AGENT_ID/agent"
  mkdir -p "$AGENT_DIR"

  # auth-profiles.json
  local AUTH_PROFILES="$AGENT_DIR/auth-profiles.json"
  if [ ! -f "$AUTH_PROFILES" ]; then
    echo '{}' > "$AUTH_PROFILES"
    print_info "  创建: $AUTH_PROFILES"
  else
    print_info "  已存在: $AUTH_PROFILES (跳过)"
  fi

  # models.json
  local MODELS_JSON="$AGENT_DIR/models.json"
  if [ ! -f "$MODELS_JSON" ]; then
    echo '{}' > "$MODELS_JSON"
    print_info "  创建: $MODELS_JSON"
  else
    print_info "  已存在: $MODELS_JSON (跳过)"
  fi

  chmod 600 "$AUTH_PROFILES" "$MODELS_JSON"

  print_success "Agent 状态目录创建完成"
}

create_agent_dirs

# ── Step 4: 安装外部 CLI 工具 (md2wechat) ─────────────────────────────
install_md2wechat() {
  print_info "检查 md2wechat CLI ..."

  # 1. 已在 PATH 中
  if command -v md2wechat &> /dev/null; then
    local version=$(md2wechat version 2>/dev/null || echo "unknown")
    print_success "  md2wechat CLI 已安装 (version: $version)"
    return 0
  fi

  # 2. 已在 ~/bin
  if [ -x "$HOME/bin/md2wechat" ]; then
    print_success "  md2wechat CLI 已安装在 ~/bin"
    print_info "  提示: 确保 ~/bin 在 PATH 中 (export PATH=\"\$HOME/bin:\$PATH\")"
    return 0
  fi

  # 3. 尝试自动安装
  print_info "  md2wechat CLI 未安装，尝试自动安装..."

  if ! command -v go &> /dev/null; then
    print_warning "  未检测到 Go，跳过 md2wechat 自动安装"
    print_info "  请手动安装: brew install go && 重新运行此脚本"
    return 1
  fi

  local go_version=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
  print_info "  检测到 Go $go_version"

  local tmp_dir=$(mktemp -d)
  local repo_dir="$tmp_dir/md2wechat-skill"

  print_info "  克隆 md2wechat-skill 项目..."
  if ! git clone --depth 1 https://github.com/geekjourneyx/md2wechat-skill.git "$repo_dir" 2>/dev/null; then
    print_warning "  GitHub 克隆失败，尝试 Gitee 镜像..."
    if ! git clone --depth 1 https://gitee.com/nieyiyi/md2wechat-skill.git "$repo_dir" 2>/dev/null; then
      print_error "  克隆失败，请检查网络连接"
      rm -rf "$tmp_dir"
      return 1
    fi
  fi

  mkdir -p "$HOME/bin"

  print_info "  编译 md2wechat CLI ..."
  cd "$repo_dir"
  if GOPROXY=https://goproxy.cn,direct go build -o md2wechat ./cmd/md2wechat 2>&1; then
    mv md2wechat "$HOME/bin/"
    chmod +x "$HOME/bin/md2wechat"
    print_success "  md2wechat CLI 安装成功"

    export PATH="$HOME/bin:$PATH"

    # 永久添加到 PATH
    local shell_rc=""
    if [ -f "$HOME/.zshrc" ]; then
      shell_rc="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
      shell_rc="$HOME/.bashrc"
    fi

    if [ -n "$shell_rc" ] && ! grep -q 'export PATH="\$HOME/bin:\$PATH"' "$shell_rc" 2>/dev/null; then
      echo '' >> "$shell_rc"
      echo '# Added by openclaw-content-factory' >> "$shell_rc"
      echo 'export PATH="$HOME/bin:$PATH"' >> "$shell_rc"
      print_info "  已将 ~/bin 添加到 PATH ($shell_rc)"
    fi
  else
    print_error "  编译失败"
    rm -rf "$tmp_dir"
    return 1
  fi

  cd - > /dev/null
  rm -rf "$tmp_dir"
  return 0
}

install_md2wechat

# ── Step 5: 配置 API Keys ─────────────────────────────────────
write_env_key() {
  local env_file="$1"
  local key_name="$2"
  local key_value="$3"

  mkdir -p "$(dirname "$env_file")"
  touch "$env_file"

  if grep -q "^${key_name}=" "$env_file" 2>/dev/null; then
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

configure_api_keys() {
  print_info "配置 API Keys ..."

  local GLOBAL_ENV="$OC_HOME/.env"
  local AUTH_PROFILES="$OC_HOME/agents/$AGENT_ID/agent/auth-profiles.json"
  local SKILLS_DIR="$WORKSPACE_DIR/skills"

  # key名称:描述:存放位置 (global | skill:skill1,skill2)
  local API_KEY_CONFIGS=(
    "TAVILY_API_KEY:Tavily 搜索:global"
    "SILICONFLOW_API_KEY:硅基流动 API:skill:yzfly-douyin-mcp-server-douyin-video,ai-cover-generator"
    "GEMINI_API_KEY:Gemini API:skill:ai-cover-generator"
    "WECHAT_APPID:微信公众号 AppID:skill:md2wechat"
    "WECHAT_SECRET:微信公众号 Secret:skill:md2wechat"
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

      if [ "$key_location" = "global" ]; then
        write_env_key "$GLOBAL_ENV" "$key_name" "$key_value"
        print_info "    -> $GLOBAL_ENV"
      else
        skill_names="${key_location#skill:}"
        IFS=',' read -ra skill_array <<< "$skill_names"
        for skill_name in "${skill_array[@]}"; do
          skill_env_file="$SKILLS_DIR/$skill_name/.env"
          write_env_key "$skill_env_file" "$key_name" "$key_value"
          print_info "    -> $skill_env_file"
        done
      fi
    fi
  done

  if [ $has_keys -eq 1 ]; then
    [ -f "$GLOBAL_ENV" ] && chmod 600 "$GLOBAL_ENV"

    # 更新 auth-profiles.json
    if [ -f "$AUTH_PROFILES" ]; then
      python3 << 'PYEOF'
import json, os
from pathlib import Path

auth_file = Path.home() / ".openclaw" / "agents" / "content" / "agent" / "auth-profiles.json"

try:
    data = json.loads(auth_file.read_text())
except:
    data = {}

if "api_keys" not in data:
    data["api_keys"] = {}

for key_name in ["TAVILY_API_KEY", "SILICONFLOW_API_KEY", "GEMINI_API_KEY", "WECHAT_APPID", "WECHAT_SECRET"]:
    value = os.environ.get(key_name)
    if value:
        data["api_keys"][key_name] = value

auth_file.write_text(json.dumps(data, ensure_ascii=False, indent=2))
print("  auth-profiles.json 已更新")
PYEOF
      print_success "API Keys 配置完成"
    fi
  else
    print_warning "未检测到 API Keys 环境变量"
    echo ""
    echo "  可通过以下方式配置 API Keys:"
    echo ""
    echo "    FEISHU_CHAT_ID=xxx TAVILY_API_KEY=xxx SILICONFLOW_API_KEY=xxx \\"
    echo "    GEMINI_API_KEY=xxx WECHAT_APPID=xxx WECHAT_SECRET=xxx ./install.sh"
    echo ""
    echo "  或安装后编辑对应的 .env 文件"
  fi
}

configure_api_keys

echo ""
print_success "安装完成!"
echo ""
echo "═════════════════════════════════════════════════════════════"
echo ""
echo "  工作空间: $WORKSPACE_DIR"
echo "  Agent 状态: $OC_HOME/agents/$AGENT_ID/agent/"
echo "  Skills: $WORKSPACE_DIR/skills/"
echo ""
print_success "开始使用你的 AI 内容工厂吧!"
echo ""
