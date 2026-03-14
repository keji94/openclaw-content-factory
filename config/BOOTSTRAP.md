# BOOTSTRAP.md · 初始化指南

这是你的"出生证明"。按照以下步骤完成初始化，完成后删除此文件。

---

## 初始化步骤概览

| 步骤     | 内容 | 预计耗时 | 依赖        | 阻塞点 |
|--------|------|----------|-----------|--------|
| Step 1 | 配置主 Agent 权限 | 10秒 | 无         | 无 |
| Step 2 | 绑定群组 | 10秒 | 无         | 无 |
| Step 3 | 安装 Skills | 30秒 | 无         | 无 |
| Step 4 | 安装飞书插件 | 30-60秒 | 无         | 安装后需用户授权 |
| Step 5 | 初始化多维表格 | 30秒 | Step 4 完成 | 需授权后才能执行 |


**执行顺序**：Step 1 → Step 2 → Step 3→ Step 4(等待授权) → Step 5
**强制**：没完成一个初始化步骤，更新初始化进度记录表的状态字段
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

### Step 2: 绑定群组
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

### Step 3: 安装飞书插件
```bash
npx -y @larksuite/openclaw-lark-tools install
```
插件安装完成后，执行下面命令
```
/feishu auth
```
如果需要授权则等待用户完成授权，如果不需要授权则直接跳过

### Step 4: 初始化多维表格
按照 TOOLS.md 配置内容工厂表格（灵感库 + 内容写作两个子表）

### Step 5: 安装 Skills
```bash
clawhub install playwright-scraper
clawhub install tavily-search
clawhub install humanizer-zh
```
如果已安装则忽略

---

## 通知策略（强制执行）

## 进度通知机制
- schedule: "*/20 * * * * *"  # 每20秒（需要 cron 支持秒级）
- action: 检查初始化状态，发送进度记录表的状态到内容工厂群组


### 进度记录表(每完成一个步骤时更新状态)

| 进度     | 状态   |
|--------|------|
| Step 1 | 已完成  |
| Step 2 | 已完成  |
| Step 3 | 阻塞等待 |
| Step 4 | 待执行  |
| Step 4 | 待执行  |

### 通知格式模板

```
📍 初始化进度 [X/5]

✅ 已完成：
- Step 1: XXXX
- Step 2: XXXX

🔄 当前状态：
- Step 4: ⏳ 等待用户授权 (/feishu auth)

⏸️ 阻塞中：
- Step 5: 依赖 Step 4 完成

⏳ 待执行：
- Step 5: 初始化多维表格
```

### 阻塞处理规范

当步骤被阻塞时，通知必须包含：
1. **阻塞原因** - 为什么无法进行
2. **解除条件** - 什么条件满足后可以继续
3. **用户操作** - 需要用户做什么

示例：
```
⏸️ Step 5 阻塞：飞书授权未完成

原因：创建多维表格需要用户授权
解除条件：完成 /feishu auth 授权
需要你：请发送 "/feishu auth" 完成授权
```

---

## 完成标志

当所有步骤执行完毕，发送：
```
🎉 初始化完成！
内容工厂已就绪，可以开始使用了。

📊 最终状态：
✅ Step 1: 主 Agent 权限已配置
✅ Step 2: 群组已绑定 (oc_xxx)
✅ Step 3: Skills 已安装 (3/3)
✅ Step 4: 飞书插件已安装并授权
✅ Step 5: 多维表格已创建

```

然后删除此 BOOTSTRAP.md 文件。
