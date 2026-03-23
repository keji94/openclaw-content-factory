# OpenClaw Content Factory 🏭

> AI 内容工厂 1.1

## 🎯 这是什么？

这是一个基于 OpenClaw 的内容生产 Agent，让飞书成为你的内容运转中心。

### 核心流程

```
素材入库 → 选题推荐 → 大纲生成 → 初稿写作 → 修改定稿 → 归档发布
```

### 功能模块

| 阶段 | 功能 | 说明 |
|------|------|------|
| 素材入库 | 链接解析、内容抓取、逐字稿提取 | 转发链接给 AI，自动抓取内容并存入素材库 |
| 选题推荐 | 素材拆解、选题生成、优先级排序 | AI 从素材库推荐值得写的选题 |
| 内容写作 | 大纲生成、初稿撰写、云文档创建 | 选定选题后，AI 自动创建大纲和初稿 |
| 归档发布 | 定稿确认、知识库归档 | 完成后自动归档，形成知识沉淀 |

### 核心理念

**你负责扔素材和做决定，AI 负责执行和产出。**

- 📥 收到好内容 → 转发给 AI → 自动入库并拆解选题
- 📤 想写东西 → 问 AI 推荐 → 从选题库挑选
- ✍️ 确定选题 → AI 出大纲 → 确认后写初稿 → 创建云文档
- ✅ 人工改稿 → 告诉 AI 定稿 → 自动归档知识库

---

## 🚀 安装方式

### 方式一：手动安装（推荐）

#### Step 1: 安装飞书官方插件
登录你的服务器输入下面命令：
```bash
npx -y @larksuite/openclaw-lark-tools install
```

安装完成后在飞书给机器人私聊，发送：
```
/feishu auth
```

按提示完成飞书授权。

#### Step 2: 创建飞书群组并获取 Chat ID

1. 在飞书新建一个群组（名称随意，如「内容工厂」）
2. 添加你的 OpenClaw 机器人到群组
3. 获取群组 Chat ID：
   - 点击群组设置 → 群公告/群信息

> 💡 Chat ID 用于绑定 Agent 到指定群组，安装时可通过 `FEISHU_CHAT_ID` 环境变量传入，也可安装后手动配置。

#### Step 3: 获取 API Keys

根据需要获取以下 API Keys：

| API Key | 用途 | 获取地址 |
|---------|------|----------|
| `TAVILY_API_KEY` | Tavily 搜索 | https://tavily.com |
| `SILICONFLOW_API_KEY` | 硅基流动（抖音文案提取） | https://cloud.siliconflow.cn |

> 💡 API Keys 为可选配置，也可安装后在对应 `.env` 文件中手动配置。

#### Step 4: 克隆项目并安装

```bash
# 克隆项目
git clone https://gitee.com/nieyiyi/openclaw-content-factory.git
cd openclaw-content-factory

# 配置环境变量并执行安装
TAVILY_API_KEY=<第三步获取的key> SILICONFLOW_API_KEY=<第三步获取的key> FEISHU_CHAT_ID=<第三步获取的chatId> ./install.sh
```

**环境变量说明**：

| 环境变量 | 必需 | 说明 |
|---------|------|------|
| `TAVILY_API_KEY` | 可选 | Tavily 搜索 |
| `SILICONFLOW_API_KEY` | 可选 | 硅基流动 API |
| `FEISHU_CHAT_ID` | 可选 | 飞书群组 ID，格式如 `oc_xxx` |

#### Step 5: 初始化配置

在飞书群组中发送以下消息，让 AI 完成初始化：

```
请按照 ~/.openclaw/workspace-content/BOOTSTRAP.md 完成初始化。
注意：部分步骤可能已通过手动安装完成，请先检查再执行。
```

AI 会自动检测已完成的步骤并跳过，只执行必要的初始化操作（主要是创建多维表格）。

---

### 方式二：自动安装

让 AI Agent 帮你执行安装：

#### 1. 在飞书新建群组
创建一个名为「内容工厂」的群组，添加你的 OpenClaw 机器人。

#### 2. 将下面这一段内容复制后发送给内容工厂

```

请你按照下面步骤完成本群组的配置
# 1.克隆项目
```
    git clone https://gitee.com/nieyiyi/openclaw-content-factory.git
    cd openclaw-content-factory
```
完成后通知进度
# 2.执行脚本
chmod +x install.sh && ./install.sh
完成后通知进度
# 3.按照 openclaw-content-factory/config/BOOTSTRAP.md 进行初始化

```

#### 3. 重启 gateway
在内容工厂群发送消息：`请你重启 Gateway`

---

## 📁 安装后的目录结构

```
~/.openclaw/
├── openclaw.json                    # Agent 注册配置
├── .env                             # 全局 API Keys
├── workspace-content/               # 内容工厂工作目录
│   ├── AGENTS.md                    # 核心规则
│   ├── SOUL.md                      # 角色定位
│   ├── USER.md                      # 用户档案
│   ├── TOOLS.md                     # 工具配置
│   ├── SOP_CONTENT.md               # 内容生产 SOP
│   ├── HEARTBEAT.md                 # 定时任务
│   ├── MEMORY.md                    # 长期记忆
│   ├── BOOTSTRAP.md                 # 初始化指南
│   ├── memory/                      # 每日日记
│   └── skills/                      # Skills 目录
│       ├── humanizer-zh/            # 中文人性化改写
│       ├── openclaw-tavily-search/  # Tavily 搜索
│       ├── playwright-scraper-skill/# 网页抓取
│       └── yzfly-douyin-mcp-server-douyin-video/  # 抖音视频处理
│           └── .env                 # Skill 专属 API Key
└── agents/
    └── content/
        └── agent/
            ├── auth-profiles.json   # Agent 认证配置
            └── models.json           # Agent 模型配置
```

---

## 🔧 日常使用

### 更新配置
```bash
cd openclaw-content-factory
./update.sh
```

### 卸载内容工厂
```bash
./uninstall.sh
```

---

## 📊 工作流程

```
刷到好内容 → 转给 AI → 存进素材库 + 打标签 + 拆选题
     ↓
想写东西时 → 问 AI 推荐 → AI 从素材库给选题
     ↓
选定选题 → AI 建档 → 出大纲 → 生成初稿 → 创建云文档
     ↓
链接回填表格 → 人工改稿 → 告诉 AI 定稿 → 归档进知识库
```

---

## 🔗 相关链接

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- 关注我的公众号获取更多信息：**拾疑**

## 📝 License

MIT

---
