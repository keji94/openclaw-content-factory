#!/usr/bin/env python3
"""
观察脚本：记录AI生成的初稿

用法：
    python observe_draft.py \
        --article-id "2026-03-26_001" \
        --title "文章标题" \
        --source "https://..." \
        --content "初稿MD内容"
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path
import argparse

def load_config():
    """加载配置"""
    config_dir = Path(__file__).parent.parent / "writing-rules"
    workspace_dir = Path(__file__).parent.parent.parent / "workspace-content" / "writing-improvement"

    return {
        "config_dir": config_dir,
        "workspace_dir": workspace_dir,
        "drafts_dir": workspace_dir / "drafts"
    }

def save_draft(article_id, title, source, content):
    """保存初稿"""
    config = load_config()

    # 确保目录存在
    config["drafts_dir"].mkdir(parents=True, exist_ok=True)

    # 保存MD文件
    draft_file = config["drafts_dir"] / f"{article_id}_original.md"

    with open(draft_file, 'w', encoding='utf-8') as f:
        f.write(content)

    # 保存元数据
    metadata = {
        "articleId": article_id,
        "title": title,
        "source": source,
        "savedAt": datetime.now().isoformat(),
        "stage": "draft"
    }

    meta_file = config["drafts_dir"] / f"{article_id}_meta.json"
    with open(meta_file, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)

    print(f"✅ 初稿已保存: {draft_file}")
    print(f"📝 文章ID: {article_id}")
    print(f"📌 标题: {title}")

    return draft_file

def main():
    parser = argparse.ArgumentParser(description='记录AI生成的初稿')
    parser.add_argument('--article-id', required=True, help='文章唯一ID')
    parser.add_argument('--title', required=True, help='文章标题')
    parser.add_argument('--source', required=True, help='来源链接（飞书文档URL等）')
    parser.add_argument('--content', required=True, help='初稿MD内容')
    parser.add_argument('--content-file', help='从文件读取内容')

    args = parser.parse_args()

    # 如果指定了文件，从文件读取
    if args.content_file:
        with open(args.content_file, 'r', encoding='utf-8') as f:
            content = f.read()
    else:
        content = args.content

    try:
        save_draft(args.article_id, args.title, args.source, content)
        return 0
    except Exception as e:
        print(f"❌ 保存失败: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
