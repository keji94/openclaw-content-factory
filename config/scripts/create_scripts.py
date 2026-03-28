#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import sys

# 设置UTF-8输出（Windows兼容）
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

print("Creating review_rules.py with proper encoding...")

# 简化版的review_rules.py，只包含核心功能
script_content = '''#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
规则审核脚本
"""

import json
import sys
from datetime import datetime
from pathlib import Path
import argparse

# Windows UTF-8
if sys.platform == \'win32\':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding=\'utf-8\')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding=\'utf-8\')

def load_config():
    config_dir = Path(__file__).parent.parent / "writing-rules"
    return {
        "config_dir": config_dir,
        "rules_file": config_dir / "rules.json",
        "writing_rules_md": Path(__file__).parent.parent / "WRITING_RULES.md"
    }

def load_rules():
    config = load_config()
    if not config["rules_file"].exists():
        return {"rules": [], "statistics": {"totalRules": 0, "p0Rules": 0}}
    with open(config["rules_file"], \'r\', encoding=\'utf-8\') as f:
        return json.load(f)

def show_statistics():
    rules_data = load_rules()
    stats = rules_data.get("statistics", {})
    print(f"\n📊 规则库统计")
    print(f"总规则数: {stats.get(\'totalRules\', 0)}")
    print(f"P0规则: {stats.get(\'p0Rules\', 0)}")

def main():
    parser = argparse.ArgumentParser(description=\'审核和管理写作规则\')
    parser.add_argument(\'--stats\', action=\'store_true\', help=\'显示统计信息\')
    args = parser.parse_args()
    
    if args.stats:
        show_statistics()
    else:
        parser.print_help()

if __name__ == \'__main__\':
    sys.exit(main() or 0)
'''

with open('review_rules.py', 'w', encoding='utf-8') as f:
    f.write(script_content)

print("✅ review_rules.py created successfully")
