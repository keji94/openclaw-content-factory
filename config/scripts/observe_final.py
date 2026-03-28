#!/usr/bin/env python3
"""
观察脚本：记录用户修改后的定稿并触发差异分析

用法：
    python observe_final.py \
        --article-id "2026-03-26_001" \
        --content "定稿MD内容"
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path
import argparse
import subprocess

def load_config():
    """加载配置"""
    config_dir = Path(__file__).parent.parent / "writing-rules"
    workspace_dir = Path(__file__).parent.parent.parent / "workspace-content" / "writing-improvement"

    return {
        "config_dir": config_dir,
        "workspace_dir": workspace_dir,
        "finals_dir": workspace_dir / "finals",
        "drafts_dir": workspace_dir / "drafts",
        "diffs_dir": workspace_dir / "diffs"
    }

def save_final(article_id, content):
    """保存定稿"""
    config = load_config()

    # 确保目录存在
    config["finals_dir"].mkdir(parents=True, exist_ok=True)

    # 保存MD文件
    final_file = config["finals_dir"] / f"{article_id}_final.md"

    with open(final_file, 'w', encoding='utf-8') as f:
        f.write(content)

    # 更新元数据
    meta_file = config["drafts_dir"] / f"{article_id}_meta.json"
    if meta_file.exists():
        with open(meta_file, 'r', encoding='utf-8') as f:
            metadata = json.load(f)
    else:
        metadata = {"articleId": article_id}

    metadata["finalSavedAt"] = datetime.now().isoformat()
    metadata["stage"] = "final"

    with open(meta_file, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)

    print(f"✅ 定稿已保存: {final_file}")

    return final_file

def trigger_analysis(article_id):
    """触发差异分析和规则提取"""
    config = load_config()
    scripts_dir = Path(__file__).parent

    try:
        # 运行差异分析
        analyze_script = scripts_dir / "analyze_diff.py"
        result = subprocess.run(
            [sys.executable, str(analyze_script), "--article-id", article_id],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            print(f"✅ 差异分析完成")
            print(result.stdout)
        else:
            print(f"⚠️ 差异分析失败: {result.stderr}")

        return result.returncode == 0
    except Exception as e:
        print(f"⚠️ 无法触发分析: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='记录用户修改后的定稿')
    parser.add_argument('--article-id', required=True, help='文章唯一ID')
    parser.add_argument('--content', required=True, help='定稿MD内容')
    parser.add_argument('--content-file', help='从文件读取内容')
    parser.add_argument('--no-analysis', action='store_true', help='不触发自动分析')

    args = parser.parse_args()

    # 如果指定了文件，从文件读取
    if args.content_file:
        with open(args.content_file, 'r', encoding='utf-8') as f:
            content = f.read()
    else:
        content = args.content

    try:
        save_final(args.article_id, args.content)

        # 触发差异分析
        if not args.no_analysis:
            trigger_analysis(args.article_id)

        return 0
    except Exception as e:
        print(f"❌ 保存失败: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
