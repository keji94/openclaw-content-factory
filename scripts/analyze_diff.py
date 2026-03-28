#!/usr/bin/env python3
"""
差异分析脚本：对比初稿和定稿，生成详细的差异报告

用法：
    python analyze_diff.py --article-id "2026-03-26_001"
    python analyze_diff.py --all  # 分析所有待分析的文章
"""

import json
import sys
from datetime import datetime
from pathlib import Path
import argparse
import difflib
import re
from typing import List, Dict, Tuple

def load_config():
    """加载配置"""
    config_dir = Path(__file__).parent.parent / "writing-rules"
    workspace_dir = Path(__file__).parent.parent / "writing-improvement"

    return {
        "config_dir": config_dir,
        "workspace_dir": workspace_dir,
        "drafts_dir": workspace_dir / "drafts",
        "finals_dir": workspace_dir / "finals",
        "diffs_dir": workspace_dir / "diffs"
    }

def load_article_metadata(article_id: str) -> Dict:
    """加载文章元数据"""
    config = load_config()
    meta_file = config["drafts_dir"] / f"{article_id}_meta.json"

    if meta_file.exists():
        with open(meta_file, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"articleId": article_id}

def load_draft_and_final(article_id: str) -> Tuple[str, str]:
    """加载初稿和定稿"""
    config = load_config()

    draft_file = config["drafts_dir"] / f"{article_id}_original.md"
    final_file = config["finals_dir"] / f"{article_id}_final.md"

    if not draft_file.exists():
        raise FileNotFoundError(f"初稿不存在: {draft_file}")
    if not final_file.exists():
        raise FileNotFoundError(f"定稿不存在: {final_file}")

    with open(draft_file, 'r', encoding='utf-8') as f:
        draft_content = f.read()

    with open(final_file, 'r', encoding='utf-8') as f:
        final_content = f.read()

    return draft_content, final_content

def generate_unified_diff(draft_lines: List[str], final_lines: List[str], article_id: str) -> str:
    """生成统一的差异格式"""
    diff = difflib.unified_diff(
        draft_lines,
        final_lines,
        fromfile=f"{article_id}_original.md",
        tofile=f"{article_id}_final.md",
        lineterm=""
    )

    return '\n'.join(diff)

def extract_key_changes(draft_content: str, final_content: str) -> List[Dict]:
    """提取关键变更点"""
    changes = []

    draft_paragraphs = [p.strip() for p in draft_content.split('\n\n') if p.strip()]
    final_paragraphs = [p.strip() for p in final_content.split('\n\n') if p.strip()]

    # 使用SequenceMatcher找到相似度低的段落（重大修改）
    for i, (draft_para, final_para) in enumerate(zip(draft_paragraphs, final_paragraphs)):
        similarity = difflib.SequenceMatcher(None, draft_para, final_para).ratio()

        if similarity < 0.7:  # 相似度低于70%认为是重大修改
            changes.append({
                "type": "major_edit",
                "location": f"段落{i+1}",
                "original": draft_para[:100] + "..." if len(draft_para) > 100 else draft_para,
                "improved": final_para[:100] + "..." if len(final_para) > 100 else final_para,
                "similarity": f"{similarity*100:.1f}%"
            })

    # 检测新增内容
    if len(final_paragraphs) > len(draft_paragraphs):
        added_count = len(final_paragraphs) - len(draft_paragraphs)
        changes.append({
            "type": "addition",
            "description": f"新增了 {added_count} 个段落"
        })

    # 检测删除内容
    if len(draft_paragraphs) > len(final_paragraphs):
        deleted_count = len(draft_paragraphs) - len(final_paragraphs)
        changes.append({
            "type": "deletion",
            "description": f"删除了 {deleted_count} 个段落"
        })

    return changes

def calculate_statistics(draft_content: str, final_content: str) -> Dict:
    """计算文本统计信息"""
    stats = {
        "draft": {
            "chars": len(draft_content),
            "chars_no_spaces": len(draft_content.replace(' ', '').replace('\n', '')),
            "words": len(draft_content.split()),
            "paragraphs": len([p for p in draft_content.split('\n\n') if p.strip()]),
            "lines": len(draft_content.split('\n'))
        },
        "final": {
            "chars": len(final_content),
            "chars_no_spaces": len(final_content.replace(' ', '').replace('\n', '')),
            "words": len(final_content.split()),
            "paragraphs": len([p for p in final_content.split('\n\n') if p.strip()]),
            "lines": len(final_content.split('\n'))
        }
    }

    # 计算变化
    stats["changes"] = {
        "chars": stats["final"]["chars"] - stats["draft"]["chars"],
        "words": stats["final"]["words"] - stats["draft"]["words"],
        "paragraphs": stats["final"]["paragraphs"] - stats["draft"]["paragraphs"]
    }

    # 计算平均句长
    def avg_sentence_length(text):
        sentences = re.split(r'[。！？]', text)
        lengths = [len(s) for s in sentences if s.strip()]
        return sum(lengths) / len(lengths) if lengths else 0

    stats["draft"]["avg_sentence_length"] = avg_sentence_length(draft_content)
    stats["final"]["avg_sentence_length"] = avg_sentence_length(final_content)

    return stats

def generate_markdown_report(article_id: str, metadata: Dict, draft_content: str, final_content: str) -> str:
    """生成Markdown格式的差异报告"""

    # 生成差异
    draft_lines = draft_content.split('\n')
    final_lines = final_content.split('\n')
    unified_diff = generate_unified_diff(draft_lines, final_lines, article_id)

    # 提取关键变更
    key_changes = extract_key_changes(draft_content, final_content)

    # 计算统计
    statistics = calculate_statistics(draft_content, final_content)

    # 生成报告
    report = f"""# 文章差异分析报告

## 基本信息

- **文章ID**: {article_id}
- **标题**: {metadata.get('title', '未知')}
- **来源**: {metadata.get('source', '未知')}
- **分析时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

---

## 统计概览

### 字数统计
| 项目 | 初稿 | 定稿 | 变化 |
|------|------|------|------|
| 字符数 | {statistics['draft']['chars']:,} | {statistics['final']['chars']:,} | {statistics['changes']['chars']:+,} |
| 有效字符 | {statistics['draft']['chars_no_spaces']:,} | {statistics['final']['chars_no_spaces']:,} | - |
| 词数 | {statistics['draft']['words']:,} | {statistics['final']['words']:,} | {statistics['changes']['words']:+,} |
| 段落数 | {statistics['draft']['paragraphs']} | {statistics['final']['paragraphs']} | {statistics['changes']['paragraphs']:+d} |
| 行数 | {statistics['draft']['lines']} | {statistics['final']['lines']} | - |

### 语言风格
| 项目 | 初稿 | 定稿 | 变化 |
|------|------|------|------|
| 平均句长 | {statistics['draft']['avg_sentence_length']:.1f}字 | {statistics['final']['avg_sentence_length']:.1f}字 | {statistics['final']['avg_sentence_length'] - statistics['draft']['avg_sentence_length']:+.1f}字 |

---

## 关键变更

"""

    if key_changes:
        for change in key_changes:
            if change["type"] == "major_edit":
                report += f"""### {change['location']} - 重大修改

**相似度**: {change['similarity']}

**原内容**:
```
{change['original']}
```

**修改后**:
```
{change['improved']}
```

---
"""
            elif change["type"] == "addition":
                report += f"""### ✂️ 内容增加

{change['description']}

---
"""
            elif change["type"] == "deletion":
                report += f"""### ✂️ 内容删除

{change['description']}

---
"""
    else:
        report += "未检测到重大修改。\n\n---\n\n"

    report += """## 详细差异

```diff
"""

    report += unified_diff + "\n```\n"

    report += f"""

---

**报告生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**系统版本**: Writing Improvement System v1.0
"""

    return report

def save_diff_report(article_id: str, report: str):
    """保存差异报告"""
    config = load_config()
    config["diffs_dir"].mkdir(parents=True, exist_ok=True)

    report_file = config["diffs_dir"] / f"{article_id}_diff.md"

    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report)

    return report_file

def trigger_rule_extraction(article_id: str):
    """触发规则提取"""
    import subprocess

    scripts_dir = Path(__file__).parent
    extract_script = scripts_dir / "extract_rules.py"

    try:
        result = subprocess.run(
            [sys.executable, str(extract_script), "--article-id", article_id],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            print(f"✅ 规则提取完成")
            return True
        else:
            print(f"⚠️ 规则提取失败: {result.stderr}")
            return False
    except Exception as e:
        print(f"⚠️ 无法触发规则提取: {e}")
        return False

def analyze_article(article_id: str, auto_extract: bool = True):
    """分析单篇文章"""
    print(f"\n📝 分析文章: {article_id}")

    try:
        # 加载元数据
        metadata = load_article_metadata(article_id)

        # 加载初稿和定稿
        draft_content, final_content = load_draft_and_final(article_id)

        print(f"✅ 初稿: {len(draft_content)} 字符")
        print(f"✅ 定稿: {len(final_content)} 字符")

        # 生成差异报告
        report = generate_markdown_report(article_id, metadata, draft_content, final_content)

        # 保存报告
        report_file = save_diff_report(article_id, report)
        print(f"✅ 差异报告已保存: {report_file}")

        # 触发规则提取
        if auto_extract:
            trigger_rule_extraction(article_id)

        return True

    except Exception as e:
        print(f"❌ 分析失败: {e}")
        import traceback
        traceback.print_exc()
        return False

def analyze_all_pending():
    """分析所有待分析的文章"""
    config = load_config()

    finals_dir = config["finals_dir"]
    if not finals_dir.exists():
        print("⚠️ 没有待分析的文章")
        return

    # 获取所有定稿文件
    final_files = list(finals_dir.glob("*_final.md"))
    article_ids = [f.stem.replace("_final", "") for f in final_files]

    # 过滤掉已经有差异报告的
    pending_ids = []
    for article_id in article_ids:
        diff_file = config["diffs_dir"] / f"{article_id}_diff.md"
        if not diff_file.exists():
            pending_ids.append(article_id)

    if not pending_ids:
        print("✅ 所有文章都已分析完毕")
        return

    print(f"📚 找到 {len(pending_ids)} 篇待分析文章")

    success_count = 0
    for article_id in pending_ids:
        if analyze_article(article_id, auto_extract=True):
            success_count += 1

    print(f"\n📊 分析完成: {success_count}/{len(pending_ids)} 篇文章")

def main():
    parser = argparse.ArgumentParser(description='分析初稿和定稿的差异')
    parser.add_argument('--article-id', help='文章ID')
    parser.add_argument('--all', action='store_true', help='分析所有待分析文章')
    parser.add_argument('--no-extract', action='store_true', help='不触发规则提取')

    args = parser.parse_args()

    try:
        if args.all:
            analyze_all_pending()
        elif args.article_id:
            analyze_article(args.article_id, auto_extract=not args.no_extract)
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
    sys.exit(main())
