#!/usr/bin/env python3
"""
生成周报报告

用法:
    python generate_weekly_report.py
    python generate_weekly_report.py --week 2026-W12
    python generate_weekly_report.py --output report.md
"""

import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
import argparse
from typing import List, Dict

def load_config():
    """加载配置"""
    config_dir = Path(__file__).parent.parent / "writing-rules"
    workspace_dir = Path(__file__).parent.parent / "writing-improvement"

    return {
        "config_dir": config_dir,
        "workspace_dir": workspace_dir,
        "rules_file": config_dir / "rules.json",
        "stats_file": config_dir / "stats.json",
        "candidates_dir": config_dir / "candidates",
        "drafts_dir": workspace_dir / "drafts",
        "finals_dir": workspace_dir / "finals"
    }

def load_rules():
    """加载规则数据"""
    config = load_config()

    if not config["rules_file"].exists():
        return None

    with open(config["rules_file"], 'r', encoding='utf-8') as f:
        return json.load(f)

def get_week_range(week_str: str = None) -> tuple:
    """获取周范围日期"""
    if week_str:
        # 周格式如 2026-W12
        year, week = map(int, week_str.split('-W'))
        # 获取该周的起始日期
        start_date = datetime.strptime(f"{year}-{week}-1", "%Y-%W-%w")
        if start_date.year != year:
            start_date += timedelta(days=7)
        end_date = start_date + timedelta(days=6)
    else:
        # 本周
        today = datetime.now()
        start_date = today - timedelta(days=today.weekday())
        end_date = start_date + timedelta(days=6)

    return start_date, end_date

def get_articles_in_week(start_date: datetime, end_date: datetime) -> List[Dict]:
    """获取本周文章"""
    config = load_config()
    finals_dir = config["finals_dir"]

    if not finals_dir.exists():
        return []

    articles = []

    for final_file in finals_dir.glob("*_final.md"):
        # 文件名日期格式: YYYY-MM-DD_XXX_final.md
        try:
            date_str = final_file.stem.split('_')[0]
            file_date = datetime.strptime(date_str, "%Y-%m-%d")

            if start_date <= file_date <= end_date:
                # 加载元数据
                article_id = final_file.stem.replace("_final", "")
                meta_file = config["drafts_dir"] / f"{article_id}_meta.json"

                metadata = {"articleId": article_id, "date": date_str}
                if meta_file.exists():
                    with open(meta_file, 'r', encoding='utf-8') as f:
                        metadata.update(json.load(f))

                articles.append(metadata)
        except Exception as e:
            continue

    return articles

def get_new_rules_in_week(start_date: datetime, end_date: datetime) -> Dict:
    """获取本周新增规则"""
    config = load_config()
    rules_data = load_rules()

    if not rules_data:
        return {"P0": [], "P1": [], "P2": []}

    new_rules = {"P0": [], "P1": [], "P2": []}

    for rule in rules_data.get("rules", []):
        first_seen = rule.get("firstSeen", "")
        if first_seen:
            try:
                rule_date = datetime.strptime(first_seen, "%Y-%m-%d")
                if start_date <= rule_date <= end_date:
                    level = rule.get("level", "P2")
                    if level in new_rules:
                        new_rules[level].append(rule)
            except:
                continue

    return new_rules

def get_pending_candidates() -> List[Dict]:
    """获取待审核的候选规则"""
    config = load_config()
    candidates_dir = config["candidates_dir"]

    if not candidates_dir.exists():
        return []

    candidates = []

    for candidate_file in candidates_dir.glob("*_candidate_*.json"):
        try:
            with open(candidate_file, 'r', encoding='utf-8') as f:
                candidate = json.load(f)
                candidate["_file"] = str(candidate_file)
                candidates.append(candidate)
        except:
            continue

    # 按置信度排序
    candidates.sort(key=lambda x: x.get("confidence", 0), reverse=True)

    return candidates

def generate_weekly_report(start_date: datetime, end_date: datetime) -> str:
    """生成周报"""

    # 加载数据
    rules_data = load_rules()
    articles = get_articles_in_week(start_date, end_date)
    new_rules = get_new_rules_in_week(start_date, end_date)
    pending_candidates = get_pending_candidates()

    # 生成报告
    week_str = start_date.strftime("%Y年 第%W周")

    report = f"""# 写作学习周报

**周次**: {week_str} ({start_date.strftime('%Y-%m-%d')} ~ {end_date.strftime('%Y-%m-%d')})
**报告生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

---

## 总体本周概览

"""

    if rules_data:
        stats = rules_data.get("statistics", {})
        report += f"""**规则统计**:
- 总规则数: {stats.get('totalRules', 0)}
- P0 规则数量: {stats.get('p0Rules', 0)}
- P1 规则观察: {stats.get('p1Rules', 0)}
- P2 规则记录: {stats.get('p2Rules', 0)}
- 总文章数: {stats.get('totalArticles', 0)}

"""
    else:
        report += "_规则库暂无数据_\n\n"

    report += f"""**本周数据**:
- 写作篇数: {len(articles)} 篇
- 新增P0规则: {len(new_rules['P0'])} 条
- 新增P1规则: {len(new_rules['P1'])} 条
- 新增P2规则: {len(new_rules['P2'])} 条
- 待审核规则: {len(pending_candidates)} 条

---

## 本周写作文章

"""

    if articles:
        for i, article in enumerate(articles, 1):
            report += f"""### {i}. {article.get('title', '无标题')}

- **文章ID**: {article['articleId']}
- **日期**: {article.get('date', '未知')}
- **来源**: {article.get('source', '未知')}

"""
    else:
        report += "_本周暂无文章_\n\n"

    report += """---

## 本周新增规则

"""

    total_new = len(new_rules['P0']) + len(new_rules['P1']) + len(new_rules['P2'])

    if total_new > 0:
        if new_rules['P0']:
            report += "### P0 规则数量\n\n"
            for rule in new_rules['P0']:
                report += f"""#### {rule['id']}: {rule['pattern']}

- **类别**: {rule.get('category', '未知')}
- **置信度**: {rule.get('confidence', 0)}%
- **出现次数**: {rule.get('occurrenceCount', 0)}次
- **描述**: {rule.get('description', '无')}

"""

        if new_rules['P1']:
            report += "### P1 规则观察\n\n"
            for rule in new_rules['P1']:
                report += f"- **{rule['id']}**: {rule['pattern']} ({rule.get('confidence', 0)}%, {rule.get('occurrenceCount', 0)}次)\n"
            report += "\n"

        if new_rules['P2']:
            report += "### P2 规则记录\n\n"
            for rule in new_rules['P2']:
                report += f"- **{rule['id']}**: {rule['pattern']} ({rule.get('confidence', 0)}%, {rule.get('occurrenceCount', 0)}次)\n"
            report += "\n"
    else:
        report += "_本周无新增规则_\n\n"

    report += """---

## 待审核的候选规则

"""

    if pending_candidates:
        report += f"共有 {len(pending_candidates)} 条候选规则待审核:\n\n"

        for i, candidate in enumerate(pending_candidates[:10], 1):  # 最多显示10条
            report += f"""### {i}. {candidate.get('id', '未知')}

- **类别**: {candidate.get('category', '未知')}
- **建议级别**: {candidate.get('level', candidate.get('suggestedLevel', 'P2'))}
- **置信度**: {candidate.get('confidence', 0)}%
- **出现次数**: {candidate.get('occurrenceCount', 0)}次
- **模式**: {candidate.get('pattern', '未知')}
- **描述**: {candidate.get('description', '无')}

"""

        if len(pending_candidates) > 10:
            report += f"_还有 {len(pending_candidates) - 10} 条候选规则未显示_\n\n"

        report += """**审核命令**:
```bash
python config/scripts/review_rules.py --level P0 --interactive
```
"""
    else:
        report += "_暂无待审核的候选规则_\n\n"

    report += """---

## 学习进展

### 规则积累健康度

文章数量和规则数量的参考标准:

| 文章数 | P0规则数 | P1规则数 | P2规则数 |
|--------|-------------|-------------|-------------|
| 10篇 | 2-3条 | 5-8条 | 10-15条 |
| 20篇 | 5-8条 | 10-15条 | 20-30条 |
| 50篇 | 12-18条 | 15-25条 | 30-50条 |

### 写作学习评估

- **起步**: 0-10篇，规则正在积累，继续学习
- **成长**: 10-30篇，规则逐步完善，AI 写作风格正在形成
- **成熟**: 30篇+，规则体系完整，风格匹配度可达50%+

---

## 下周计划

"""

    if pending_candidates:
        report += """1. **审核候选规则**: 运行 `python config/scripts/review_rules.py --level P0 --interactive`
2. **持续写作练习**: 保持日常写作习惯
3. **观察规则效果**: 关注规则对写作质量的影响

"""
    else:
        report += """1. **增加写作量**: 多写多练，积累更多初稿-定稿对
2. **关注写作风格**: SOP流程中加入风格自检步骤
3. **保持互动频率**: 每周至少2-3次互动，增加学习样本

"""

    report += f"""

---

**报告版本**: Writing Improvement System v1.0
**生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

备注 **重要**: 本报告由系统自动生成，数据来源于写作学习积累。如有疑问请人工审核。
"""

    return report

def main():
    parser = argparse.ArgumentParser(description='生成写作学习周报')
    parser.add_argument('--week', help='周次格式如 2026-W12')
    parser.add_argument('--output', help='输出文件路径')

    args = parser.parse_args()

    try:
        # 获取周范围日期
        start_date, end_date = get_week_range(args.week)

        # 生成报告
        report = generate_weekly_report(start_date, end_date)

        # 输出报告
        if args.output:
            output_path = Path(args.output)
            output_path.parent.mkdir(parents=True, exist_ok=True)

            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(report)

            print(f"周报已输出到: {output_path}")
        else:
            print("\n" + report)
            print("\n" + "="*60)
            print("\n备注: 使用 --output 参数将报告保存到文件")
            print("   示例: python generate_weekly_report.py --output weekly_report.md")

        return 0

    except Exception as e:
        print(f"生成失败: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
