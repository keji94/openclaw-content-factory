#!/usr/bin/env python3
"""
规则提取脚本：从差异中提取写作规则模式

用法：
    python extract_rules.py --article-id "2026-03-26_001"
    python extract_rules.py --auto-level  # 自动提取所有待分析文章
    python extract_rules.py --init        # 初始化规则数据库
"""

import json
import sys
import os
from datetime import datetime
from pathlib import Path
import argparse
import re
from typing import List, Dict, Any

# 设置UTF-8输出（Windows兼容）
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def load_config():
    """加载配置"""
    config_dir = Path(__file__).parent.parent / "writing-rules"
    workspace_dir = Path(__file__).parent.parent.parent / "workspace-content" / "writing-improvement"

    return {
        "config_dir": config_dir,
        "workspace_dir": workspace_dir,
        "drafts_dir": workspace_dir / "drafts",
        "finals_dir": workspace_dir / "finals",
        "diffs_dir": workspace_dir / "diffs",
        "candidates_dir": config_dir / "candidates",
        "rules_file": config_dir / "rules.json",
        "stats_file": config_dir / "stats.json"
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

def extract_patterns_from_diff(article_id: str) -> List[Dict[str, Any]]:
    """从差异中提取模式"""
    config = load_config()

    # 加载初稿和定稿
    draft_file = config["drafts_dir"] / f"{article_id}_original.md"
    final_file = config["finals_dir"] / f"{article_id}_final.md"

    if not draft_file.exists() or not final_file.exists():
        print(f"⚠️ 文章 {article_id} 文件不完整，跳过")
        return []

    with open(draft_file, 'r', encoding='utf-8') as f:
        draft_content = f.read()

    with open(final_file, 'r', encoding='utf-8') as f:
        final_content = f.read()

    patterns = []

    # 模式1: 检测AI痕迹词汇的替换
    ai_words = ['综上所述', '不难看出', '由此可见', '显而易见', '值得注意的是']
    for word in ai_words:
        if word in draft_content and word not in final_content:
            # 找到替换内容
            pattern = re.search(re.escape(word) + r'.*?\n', draft_content)
            if pattern:
                patterns.append({
                    "category": "语言风格",
                    "pattern": f"避免AI痕迹词汇：{word}",
                    "description": f"将'{word}'替换为更自然的表达",
                    "confidence": 75,
                    "source": "ai_words_replacement"
                })

    # 模式2: 检测标题变化
    draft_title = draft_content.split('\n')[0]
    final_title = final_content.split('\n')[0]

    if draft_title != final_title:
        # 检查是否使用了数字型标题
        if re.search(r'\d+', final_title) and not re.search(r'\d+', draft_title):
            patterns.append({
                "category": "标题",
                "pattern": "标题使用数字型公式",
                "description": f"标题从'{draft_title}'改为'{final_title}'，增加了具体数字",
                "positiveExample": final_title,
                "negativeExample": draft_title,
                "confidence": 80,
                "source": "title_analysis"
            })

    # 模式3: 检测开头是否增加了痛点引入
    draft_first_lines = '\n'.join(draft_content.split('\n')[:5])
    final_first_lines = '\n'.join(final_content.split('\n')[:5])

    pain_point_keywords = ['痛点', '问题', '困扰', '烦恼', '遇到过', '是不是']
    has_pain_point_draft = any(kw in draft_first_lines for kw in pain_point_keywords)
    has_pain_point_final = any(kw in final_first_lines for kw in pain_point_keywords)

    if not has_pain_point_draft and has_pain_point_final:
        patterns.append({
            "category": "结构",
            "pattern": "开头痛点引入",
            "description": "开头前5行必须提出痛点或问题",
            "confidence": 85,
            "source": "opening_analysis"
        })

    # 模式4: 检测结尾是否有行动号召
    draft_last_lines = '\n'.join(draft_content.split('\n')[-5:])
    final_last_lines = '\n'.join(final_content.split('\n')[-5:])

    cta_keywords = ['点赞', '在看', '评论', '关注', '分享']
    has_cta_draft = any(kw in draft_last_lines for kw in cta_keywords)
    has_cta_final = any(kw in final_last_lines for kw in cta_keywords)

    if not has_cta_draft and has_cta_final:
        patterns.append({
            "category": "结构",
            "pattern": "结尾行动号召",
            "description": "结尾必须包含点赞、在看、评论等引导",
            "confidence": 75,
            "source": "ending_analysis"
        })

    # 模式5: 检测短句比例变化
    def avg_sentence_length(text):
        sentences = re.split(r'[。！？]', text)
        lengths = [len(s) for s in sentences if s.strip()]
        return sum(lengths) / len(lengths) if lengths else 0

    draft_avg_len = avg_sentence_length(draft_content)
    final_avg_len = avg_sentence_length(final_content)

    if draft_avg_len > 20 and final_avg_len < 18:
        patterns.append({
            "category": "语言风格",
            "pattern": "短句节奏",
            "description": f"平均句长从{draft_avg_len:.1f}字减少到{final_avg_len:.1f}字",
            "confidence": 70,
            "source": "sentence_length_analysis"
        })

    # 为每个模式添加文章ID
    for pattern in patterns:
        pattern["articleId"] = article_id

    return patterns

def calculate_rule_level(rule_data: Dict, all_rules: List[Dict]) -> str:
    """计算规则级别（P0/P1/P2）"""
    # 查找是否已存在相似规则
    similar_rules = [
        r for r in all_rules
        if r.get("pattern") == rule_data.get("pattern")
        and r.get("category") == rule_data.get("category")
    ]

    if not similar_rules:
        return "P2"  # 新规则，出现1次

    # 更新出现次数
    existing_rule = similar_rules[0]
    occurrence_count = existing_rule.get("occurrenceCount", 0) + 1

    if occurrence_count >= 5:
        return "P0"
    elif occurrence_count >= 2:
        return "P1"
    else:
        return "P2"

def update_rules_with_patterns(article_id: str, patterns: List[Dict]):
    """用新模式更新规则库"""
    config = load_config()
    rules_data = load_rules()

    for pattern in patterns:
        # 计算规则级别
        level = calculate_rule_level(pattern, rules_data["rules"])

        # 查找或创建规则
        existing_rule = next(
            (r for r in rules_data["rules"]
             if r.get("pattern") == pattern.get("pattern")
             and r.get("category") == pattern.get("category")),
            None
        )

        if existing_rule:
            # 更新现有规则
            existing_rule["occurrenceCount"] = existing_rule.get("occurrenceCount", 0) + 1
            existing_rule["lastSeen"] = datetime.now().strftime("%Y-%m-%d")
            existing_rule["confidence"] = min(95, existing_rule.get("confidence", 70) + 5)
            existing_rule["level"] = level

            # 添加到来源文章
            if "sourceArticles" not in existing_rule:
                existing_rule["sourceArticles"] = []
            if article_id not in existing_rule["sourceArticles"]:
                existing_rule["sourceArticles"].append(article_id)

            # 如果达到P0，生成候选文件
            if level == "P0" and existing_rule.get("status") != "approved":
                save_candidate_rule(existing_rule, article_id)

        else:
            # 创建新规则
            new_rule = {
                "id": f"rule_{len(rules_data['rules']) + 1:03d}",
                "category": pattern.get("category"),
                "pattern": pattern.get("pattern"),
                "description": pattern.get("description"),
                "occurrenceCount": 1,
                "confidence": pattern.get("confidence", 70),
                "level": level,
                "status": "pending",
                "firstSeen": datetime.now().strftime("%Y-%m-%d"),
                "lastSeen": datetime.now().strftime("%Y-%m-%d"),
                "sourceArticles": [article_id]
            }

            # 添加示例
            if "positiveExample" in pattern:
                new_rule["positiveExample"] = pattern["positiveExample"]
            if "negativeExample" in pattern:
                new_rule["negativeExample"] = pattern["negativeExample"]

            rules_data["rules"].append(new_rule)

    # 更新统计
    rules_data["statistics"]["totalRules"] = len(rules_data["rules"])
    rules_data["statistics"]["p0Rules"] = sum(1 for r in rules_data["rules"] if r["level"] == "P0")
    rules_data["statistics"]["p1Rules"] = sum(1 for r in rules_data["rules"] if r["level"] == "P1")
    rules_data["statistics"]["p2Rules"] = sum(1 for r in rules_data["rules"] if r["level"] == "P2")
    rules_data["statistics"]["totalArticles"] = len(set(
        article for r in rules_data["rules"]
        for article in r.get("sourceArticles", [])
    ))

    # 保存规则
    save_rules(rules_data)

    print(f"✅ 规则库已更新")
    print(f"📊 总规则数: {rules_data['statistics']['totalRules']}")
    print(f"📊 P0规则: {rules_data['statistics']['p0Rules']}")
    print(f"📊 P1规则: {rules_data['statistics']['p1Rules']}")
    print(f"📊 P2规则: {rules_data['statistics']['p2Rules']}")

def save_candidate_rule(rule: Dict, article_id: str):
    """保存候选规则（待审核的P0规则）"""
    config = load_config()
    config["candidates_dir"].mkdir(parents=True, exist_ok=True)

    candidate_file = config["candidates_dir"] / f"{datetime.now().strftime('%Y-%m-%d')}_candidate_{rule['id']}.json"

    with open(candidate_file, 'w', encoding='utf-8') as f:
        json.dump(rule, f, ensure_ascii=False, indent=2)

    print(f"✅ 候选规则已保存: {candidate_file}")

def process_article(article_id: str):
    """处理单篇文章"""
    print(f"\n📝 处理文章: {article_id}")

    # 提取模式
    patterns = extract_patterns_from_diff(article_id)

    if not patterns:
        print(f"⚠️ 未提取到明显模式")
        return

    print(f"✅ 提取到 {len(patterns)} 个模式")

    # 更新规则库
    update_rules_with_patterns(article_id, patterns)

def process_all_pending():
    """处理所有待分析的文章"""
    config = load_config()

    finals_dir = config["finals_dir"]
    if not finals_dir.exists():
        print("⚠️ 没有待分析的文章")
        return

    final_files = list(finals_dir.glob("*_final.md"))
    article_ids = [f.stem.replace("_final", "") for f in final_files]

    print(f"📚 找到 {len(article_ids)} 篇文章待分析")

    for article_id in article_ids:
        try:
            process_article(article_id)
        except Exception as e:
            print(f"❌ 处理 {article_id} 失败: {e}")

def init_database():
    """初始化规则数据库"""
    config = load_config()

    # 创建目录
    config["config_dir"].mkdir(parents=True, exist_ok=True)
    config["workspace_dir"].mkdir(parents=True, exist_ok=True)
    config["drafts_dir"].mkdir(parents=True, exist_ok=True)
    config["finals_dir"].mkdir(parents=True, exist_ok=True)
    config["diffs_dir"].mkdir(parents=True, exist_ok=True)
    config["candidates_dir"].mkdir(parents=True, exist_ok=True)

    # 创建空规则库
    if not config["rules_file"].exists():
        save_rules(load_rules())

    # 创建空统计文件
    if not config["stats_file"].exists():
        with open(config["stats_file"], 'w', encoding='utf-8') as f:
            json.dump({
                "lastAnalysis": None,
                "pendingReview": 0,
                "articlesProcessed": 0,
                "rulesExtracted": 0,
                "p0RulesApproved": 0
            }, f, indent=2)

    print("✅ 规则数据库初始化完成")
    print(f"📁 配置目录: {config['config_dir']}")
    print(f"📁 工作目录: {config['workspace_dir']}")

def main():
    parser = argparse.ArgumentParser(description='从差异中提取写作规则')
    parser.add_argument('--article-id', help='文章ID')
    parser.add_argument('--auto-level', action='store_true', help='自动处理所有待分析文章')
    parser.add_argument('--init', action='store_true', help='初始化规则数据库')

    args = parser.parse_args()

    try:
        if args.init:
            init_database()
        elif args.auto_level:
            process_all_pending()
        elif args.article_id:
            process_article(args.article_id)
        else:
            parser.print_help()
            return 1

        return 0
    except Exception as e:
        print(f"❌ 提取失败: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
