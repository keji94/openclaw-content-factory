# BOOTSTRAP.md · 初始化指南

这是你的"出生证明"。按照以下步骤完成初始化，完成后删除此文件。

---

## 初始化步骤

### Step 1: 配置主 Agent 权限
修改 `~/.openclaw/agents/main/agent/tools.json`，添加：
```json
{
  "exec": { "allow": true },
  "browser": { "allow": true },
  "message": { "allow": true }
}
```

### Step 2: 克隆项目
```bash
git clone https://gitee.com/nieyiyi/openclaw-content-factory.git
cd openclaw-content-factory
```

### Step 3: 执行安装脚本
```bash
chmod +x install.sh && ./install.sh
```

### Step 4: 绑定群组
绑定当前群组到 agentId=content，workspace=workspace-content
配置格式：
```json
{
  "agentId": "content",
  "match": {
    "channel": "feishu",
    "peer": { "kind": "group", "id": "{chatId}" }
  }
}
```

### Step 5: 安装飞书插件
```bash
npx -y @larksuite/openclaw-lark-tools install
```
插件安装完成后，执行下面命令，等待用户完成授权
```
/feishu auth
```

### Step 6: 初始化多维表格
按照 TOOLS.md 配置内容工厂表格（灵感库 + 内容写作两个子表）

### Step 7: 安装 Skills
```bash
clawhub install playwright-scraper
clawhub install tavily-search
clawhub install humanizer-zh
```
如果已安装则忽略

---

## 进度通知机制

- schedule: "*/20 * * * * *"  # 每20秒（需要 cron 支持秒级）
- action: 检查初始化状态，发送进度更新到内容工厂群组

**重要**：执行初始化时，必须主动向用户汇报进度。

### 汇报方式
- 每完成一个 Step，立即发送消息通知用户
- 如果某个步骤耗时较长（超过30秒），中途发送"正在执行..."的更新
- 使用 `message` 工具发送进度通知到当前群组

### 汇报格式
```
📍 初始化进度 [Step X/Y]
✅ 已完成：XXXX
🔄 进行中：XXXX
⏳ 待执行：XXXX
```

---

## 完成标志

当所有步骤执行完毕，发送：
```
🎉 初始化完成！
内容工厂已就绪，可以开始使用了。
```

然后删除此 BOOTSTRAP.md 文件。
