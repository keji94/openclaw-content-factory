# 自我学习写作改进系统

## 系统概述

一个可复用、可移植的写作风格学习系统，通过对比"初稿-定稿"的差异，自动提取并积累写作规则，让 AI 的写作越来越像用户。

---

## 核心流程

```
AI写初稿 → 保存初稿MD → 用户修改定稿 → 保存定稿MD
    ↓
差异分析 → 提取规则模式 → 置信度评分 → 规则分级
    ↓
P0规则（5次以上） → 人工审核 → 写入WRITING_RULES.md
P1规则（2-4次） → 归档待观察
P2规则（1次）    → 记录但不应用
```

---

## 目录结构

```
config/
├── WRITING_IMPROVEMENT_SYSTEM.md     # 本文档
├── WRITING_RULES.md                   # 积累的写作规则（P0规则库）
├── writing-rules/                      # 规则数据和候选
│   ├── rules.json                      # 所有规则的数据库
│   ├── candidates/                     # 候选规则（待审核）
│   │   ├── 2026-03-26_rule_001.json
│   │   └── 2026-03-26_rule_002.json
│   └── stats.json                      # 规则统计信息
└── scripts/                            # 核心脚本
    ├── observe_draft.py                # 记录初稿
    ├── observe_final.py                # 记录定稿
    ├── analyze_diff.py                 # 分析差异
    ├── extract_rules.py                # 提取规则
    ├── review_rules.py                 # 审核规则
    └── apply_rules.py                  # 应用规则

workspace-content/
└── writing-improvement/                # 学习数据（不纳入版本控制）
    ├── drafts/                         # 初稿存档
    │   └── 2026-03-26_001_original.md
    ├── finals/                         # 定稿存档
    │   └── 2026-03-26_001_final.md
    └── diffs/                          # 差异报告
        └── 2026-03-26_001_diff.md
```

---

## 规则分类体系

### P0 规则（高频规则 - 确认后应用）
- **出现次数**：≥ 5 次
- **置信度**：高（≥ 80%）
- **状态**：人工审核通过
- **应用**：自动应用到所有写作
- **示例**：
  - "避免使用'综上所述'等AI痕迹词汇"
  - "标题使用数字型：[数量]个[场景][形容词]"
  - "开头必须有痛点或问题引入"

### P1 规则（中频规则 - 观察中）
- **出现次数**：2-4 次
- **置信度**：中（50-79%）
- **状态**：归档观察
- **应用**：暂不自动应用
- **示例**：
  - "技术文章增加实战案例"
  - "结尾增加行动号召"

### P2 规则（低频规则 - 记录）
- **出现次数**：1 次
- **置信度**：低（< 50%）
- **状态**：仅记录
- **应用**：不自动应用
- **示例**：
  - "某篇文章的特殊结构调整"
  - "一次性修改（可能是偶然）"

---

## 规则数据结构

### rules.json
```json
{
  "version": "1.0",
  "lastUpdated": "2026-03-26T20:00:00Z",
  "statistics": {
    "totalRules": 48,
    "p0Rules": 12,
    "p1Rules": 18,
    "p2Rules": 18,
    "totalArticles": 25
  },
  "rules": [
    {
      "id": "rule_001",
      "category": "标题",
      "pattern": "标题使用数字型公式",
      "description": "避免使用模糊标题，使用具体数字增强吸引力",
      "positiveExample": "5个方法让你快速提升写作效率",
      "negativeExample": "提升写作效率的方法",
      "occurrenceCount": 8,
      "confidence": 85,
      "level": "P0",
      "status": "approved",
      "firstSeen": "2026-03-20",
      "lastSeen": "2026-03-26",
      "sourceArticles": ["article_001", "article_005", "article_008"]
    }
  ]
}
```

### candidate rule JSON
```json
{
  "id": "2026-03-26_rule_001",
  "category": "语言风格",
  "pattern": "替换AI痕迹词汇",
  "description": "避免使用'综上所述、不难看出、由此可见'等词汇",
  "changes": [
    {
      "original": "综上所述，掌握这个技巧很重要",
      "improved": "所以，掌握这个技巧能帮你少走弯路"
    }
  ],
  "occurrenceCount": 1,
  "confidence": 75,
  "suggestedLevel": "P0",
  "status": "pending_review",
  "extractedAt": "2026-03-26T20:00:00Z",
  "articleId": "2026-03-26_001"
}
```

---

## 核心脚本说明

### 1. observe_draft.py - 记录初稿
```bash
# 使用场景：初稿写作完成后自动触发
python scripts/observe_draft.py \
  --article-id "2026-03-26_001" \
  --title "文章标题" \
  --source "feishu_doc_url" \
  --content "初稿内容MD"
```

**功能**：
- 保存初稿到 `workspace-content/writing-improvement/drafts/`
- 记录元数据（时间、标题、来源）
- 生成唯一文章ID

### 2. observe_final.py - 记录定稿
```bash
# 使用场景：定稿确认后自动触发
python scripts/observe_final.py \
  --article-id "2026-03-26_001" \
  --content "定稿内容MD"
```

**功能**：
- 保存定稿到 `workspace-content/writing-improvement/finals/`
- 触发差异分析

### 3. analyze_diff.py - 分析差异
```bash
# 自动触发（由 observe_final.py 调用）
python scripts/analyze_diff.py \
  --article-id "2026-03-26_001"
```

**功能**：
- 对比初稿和定稿
- 生成差异报告
- 提取变更模式

### 4. extract_rules.py - 提取规则
```bash
# 自动触发（由 analyze_diff.py 调用）
python scripts/extract_rules.py \
  --article-id "2026-03-26_001" \
  --auto-level
```

**功能**：
- 从差异中提取规则模式
- 计算置信度
- 更新规则出现次数
- 分级规则（P0/P1/P2）
- 生成候选规则文件

### 5. review_rules.py - 审核规则
```bash
# 手动执行：审核候选规则
python scripts/review_rules.py \
  --level P0 \
  --interactive
```

**功能**：
- 展示待审核规则
- 交互式确认/拒绝/修改
- 将确认的P0规则写入 WRITING_RULES.md
- 更新 rules.json

### 6. apply_rules.py - 应用规则
```bash
# 写作时自动调用
python scripts/apply_rules.py \
  --rules ./config/writing-rules/rules.json \
  --content "待优化内容"
```

**功能**：
- 加载已批准的P0规则
- 检查内容是否符合规则
- 提供改进建议

---

## 集成到现有流程

### 在 SOP_CONTENT.md 中集成

#### 场景4：初稿写作（修改）
在 Step 5 后增加：
```markdown
**Step 5.5: 记录初稿（用于学习）**
```bash
python config/scripts/observe_draft.py \
  --article-id "{文章ID}" \
  --title "{标题}" \
  --source "{云文档链接}" \
  --content "{初稿MD内容}"
```
```

#### 场景7：定稿归档（修改）
在 Step 1 后增加：
```markdown
**Step 1.5: 记录定稿并触发学习**
```bash
python config/scripts/observe_final.py \
  --article-id "{文章ID}" \
  --content "{定稿MD内容}"
```

系统会自动：
1. 保存定稿
2. 对比初稿和定稿
3. 提取规则候选
4. 更新规则统计
```
```

---

## 规则应用机制

### 在场景4（初稿写作）中应用规则

**Step 2.5: 应用已学习的写作规则**
```python
# 伪代码
def apply_learned_rules(draft_content, article_type):
    """应用已学习的P0规则"""
    rules = load_approved_rules()

    suggestions = []
    for rule in rules:
        if rule['level'] == 'P0' and rule['status'] == 'approved':
            # 检查是否符合规则
            if not check_rule(draft_content, rule):
                suggestion = apply_rule(draft_content, rule)
                suggestions.append(suggestion)

    return suggestions
```

### 在场景6（润色打磨）中应用规则

增加规则检查步骤：
```markdown
**Step 1.5: 应用学习到的写作规则**
- 加载 WRITING_RULES.md 中的P0规则
- 检查初稿是否符合规则
- 自动应用高置信度规则
- 生成规则应用报告
```

---

## 规则示例（WRITING_RULES.md）

```markdown
# 写作规则库

## P0 规则（已确认 - 自动应用）

### 标题类

#### Rule-001: 标题使用数字型公式
- **模式**: `[数量]个[场景][形容词]`
- **置信度**: 85%
- **出现次数**: 8次
- **示例**:
  - ✅ "5个方法让你快速提升写作效率"
  - ❌ "提升写作效率的方法"
- **应用**: 所有文章标题

#### Rule-002: 技术类标题突出价值
- **模式**: 使用"真香、贼、搞定"等口语化词汇
- **置信度**: 82%
- **出现次数**: 6次
- **应用**: 技术工具分享类文章

### 语言类

#### Rule-003: 避免AI痕迹词汇
- **禁止词汇**: 综上所述、不难看出、由此可见、显而易见
- **替换为**: 所以、可以看到、其实、很明显
- **置信度**: 90%
- **出现次数**: 12次
- **应用**: 所有文章

#### Rule-004: 短句节奏
- **规则**: 每句15-20字，避免长句
- **置信度**: 78%
- **出现次数**: 5次
- **应用**: 所有文章

### 结构类

#### Rule-005: 开头痛点引入
- **规则**: 前3-5行必须提出痛点或问题
- **置信度**: 88%
- **出现次数**: 7次
- **应用**: 教程类文章

#### Rule-006: 结尾行动号召
- **规则**: 必须包含"点赞、在看、评论"引导
- **置信度**: 75%
- **出现次数**: 6次
- **应用**: 公众号文章

## P1 规则（观察中 - 暂不自动应用）

- Rule-101: 技术文章增加实战案例（3次）
- Rule-102: 使用emoji增加亲和力（4次）
- Rule-103: 代码块前加使用场景说明（2次）

## P2 规则（记录中 - 不应用）

- Rule-201: 某篇文章的特殊结构调整（1次）
- Rule-202: 临时改用的写作风格（1次）
```

---

## 自动化任务

### 每日自动规则提取（Cron Job）

```bash
# 每晚23:00自动运行规则提取
0 23 * * * cd /path/to/project && python3 config/scripts/extract_rules.py --auto-level
```

**功能**：
- 扫描所有未分析的定稿
- 批量提取规则
- 更新规则统计
- 生成日报

---

## 安全机制

### 1. 核心安全规则必须手写
```markdown
**禁止自动学习的领域**：
- 权限边界
- 密钥保护
- 破坏性命令
- 敏感信息处理
- 法律合规要求
```

### 2. 规则审核机制
- 所有 P0 规则必须人工审核
- 拒绝偶然性修改（如临时改的缩进）
- 检查规则冲突

### 3. 规则回滚
```bash
# 如果某个规则导致问题，可以禁用
python scripts/review_rules.py --disable rule_001
```

### 4. 规则版本控制
- rules.json 纳入版本控制
- WRITING_RULES.md 纳入版本控制
- 候选规则定期归档

---

## 效果评估

### 指标
```json
{
  "metrics": {
    "规则总数": 48,
    "P0规则": 12,
    "人工修改率": {
      "初期": "60%",
      "现在": "30%",
      "下降": "50%"
    },
    "写作一致性": {
      "风格相似度": "85%",
      "用户满意度": "90%"
    }
  }
}
```

### 预期效果
- 写作效率提升 40%
- 人工修改次数减少 50%
- 写作风格一致性达到 85%
- AI 越来越像用户

---

## 使用流程

### 第一次使用
1. 确保目录结构存在
2. 初始化规则数据库：`python scripts/extract_rules.py --init`
3. 开始正常写作流程
4. 系统自动记录和学习

### 日常使用
1. **正常写作**：按 SOP 流程写作
2. **自动记录**：系统自动保存初稿和定稿
3. **自动分析**：系统自动提取规则
4. **定期审核**：每周审核一次候选规则
5. **持续改进**：规则越积累越多，写作越来越好

### 审核规则
```bash
# 每周执行一次
python scripts/review_rules.py --level P0 --interactive

# 查看统计
python scripts/review_rules.py --stats
```

---

## 可移植性

### 独立性设计
- ✅ 不依赖飞书（可以从任意来源获取内容）
- ✅ 规则格式通用（JSON + Markdown）
- ✅ 脚本语言无关（Python实现，但规则可跨语言）
- ✅ 可以独立运行

### 导出和导入
```bash
# 导出规则
python scripts/review_rules.py --export rules_backup.json

# 导入规则
python scripts/review_rules.py --import rules_backup.json
```

### 跨项目复用
```bash
# 将规则复制到另一个项目
cp -r config/writing-rules/ /path/to/other/project/config/
```

---

## 注意事项

### 1. 不要期待魔法
- 自动学习不是万能的
- 需要持续积累（建议至少 20 篇文章）
- 人工审核必须执行

### 2. 避免过拟合
- 不要让 AI 写作过于机械化
- 保持创新和变化的空间
- 定期清理低质量规则

### 3. 规则维护
- 定期检查规则有效性
- 删除过时规则
- 合并相似规则

### 4. 隐私保护
- `workspace-content/writing-improvement/` 不纳入版本控制
- 敏感内容自动脱敏
- 定期清理旧数据

---

## 进阶功能（可选）

### 1. 规则A/B测试
```bash
# 测试新规则是否有效
python scripts/apply_rules.py --test --rule candidate_rule_001
```

### 2. 规则推荐系统
- 根据文章类型推荐规则
- 规则权重动态调整

### 3. 规则可视化
- 规则应用情况图表
- 写作改进趋势分析

### 4. 协作学习
- 多用户共享规则库
- 规则市场（购买/售卖规则）

---

## 总结

这个自我学习系统的核心价值：
1. **越用越好**：积累越多，写作越像用户
2. **自动化**：减少人工干预
3. **可复用**：规则可以跨项目使用
4. **可控制**：人工审核保证质量
5. **可移植**：不依赖特定平台

**关键**：坚持使用，持续积累，定期审核。

---

## 快速开始指南

### 第一步：初始化系统（已完成）

```bash
cd D:\develop\ideaProjects\openclaw-content-factory-gitee
python config/scripts/extract_rules.py --init
```

输出：
```
✅ 规则数据库初始化完成
📁 配置目录: D:\...\config\writing-rules
📁 工作目录: D:\...\workspace-content\writing-improvement
```

### 第二步：开始正常写作

按照 `workspace-content/SOP_CONTENT.md` 中的流程写作：

1. **场景4：初稿写作** - 系统自动记录初稿
2. **场景5-6：审稿和润色** - 正常修改
3. **场景7：定稿归档** - 系统自动记录定稿并触发学习

### 第三步：积累内容（建议5-10篇）

每写完一篇定稿，系统会自动：
1. 保存初稿和定稿
2. 对比差异
3. 提取规则模式
4. 更新规则统计

### 第四步：每周审核规则

```bash
# 查看统计
python config/scripts/review_rules.py --stats

# 交互式审核P0候选规则
python config/scripts/review_rules.py --level P0 --interactive
```

审核时会展示每条候选规则，你可以选择：
- `y` - 批准并应用到写作
- `n` - 拒绝并删除
- `s` - 跳过，稍后再审
- `q` - 退出审核

### 第五步：生成周报

```bash
# 生成本周报告
python config/scripts/generate_weekly_report.py

# 保存到文件
python config/scripts/generate_weekly_report.py --output weekly_report.md
```

---

## 核心脚本使用说明

### 1. observe_draft.py - 记录初稿

**使用场景**：场景4（初稿写作）完成后自动调用

```bash
python config/scripts/observe_draft.py \
  --article-id "2026-03-26_001" \
  --title "文章标题" \
  --source "飞书文档URL" \
  --content "初稿MD内容"
```

**功能**：
- 保存初稿到 `workspace-content/writing-improvement/drafts/`
- 记录元数据（时间、标题、来源）
- 生成唯一文章ID

### 2. observe_final.py - 记录定稿

**使用场景**：场景7（定稿归档）后自动调用

```bash
python config/scripts/observe_final.py \
  --article-id "2026-03-26_001" \
  --content "定稿MD内容"
```

**功能**：
- 保存定稿到 `workspace-content/writing-improvement/finals/`
- 自动触发差异分析和规则提取
- 更新规则统计

### 3. analyze_diff.py - 分析差异

**使用场景**：由 observe_final.py 自动调用

```bash
# 分析单篇文章
python config/scripts/analyze_diff.py --article-id "2026-03-26_001"

# 分析所有待分析文章
python config/scripts/analyze_diff.py --all
```

**功能**：
- 对比初稿和定稿
- 生成详细的差异报告（Markdown格式）
- 提取关键变更点
- 计算统计信息（字数、段落数、平均句长等）

### 4. extract_rules.py - 提取规则

**使用场景**：由 analyze_diff.py 自动调用

```bash
# 提取单篇文章的规则
python config/scripts/extract_rules.py --article-id "2026-03-26_001"

# 批量提取所有待分析文章
python config/scripts/extract_rules.py --auto-level
```

**功能**：
- 从差异中提取写作规则模式
- 计算置信度
- 更新规则出现次数
- 分级规则（P0/P1/P2）
- 生成候选规则文件

### 5. review_rules.py - 审核规则

**使用场景**：每周执行一次

```bash
# 交互式审核P0规则
python config/scripts/review_rules.py --level P0 --interactive

# 查看统计
python config/scripts/review_rules.py --stats

# 生成WRITING_RULES.md
python config/scripts/review_rules.py --generate-md

# 导出规则
python config/scripts/review_rules.py --export rules_backup.json

# 导入规则
python config/scripts/review_rules.py --import rules_backup.json
```

**功能**：
- 展示待审核规则
- 交互式确认/拒绝/修改
- 将确认的P0规则写入 WRITING_RULES.md
- 更新 rules.json 的状态为 approved

### 6. apply_rules.py - 应用规则

**使用场景**：写作时检查内容是否符合规则

```bash
# 检查内容
python config/scripts/apply_rules.py --content "内容" --check

# 检查文件
python config/scripts/apply_rules.py --file article.md --check

# 检查并自动修正
python config/scripts/apply_rules.py --file article.md --apply
```

**功能**：
- 加载已批准的P0规则
- 检查内容是否符合规则
- 提供改进建议
- 自动修正不符合规则的部分（可选）
- 生成规则应用报告

### 7. generate_weekly_report.py - 生成周报

**使用场景**：每周生成一次改进报告

```bash
# 生成本周报告
python config/scripts/generate_weekly_report.py

# 生成指定周的报告
python config/scripts/generate_weekly_report.py --week 2026-W12

# 保存到文件
python config/scripts/generate_weekly_report.py --output report.md
```

**功能**：
- 统计本周产出
- 列出新增规则
- 展示待审核候选规则
- 生成改进趋势分析

---

## 目录结构

```
config/
├── WRITING_IMPROVEMENT_SYSTEM.md     # 本文档
├── WRITING_RULES.md                   # 人类可读规则库（自动生成）
├── writing-rules/                      # 规则数据和候选
│   ├── rules.json                      # 规则数据库
│   ├── stats.json                      # 统计信息
│   └── candidates/                     # 候选规则（待审核）
└── scripts/                            # 核心脚本
    ├── observe_draft.py                # 记录初稿
    ├── observe_final.py                # 记录定稿
    ├── analyze_diff.py                 # 分析差异
    ├── extract_rules.py                # 提取规则
    ├── review_rules.py                 # 审核规则
    ├── apply_rules.py                  # 应用规则
    └── generate_weekly_report.py       # 生成周报

workspace-content/
└── writing-improvement/                # 学习数据（不纳入版本控制）
    ├── drafts/                         # 初稿存档
    ├── finals/                         # 定稿存档
    └── diffs/                          # 差异报告
```

---

## 常见问题

### Q1: 需要多少篇文章才能看到效果？

**A**: 建议至少完成 **5-10篇**文章后再开始审核规则。
- 5篇：开始识别模式
- 10篇：出现第一批P0规则
- 20篇：规则库初具规模
- 50篇：风格稳定，修改率降低50%+

### Q2: 如果提取的规则是错误的怎么办？

**A**: 在审核阶段拒绝即可。
```bash
python config/scripts/review_rules.py --level P0 --interactive
```
选择 `n` 拒绝规则，它就不会被应用。

### Q3: 规则会自动应用到写作吗？

**A**: 只有 **P0级别且状态为approved** 的规则会自动应用。
- 在初稿写作时应用
- 在智能审稿时检查
- 在润色打磨时修正

### Q4: 如何禁用某个规则？

**A**: 两种方式：
1. 在审核时直接拒绝（`n`）
2. 修改 rules.json，将状态改为 `disabled`

### Q5: 学习数据会占用很多空间吗？

**A**: 不会。每篇文章约10-50KB，100篇文章约1-5MB。
建议定期清理（保留最近50篇）。

### Q6: 可以跨项目使用规则吗？

**A**: 可以！规则是通用的：
```bash
# 导出规则
python config/scripts/review_rules.py --export my_rules.json

# 在另一个项目中导入
python config/scripts/review_rules.py --import my_rules.json
```

### Q7: 如何重置整个系统？

**A**: 删除学习数据和规则库：
```bash
# 删除学习数据
rm -rf workspace-content/writing-improvement/*

# 重新初始化
python config/scripts/extract_rules.py --init
```

---

## 最佳实践

### 1. 定期审核规则
建议每周执行一次，避免候选规则堆积太多。

### 2. 保持规则质量
只批准真正符合你风格的规则，拒绝偶然性修改。

### 3. 定期清理
- 删除过时规则
- 合并相似规则
- 清理旧的学习数据（保留最近50篇）

### 4. 备份规则库
```bash
python config/scripts/review_rules.py --export rules_backup_$(date +%Y%m%d).json
```

### 5. 关注改进趋势
通过周报观察规则增长和写作改进趋势。

---

## 系统限制

1. **核心规则必须手写**：权限边界、密钥保护等安全相关规则
2. **需要持续积累**：建议至少20篇文章才能发挥最大效果
3. **偶然修改会被误提取**：必须人工审核确认
4. **可能出现规则冲突**：需要人工判断和调整

---

## 技术实现细节

### Windows编码兼容性
所有脚本已添加UTF-8输出支持，确保Windows系统正常显示emoji。

### 链式自动调用
```
observe_final.py
    ↓
analyze_diff.py
    ↓
extract_rules.py
    ↓
生成候选规则
```

### 规则数据结构
见 "规则数据结构" 章节

### 模式识别算法
见 extract_rules.py 源码中的5种模式

---

## 版本历史

- **v1.0** (2026-03-26)
  - 初始版本
  - 实现完整的自我学习写作改进系统
  - 支持5种模式识别
  - 提供完整的脚本集和文档

---

## 贡献和反馈

如有问题或建议，请在项目仓库提交issue。

**祝写作愉快！** 🎉