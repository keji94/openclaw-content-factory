#!/bin/bash

# ============================================
# md2wechat Skill 安装脚本
# 自动安装 md2wechat CLI
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

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 读取根目录的 .env 文件（如果存在）
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -f "$PROJECT_ROOT/.env" ]; then
    print_info "读取配置文件: $PROJECT_ROOT/.env"
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       📝 md2wechat Skill 安装程序                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 确保 ~/bin 存在
mkdir -p "$HOME/bin"

# ── 安装 md2wechat CLI ─────────────────────────────────
install_md2wechat() {
    # 1. 检查是否已在 PATH 中
    if command -v md2wechat &> /dev/null; then
        local version=$(md2wechat version 2>/dev/null || echo "unknown")
        print_success "md2wechat CLI 已安装 (version: $version)"
        return 0
    fi

    # 2. 检查 ~/bin/md2wechat 是否存在
    if [ -x "$HOME/bin/md2wechat" ]; then
        print_success "md2wechat CLI 已安装在 ~/bin"
        export PATH="$HOME/bin:$PATH"
        return 0
    fi

    # 3. 需要安装
    print_info "md2wechat CLI 未安装，尝试自动安装..."

    # 检查 Go
    if ! command -v go &> /dev/null; then
        print_warning "未检测到 Go"
        echo ""
        echo "  请先安装 Go："
        echo "    macOS: brew install go"
        echo "    Linux: 参考 https://go.dev/doc/install"
        echo ""
        echo "  然后重新运行此脚本"
        return 1
    fi

    # Go 版本
    local go_version=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
    print_info "检测到 Go $go_version"

    # 创建临时目录
    local tmp_dir=$(mktemp -d)
    local repo_dir="$tmp_dir/md2wechat-skill"

    # 克隆项目
    print_info "克隆 md2wechat-skill 项目..."
    if ! git clone --depth 1 https://github.com/geekjourneyx/md2wechat-skill.git "$repo_dir" 2>/dev/null; then
        print_warning "GitHub 克隆失败，尝试 Gitee 镜像..."
        if ! git clone --depth 1 https://gitee.com/nieyiyi/md2wechat-skill.git "$repo_dir" 2>/dev/null; then
            print_error "克隆失败，请检查网络连接"
            rm -rf "$tmp_dir"
            return 1
        fi
    fi

    # 编译
    print_info "编译 md2wechat CLI..."
    cd "$repo_dir"

    if GOPROXY=https://goproxy.cn,direct go build -o md2wechat ./cmd/md2wechat 2>&1; then
        # 安装到 ~/bin
        mv md2wechat "$HOME/bin/"
        chmod +x "$HOME/bin/md2wechat"

        print_success "md2wechat CLI 安装成功！"

        # 添加到 PATH
        export PATH="$HOME/bin:$PATH"

        # 永久添加到 PATH
        local shell_rc=""
        if [ -n "$ZSH_VERSION" ]; then
            shell_rc="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ]; then
            shell_rc="$HOME/.bashrc"
        fi

        if [ -n "$shell_rc" ] && ! grep -q 'export PATH="\$HOME/bin:\$PATH"' "$shell_rc" 2>/dev/null; then
            echo '' >> "$shell_rc"
            echo '# Added by md2wechat skill' >> "$shell_rc"
            echo 'export PATH="$HOME/bin:$PATH"' >> "$shell_rc"
            print_info "已将 ~/bin 添加到 $shell_rc"
        fi
    else
        print_error "编译失败"
        cd - > /dev/null
        rm -rf "$tmp_dir"
        return 1
    fi

    # 清理
    cd - > /dev/null
    rm -rf "$tmp_dir"
    return 0
}

# ── 创建配置文件 ─────────────────────────────────
create_config() {
    print_info "配置 Skill..."

    local ENV_FILE="$SCRIPT_DIR/.env"

    # 如果环境变量中有配置，写入到 skill 目录
    if [ -n "$WECHAT_APPID" ] || [ -n "$WECHAT_SECRET" ]; then
        mkdir -p "$(dirname "$ENV_FILE")"
        cat > "$ENV_FILE" << EOF
# 微信公众号配置
WECHAT_APPID=${WECHAT_APPID:-}
WECHAT_SECRET=${WECHAT_SECRET:-}
EOF
        chmod 600 "$ENV_FILE"
        print_success "已写入微信配置到 $ENV_FILE"
    else
        print_info "未检测到微信配置，跳过"
        print_info "可在根目录 .env 中配置 WECHAT_APPID 和 WECHAT_SECRET"
    fi
}

# ── 验证安装 ─────────────────────────────────
verify_installation() {
    print_info "验证安装..."

    # 确保 PATH 包含 ~/bin
    export PATH="$HOME/bin:$PATH"

    if command -v md2wechat &> /dev/null; then
        local version=$(md2wechat version 2>/dev/null || echo "unknown")
        print_success "md2wechat CLI 可用 (version: $version)"
        return 0
    else
        print_error "md2wechat CLI 不可用"
        return 1
    fi
}

# ── 主流程 ─────────────────────────────────
main() {
    install_md2wechat
    create_config

    if verify_installation; then
        echo ""
        print_success "✅ 安装完成!"
        echo ""
        echo "═════════════════════════════════════════════════════════════"
        echo ""
        echo "📁 配置说明:"
        echo ""
        echo "微信公众号配置在项目根目录的 .env 文件中:"
        echo "   WECHAT_APPID=你的AppID"
        echo "   WECHAT_SECRET=你的AppSecret"
        echo ""
        echo "如果 PATH 未生效，运行:"
        echo "   source ~/.zshrc"
        echo ""
        echo "在内容工厂中使用:"
        echo "   告诉 AI: \"帮我把这篇 Markdown 发布到公众号\""
        echo ""
        echo "═════════════════════════════════════════════════════════════"
    else
        echo ""
        print_warning "安装未完成，请检查错误信息"
    fi
}

# 执行主流程
main