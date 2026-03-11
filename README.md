# OpenClaw Content Factory 🏭

> AI 内容工厂 2.0 — 让飞书成为你的内容运转中心

## 🎯 这是什么？

一套 OpenClaw 配置文件模板，帮你快速搭建：

- **灵感库**：刷到好内容，转给 AI 就自动存进去
- **选题推荐**：AI 从灵感库推荐选题
- **内容写作**：选定选题，AI 自动创建大纲、初稿、云文档
- **知识库归档**：定稿后自动归档到知识库

**核心理念**：你负责扔素材和做决定，其他全部交给 AI。

## 🚀 快速安装

```bash
# 克隆项目
git clone https://github.com/nieyi6/openclaw-content-factory.git
cd openclaw-content-factory

# 一键安装
chmod +x install.sh && ./install.sh
```

## 📁 项目结构

```
~/.openclaw/workspace/
├── AGENTS.md          # 核心规则：启动顺序、安全边界、通信风格
├── SOUL.md            # 角色定位：助手是谁、怎么做事
├── USER.md            # 用户档案：你的创作风格和偏好
├── TOOLS.md           # 工具配置：飞书 Skills 和多维表格结构
├── SOP_CONTENT.md     # 内容生产 SOP：6个阶段的标准流程
├── HEARTBEAT.md       # 定时任务：每日、每周自动运行
├── MEMORY.md          # 长期记忆模板：用后自动填充
└── memory/            # 每日日记目录（自动生成）
    └── YYYY-MM-DD.md
```

## 🔧 使用方式

### 1. 初始化多维表格

```
帮我按照 TOOLS.md 里灵感库子表的字段定义，
在我的飞书多维表格（App Token：[你的AppToken]）里新建一个名为「灵感库」的子表，
包含所有字段和单选项的完整选项值。
建完告诉我每个字段的名称和类型。
```

### 2. 验证配置

```
我刚刚给你发了一套配置文件，请现在按顺序读取以下文件并确认加载成功：
AGENTS.md / SOUL.md / USER.md / TOOLS.md / SOP_CONTENT.md / HEARTBEAT.md / MEMORY.md

读完之后告诉我：
1. 你现在的角色是什么
2. 你能操作哪些飞书功能
3. 内容生产流程有几个阶段，分别叫什么
```

### 3. 开始使用

- **存灵感**：发送链接给 AI，它会自动存入灵感库
- **推荐选题**：发送「推荐选题」
- **开始写作**：发送「写一篇关于XX的文章」
- **定稿归档**：发送「定稿」

## 📊 工作流程

```
刷到好内容 → 转给 AI → 存进灵感库 + 打标签 + 拆选题
     ↓
想写东西时 → 问 AI 推荐 → AI 从灵感库给选题
     ↓
选定选题 → AI 建档 → 出大纲 → 生成初稿 → 创建云文档
     ↓
链接回填表格 → 人工改稿 → 告诉 AI 定稿 → 归档进知识库
```

## 🔗 相关链接

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [ArkClaw 入口](https://v2ig.cn/cRm03IcFyUU/)
- [原作者文章](https://mp.weixin.qq.com/s/aY3CDZ33ufjKfLwCiuYI-Q)

## 📝 License

MIT

---

*基于「饼干哥哥」的 AI 内容工厂 2.0 方案整理*
