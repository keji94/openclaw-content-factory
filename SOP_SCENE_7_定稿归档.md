# 场景7：定稿归档

## 触发条件
用户说「定稿」「完成了」

## 执行步骤

**Step 1: 更新状态**
```json
// 内容写作
{"阶段": "定稿"}

// 素材库
{"状态": "已写作"}
```

**Step 2: 保存定稿快照并触发学习**

1. 从飞书云文档获取最新内容（Markdown 格式）
2. 保存定稿并自动触发差异分析：
```bash
python scripts/observe_final.py \
    --article-id "YYYY-MM-DD_标题关键词" \
    --content "定稿MD内容"
```
> article-id 必须与 Scene 5 保存初稿时一致（根据文章标题重建）
> observe_final.py 会自动链式调用：analyze_diff.py → extract_rules.py → 更新 rules.json

**Step 3: 询问发布**
```
✅ 已标记为定稿！

需要我帮你：
1. 📱 发布到公众号（自动转换+上传草稿）
2. 📁 仅归档到知识库
3. 🎯 发布到公众号 + 归档知识库
4. ⏭️ 直接结束

回复对应数字即可。
```
