---
name: md2wechat
description: "微信公众号文章转换和发布工具。将 Markdown 转换为微信公众号格式的 HTML，上传图片到微信素材库，创建公众号草稿。当用户说「定稿」并选择发布到公众号时触发。"
version: 1.0.0
---

# md2wechat - 微信公众号发布工具

将 Markdown 文章转换为微信公众号格式，上传图片，创建草稿的 CLI 工具集。

## 在内容工厂中的位置

```
素材入库 → 选题推荐 → 大纲生成 → 初稿写作 → 修改定稿 → 📱 发布到公众号
                                                    ↑
                                              你在这里
```

**触发时机**：用户说「定稿」并选择「发布到公众号」时

**前置条件**：
- 飞书云文档中有已完成的文章
- 已配置微信公众号 AppID 和 Secret
- 服务器 IP 已添加到微信公众号白名单

---

## 环境要求

### 系统要求

- Go 1.21+（用于编译）
- 或预编译的 `md2wechat` 二进制文件

### 微信公众号配置

**必需配置**：
- `WECHAT_APPID`: 微信公众号 AppID
- `WECHAT_SECRET`: 微信公众号 AppSecret

获取方式：
1. 登录微信公众平台
2. 设置与开发 > 基本配置
3. 获取 AppID 和 AppSecret

---

## 🚀 安装

### 方式一：自动安装（推荐）

安装内容工厂时，`install.sh` 会自动检测并安装 md2wechat CLI：

```bash
cd /path/to/openclaw-content-factory
./install.sh
```

或者单独运行 skill 的安装脚本：

```bash
cd ~/.openclaw/workspace-content/skills/md2wechat
./install.sh
```

### 方式二：手动安装

```bash
# 1. 克隆项目
git clone https://github.com/geekjourneyx/md2wechat-skill.git
cd md2wechat-skill

# 2. 编译（使用国内代理加速）
GOPROXY=https://goproxy.cn,direct go build -o md2wechat ./cmd/md2wechat

# 3. 安装到 ~/bin
mkdir -p ~/bin
cp md2wechat ~/bin/

# 4. 添加到 PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 5. 验证
md2wechat version
```

### 方式二：下载预编译版本

```bash
# macOS/Linux
curl -L -o md2wechat https://github.com/geekjourneyx/md2wechat-skill/releases/latest/download/md2wechat-$(uname -s)-$(uname -m)
chmod +x md2wechat
```

---

## 📝 配置

### 创建配置文件

```bash
# 在 ~/.config/md2wechat/ 目录创建配置
mkdir -p ~/.config/md2wechat
cat > ~/.config/md2wechat/config.yaml << 'EOF'
wechat:
  appid: your_appid_here
  secret: your_secret_here
EOF
```

### 或使用环境变量

```bash
export WECHAT_APPID="your_appid"
export WECHAT_SECRET="your_secret"
```

---

## 🔧 CLI 命令

### 1. 转换 Markdown 为 HTML

```bash
# AI 模式转换（返回 prompt，需用 AI 生成 HTML）
md2wechat convert article.md --mode ai --theme autumn-warm --json

# 输出示例：
# {
#   "success": true,
#   "code": "CONVERT_AI_REQUEST_READY",
#   "data": {
#     "action": "ai_request",
#     "prompt": "完整的 Claude 提示词...",
#     "images": [...]
#   }
# }
```

**参数说明**：
- `--mode ai`: AI 模式，返回 prompt 供 AI 生成
- `--theme`: 主题名称（autumn-warm, spring-fresh, ocean-calm 等）
- `--json`: JSON 格式输出

---

### 2. 上传图片到微信素材库

```bash
# 上传本地图片
md2wechat upload_image ./cover.jpg --json

# 下载远程图片并上传
md2wechat download_and_upload https://example.com/image.jpg --json

# 输出示例：
# {
#   "success": true,
#   "data": {
#     "media_id": "xxx",
#     "url": "https://..."
#   }
# }
```

---

### 3. 创建草稿

```bash
# 准备 draft.json
cat > draft.json << 'EOF'
{
  "articles": [{
    "title": "文章标题",
    "content": "<p>HTML内容</p>",
    "thumb_media_id": "封面图片media_id",
    "digest": "文章摘要",
    "author": "作者"
  }]
}
EOF

# 创建草稿
md2wechat create_draft draft.json --json

# 输出示例：
# {
#   "success": true,
#   "data": {
#     "media_id": "草稿media_id"
#   }
# }
```

---

## 📋 完整发布流程

AI 在帮助用户发布文章时，按以下流程操作：

### Step 1: 转换 Markdown

```bash
md2wechat convert article.md --mode ai --theme autumn-warm --json
```

解析返回的 JSON，获取 `prompt` 和 `images`。

### Step 2: 使用 prompt 生成 HTML

AI 使用返回的 `prompt` 调用 Claude，生成微信公众号格式的 HTML。

### Step 3: 上传图片

```bash
# 上传文章中的图片
md2wechat upload_image ./image1.jpg --json

# 上传封面图
md2wechat upload_image ./cover.jpg --json
```

### Step 4: 创建草稿

```bash
# 构建 draft.json
cat > draft.json << EOF
{
  "articles": [{
    "title": "文章标题",
    "content": "<!-- 替换图片占位符后的完整 HTML -->",
    "thumb_media_id": "封面图片media_id",
    "digest": "文章摘要"
  }]
}
EOF

# 创建草稿
md2wechat create_draft draft.json --json
```

### Step 5: 通知用户

告知用户草稿已创建，可在微信公众号后台查看和发布。

---

## 🎨 主题说明

| 主题 | 风格 | 适用场景 |
|------|------|---------|
| autumn-warm | 秋日暖阳 | 文艺、生活 |
| spring-fresh | 春日清新 | 科技、资讯 |
| ocean-calm | 海洋宁静 | 专业、商务 |
| custom | 自定义 | 使用 --custom-prompt |

查看所有主题：
```bash
md2wechat themes --json
```

---

## ⚠️ 故障排除

### 配置错误

```
配置错误 [WechatAppID]: 微信公众号 AppID 未配置
```

**解决方案**: 设置环境变量或创建配置文件。

### 图片上传失败

1. 检查图片格式（支持 JPG、PNG）
2. 检查图片大小（最大 10MB）
3. 检查网络连接

### 创建草稿失败

1. 确保 `thumb_media_id` 是有效的封面图片
2. 确保 `content` HTML 格式正确

---

## 📁 目录结构

```
md2wechat/
├── SKILL.md          # 本文档
├── .env.example      # 配置示例
└── install.sh        # 安装脚本
```

---

## 相关链接

- [md2wechat-skill 项目](https://github.com/geekjourneyx/md2wechat-skill)
- [微信公众平台](https://mp.weixin.qq.com/)

---

## License

MIT