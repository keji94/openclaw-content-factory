#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
规则审核脚本：审核候选规则，将确认的P0规则写入WRITING_RULES.md

用法：
    python review_rules_simple.py --stats
    python review_rules_simple.py --generate-md
"""

import json
import sys
import os
from datetime import datetime
from pathlib import Path
import argparse

# Windows UTF-8 support
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def load_config():
    """加载配置"""
    config_dir = Path(__file__).parent.parent / "writing-rules"
    return {
        "config_dir": config_dir,
        "rules_file": config_dir / "rules.json",
        "writing_rules_md": Path(__file__).parent.parent / "WRITING_RULES.md"
    }

def load_rules():
    """加载规则数据库"""
    config = load_config()
    if not config["rules_file"].exists():
        return {
            "version": "1.0",
            "lastUpdated": datetime.now().isoformat(),
            "statistics": {
                "totalRules": 0,
                "p0Rules": 0,
                "p1Rules": 0,
                "p2Rules": 0,
                "totalArticles": 0
            },
            "rules": []
        }
    with open(config["rules_file"], 'r', encoding='utf-8') as f:
        return json.load(f)

def save_rules(rules_data):
    """保存规则数据库"""
    config = load_config()
    rules_data["lastUpdated"] = datetime.now().isoformat()
    with open(config["rules_file"], 'w', encoding='utf-8') as f:
        json.dump(rules_data, f, ensure_ascii=False, indent=2)

def show_statistics():
    """显示统计信息"""
    rules_data = load_rules()
    stats = rules_data.get("statistics", {})

    print(f"\n📊 规则库统计")
    print(f"{'='*60}")
    print(f"总规则数: {stats.get('totalRules', 0)}")
    print(f"P0规则（已确认）: {stats.get('p0Rules', 0)}")
    print(f"P1规则（观察中）: {stats.get('p1Rules', 0)}")
    print(f"P2规则（记录中）: {stats.get('p2Rules', 0)}")
    print(f"总文章数: {stats.get('totalArticles', 0)}")
    print(f"最后更新: {rules_data.get('lastUpdated', '未知')}")

    # 显示P0规则
    p0_rules = [r for r in rules_data.get("rules", []) if r.get("level") == "P0"]
    if p0_rules:
        print(f"\n✅ P0规则列表:")
        for rule in p0_rules:
            print(f"  - {rule['id']}: {rule['pattern']} ({rule.get('confidence', 0)}%)")

def generate_writing_rules_md():
    """生成WRITING_RULES.md文档"""
    rules_data = load_rules()
    config = load_config()

    # 获取已批准的规则
    approved_rules = [r for r in rules_data.get("rules", []) if r.get("status") == "approved"]

    # 按类别和级别分组
    categories = {}
    for rule in approved_rules:
        category = rule.get("category", "其他")
        if category not in categories:
            categories[category] = {"P0": [], "P1": [], "P2": []}
        level = rule.get("level", "P2")
        categories[category][level].append(rule)

    # 生成Markdown
    md = f"""# 写作规则库

> 本文档由自我学习写作改进系统自动生成
> 最后更新: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## 规则说明

本规则库通过分析初稿和定稿的差异自动提取并经人工审核确认。

### 规则分级

- **P0规则**（高频规则）：出现≥5次，置信度≥80%，已确认，自动应用
- **P1规则**（中频规则）：出现2-4次，置信度50-79%，观察中
- **P2规则**（低频规则）：出现1次，置信度<50%，仅记录

---

## 统计概览

- 总规则数: {rules_data['statistics']['totalRules']}
- P0规则（已确认）: {rules_data['statistics']['p0Rules']}
- P1规则（观察中）: {rules_data['statistics']['p1Rules']}
- P2规则（记录中）: {rules_data['statistics']['p2Rules']}
- 总文章数: {rules_data['statistics']['totalArticles']}

---

## P0规则（已确认 - 自动应用）

"""

    if not approved_rules:
        md += "_暂无P0规则。规则会在积累至少5次出现并经人工审核后加入此列表。_\n\n"
    else:
        # 按类别输出P0规则
        for category, rules_by_level in categories.items():
            if rules_by_level["P0"]:
                md += f"\n### {category}\n\n"
                for rule in rules_by_level["P0"]:
                    md += f"""#### {rule['id']}: {rule['pattern']}

- **置信度**: {rule['confidence']}%
- **出现次数**: {rule['occurrenceCount']}次
- **首次出现**: {rule['firstSeen']}
- **最后出现**: {rule['lastSeen']}

**描述**: {rule['description']}

"""
                    if rule.get("positiveExample"):
                        md += f"""✅ **正例**:
```
{rule['positiveExample']}
```

"""
                    if rule.get("negativeExample"):
                        md += f"""❌ **反例**:
```
{rule['negativeExample']}
```

"""
                    md += f"""**来源文章**: {', '.join(rule.get('sourceArticles', []))}

---

"""

    md += f"""

---

**系统版本**: Writing Improvement System v1.0
**生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""

    # 保存
    with open(config["writing_rules_md"], 'w', encoding='utf-8') as f:
        f.write(md)

    print(f"✅ 已生成规则库文档: {config['writing_rules_md']}")
    return True

def main():
    parser = argparse.ArgumentParser(description='审核和管理写作规则')
    parser.add_argument('--stats', action='store_true', help='显示统计信息')
    parser.add_argument('--generate-md', action='store_true', help='生成WRITING_RULES.md')

    args = parser.parse_args()

    try:
        if args.stats:
            show_statistics()
        elif args.generate_md:
            generate_writing_rules_md()
        else:
            parser.print_help()
            return 1

        return 0
    except Exception as e:
        print(f"❌ 执行失败: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main() or 0)
