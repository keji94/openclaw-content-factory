# BOOTSTRAP.md · 初始化指南

这是你的"出生证明"。按照以下步骤完成初始化，完成后删除此文件。

---

## 初始化步骤概览

| 步骤 | 内容 | 检查方式 | 手动安装可能已跳过 |
|------|------|----------|-------------------|
| Step 1 | 绑定群组 | 检查 bindings 是否已存在 content 绑定 | ✅ 可能已通过 FEISHU_CHAT_ID 配置 |
| Step 2 | 安装飞书插件 | 检查插件是否已安装 | ✅ 可能已手动安装 |
| Step 3 | 初始化多维表格 | 调用 feishu_bitable_app list 检查飞书现有表格 | ✅ 可能已有现成表格 |
| Step 4 | 验证 API Keys | 检查 .env 文件 | ✅ 可能已配置 |

**执行原则**：每步先检查是否已完成，已完成的跳过。

---

## 初始化步骤

### Step 1: 检查并绑定群组

**检查**：读取 `~/.openclaw/openclaw.json`，检查 `bindings` 中是否已有 `agentId=content` 的绑定。

**如果未绑定**：
绑定当前群组到 agentId=content，配置格式：
```json
{
  "agentId": "content",
  "match": {
    "channel": "feishu",
    "peer": { "kind": "group", "id": "{chatId}" }
  }
}
```

**如果已绑定**：跳过，输出 `✅ Step 1: 群组已绑定`

---

### Step 2: 检查飞书插件

**检查**：执行 `/feishu auth` 测试是否已授权。

**如果未安装/未授权**：
```bash
npx -y @larksuite/openclaw-lark-tools install
```
然后执行 `/feishu auth` 完成授权。

**如果已授权**：跳过，输出 `✅ Step 2: 飞书插件已安装并授权`

---

### Step 3: 检查并初始化多维表格

**检查**：调用 `feishu_bitable_app`（action: `list`）列出用户飞书上的所有多维表格，按名称匹配是否有包含「内容工厂」「素材库」「内容写作」等关键词的现成表格。

**如果找到现成表格**：
向用户展示找到的表格列表，请用户确认要使用哪一个：
- 用户确认后，获取该表格的 Table 列表（`feishu_bitable_app_table`），找到或创建素材库和内容写作两个子表
- 验证字段结构是否符合 TOOLS.md 定义（`feishu_bitable_app_table_field.list`），缺失的字段补创建
- 将 App Token、Table ID 回填到 TOOLS.md
- 输出 `✅ Step 3: 复用现有多维表格（{表格名}）`

**如果没有找到合适的现成表格**：
按照 TOOLS.md 从零创建：
- 创建多维表格，获取 App Token
- 创建素材库子表，获取 Table ID
- 创建内容写作子表，获取 Table ID
- 按照字段定义配置各子表的字段结构
- 将获取到的 App Token、Table ID 回填到 TOOLS.md

---

### Step 4: 验证 API Keys

**检查**：
- `~/.openclaw/.env` 中的 `TAVILY_API_KEY`
- `~/.openclaw/workspace-content/skills/yzfly-douyin-mcp-server-douyin-video/.env` 中的 `SILICONFLOW_API_KEY`

**如果缺失**：提醒用户手动配置。

**如果已配置**：输出 `✅ Step 4: API Keys 已配置`

---

## 完成标志

当所有步骤执行完毕，发送：

```
🎉 初始化完成！
内容工厂已就绪，可以开始使用了。

📊 最终状态：
✅ Step 1: 群组已绑定
✅ Step 2: 飞书插件已授权
✅ Step 3: 多维表格已就绪
✅ Step 4: API Keys 已配置

📝 接下来你可以：
- 发送链接，自动入库素材
- 说「推荐选题」，获取选题建议
- 说「选X」，开始写作流程
```

然后删除此 BOOTSTRAP.md 文件。
