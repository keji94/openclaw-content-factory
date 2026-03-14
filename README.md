# OpenClaw Content Factory 🏭

> AI 内容工厂 1.0 — 让飞书成为你的内容运转中心

## 🎯 这是什么？

一套 OpenClaw 配置文件模板，帮你快速搭建：

- **素材库**：刷到好内容，转给 AI 就自动存进去
- **选题推荐**：AI 从素材库推荐选题
- **内容写作**：选定选题，AI 自动创建大纲、初稿、云文档
- **知识库归档**：定稿后自动归档到知识库

**核心理念**：你负责扔素材和做决定，其他全部交给 AI。

## 🚀 快速安装

### 1.在飞书新建一个群组--内容工厂。
在群里添加你的 OpenClaw 机器人
### 2.将下面这一段内容复制后发送给内容工厂

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

### 3.重启 gateway
在内容工厂群发送消息：请你重启 Gateway

## 📁 项目结构

```
~/.openclaw/workspace-content/
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

## 如何更新内容工厂的配置
执行 update.sh

## 如何卸载内容工厂
执行 uninstall.sh

## 🔗 相关链接

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- 关注我的公众号获取更多信息：**拾疑**

## 📝 License

MIT

---
