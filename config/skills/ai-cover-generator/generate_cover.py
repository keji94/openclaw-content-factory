#!/usr/bin/env python3
"""
AI 封面图生成工具
使用 CellCog SDK（底层模型：Gemini 3.1 Flash Image / Nano Banana 2）生成文章封面图
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Optional, Dict, Any

# 默认配置
DEFAULT_CHAT_MODE = "agent"  # "agent" for simple images, "agent team" for complex
DEFAULT_RETRY = 3
DEFAULT_ASPECT_RATIO = "21:9"  # 接近公众号封面 2.35:1 比例
DEFAULT_SIZE = "2K"

# 风格映射（根据标题关键词自动匹配）
STYLE_MAP = {
    "AI": "科技感，蓝色调，神经网络图案，电路板纹理",
    "人工智能": "科技感，蓝色调，神经网络图案，电路板纹理",
    "教程": "简约现代风格，清晰的步骤图示，蓝色渐变背景",
    "如何": "简约现代风格，问号元素，渐变背景",
    "案例": "商务专业风格，数据图表元素，深蓝色调",
    "复盘": "商务专业风格，时间线元素，蓝灰色调",
    "观点": "抽象艺术风格，对比色块，思考者元素",
    "思考": "抽象艺术风格，蓝色调，灯泡或大脑元素",
    "方法": "实用工具风格，手把手元素，绿色或蓝色调",
    "技巧": "实用工具风格，技巧提示元素，橙色点缀",
    "工具": "工具图标风格，简洁几何图形，蓝色调",
    "产品": "产品展示风格，简约背景，渐变光效",
    "运营": "增长图表风格，上升箭头，绿色或蓝色调",
    "营销": "营销漏斗风格，多彩元素，现代感",
    "设计": "创意艺术风格，多彩渐变，几何图形",
    "写作": "文字元素风格，墨水笔触，暖色调",
    "效率": "时钟或齿轮元素，蓝绿色调",
    "职场": "商务人物剪影，城市背景，蓝色调",
    "创业": "火箭上升元素，渐变背景，活力感",
}

DEFAULT_STYLE = "现代简约风格，渐变蓝色背景，几何图形装饰，适合公众号封面，高清，无文字"


def load_env(env_file: Optional[str] = None) -> dict:
    """加载 API Key 配置，返回字典"""
    keys = {}

    # 优先从环境变量获取
    for key in ["GEMINI_API_KEY", "SILICONFLOW_API_KEY"]:
        val = os.environ.get(key)
        if val:
            keys[key] = val

    # 尝试从 .env 文件加载
    if env_file is None:
        script_dir = Path(__file__).parent
        env_file = script_dir / ".env"

        if not env_file.exists():
            env_file = Path.home() / ".openclaw" / "workspace-content" / "skills" / "ai-cover-generator" / ".env"

    if Path(env_file).exists():
        with open(env_file, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if "=" in line and not line.startswith("#"):
                    k, v = line.split("=", 1)
                    k = k.strip()
                    v = v.strip()
                    if k in ("GEMINI_API_KEY", "SILICONFLOW_API_KEY") and k not in keys:
                        keys[k] = v

    # 检查至少有一个可用的 key
    if not keys.get("GEMINI_API_KEY") and not keys.get("SILICONFLOW_API_KEY"):
        print(json.dumps({
            "success": False,
            "error": "未配置任何 API Key",
            "hint": "请设置 GEMINI_API_KEY 或 SILICONFLOW_API_KEY 环境变量，或创建 .env 文件"
        }))
        sys.exit(1)

    return keys


def generate_prompt_from_title(title: str) -> str:
    """根据标题自动生成提示词"""
    for keyword, style in STYLE_MAP.items():
        if keyword in title:
            return f"{style}，适合公众号封面，高清，无文字，主题相关"

    return DEFAULT_STYLE


def _generate_via_gemini(
    prompt: str,
    output_path: str,
    api_key: str,
    max_retries: int = DEFAULT_RETRY,
) -> Dict[str, Any]:
    """通过 Gemini Imagen API 生成图片（imagen-4.0-generate-001）"""
    import requests
    import base64

    # Imagen predict endpoint
    url = f"https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-generate-001:predict"

    headers = {
        "x-goog-api-key": api_key,
        "Content-Type": "application/json",
    }
    payload = {
        "instances": [
            {"prompt": prompt}
        ],
        "parameters": {
            "sampleCount": 1,
            "aspectRatio": "16:9",
        }
    }

    last_error = None
    for attempt in range(1, max_retries + 1):
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=120)
            response.raise_for_status()
            data = response.json()

            # 从 Imagen 响应中提取图片
            predictions = data.get("predictions", [])
            if not predictions:
                return {"success": False, "error": "Imagen API 未返回图片", "response": data}

            img_b64 = predictions[0].get("bytesBase64Encoded")
            if not img_b64:
                return {"success": False, "error": "Imagen 响应中无图片数据", "response": data}

            # 确保输出目录存在
            output_dir = Path(output_path).parent
            output_dir.mkdir(parents=True, exist_ok=True)

            # 解码并保存图片
            img_bytes = base64.b64decode(img_b64)

            ext = Path(output_path).suffix.lower()
            if ext in (".jpg", ".jpeg"):
                from io import BytesIO
                from PIL import Image
                img = Image.open(BytesIO(img_bytes))
                if img.mode == "RGBA":
                    img = img.convert("RGB")
                img.save(output_path, "JPEG", quality=95)
            else:
                with open(output_path, "wb") as f:
                    f.write(img_bytes)

            return {
                "success": True,
                "image_path": str(output_path),
                "model": "imagen-4.0-generate-001",
                "prompt": prompt,
                "attempts": attempt,
            }

        except requests.exceptions.HTTPError as e:
            status = e.response.status_code if e.response else "unknown"
            try:
                err_body = e.response.json() if e.response else {}
                err_msg = err_body.get("error", {}).get("message", str(e))
            except Exception:
                err_msg = str(e)
            last_error = f"Imagen API HTTP {status}: {err_msg} (尝试 {attempt}/{max_retries})"
            if attempt < max_retries:
                time.sleep(3)
        except Exception as e:
            last_error = f"生成失败 (尝试 {attempt}/{max_retries}): {str(e)}"
            if attempt < max_retries:
                time.sleep(2)

    return {"success": False, "error": f"重试 {max_retries} 次后仍失败: {last_error}"}


def _generate_via_siliconflow(
    prompt: str,
    output_path: str,
    api_key: str,
    model: str = "nanophotohq/nanophoto-nano-banana-pro",
    width: int = 900,
    height: int = 383,
    max_retries: int = DEFAULT_RETRY,
) -> Dict[str, Any]:
    """通过硅基流动 API 生成图片（备用方案）"""
    import requests

    url = "https://api.siliconflow.cn/v1/images/generations"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": model,
        "prompt": prompt,
        "image_size": f"{width}x{height}",
        "num_inference_steps": 20,
    }

    last_error = None
    for attempt in range(1, max_retries + 1):
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=60)
            response.raise_for_status()
            data = response.json()

            if "images" in data and len(data["images"]) > 0:
                image_url = data["images"][0].get("url")
                if not image_url:
                    return {"success": False, "error": "API 返回的图片 URL 为空"}

                img_response = requests.get(image_url, timeout=30)
                img_response.raise_for_status()

                output_dir = Path(output_path).parent
                output_dir.mkdir(parents=True, exist_ok=True)

                with open(output_path, "wb") as f:
                    f.write(img_response.content)

                return {
                    "success": True,
                    "image_path": str(output_path),
                    "model": model,
                    "prompt": prompt,
                    "attempts": attempt,
                }
            else:
                return {"success": False, "error": "API 未返回图片数据", "response": data}

        except Exception as e:
            last_error = f"请求失败 (尝试 {attempt}/{max_retries}): {str(e)}"
            if attempt < max_retries:
                time.sleep(2)

    return {"success": False, "error": f"重试 {max_retries} 次后仍失败: {last_error}"}


def generate_cover(
    title: Optional[str] = None,
    prompt: Optional[str] = None,
    output_path: str = "./cover.jpg",
    chat_mode: str = DEFAULT_CHAT_MODE,
    width: int = 900,
    height: int = 383,
    max_retries: int = DEFAULT_RETRY,
) -> Dict[str, Any]:
    """
    生成封面图

    优先使用 CellCog SDK (Gemini/Nano Banana 2)，
    如果 CellCog 不可用且配置了 SILICONFLOW_API_KEY，则回退到硅基流动。

    Args:
        title: 文章标题（用于自动生成提示词）
        prompt: 自定义提示词（优先级高于 title）
        output_path: 输出图片路径
        chat_mode: CellCog 聊天模式 ("agent" 或 "agent team")
        width: 图片宽度（仅硅基流动备用方案使用）
        height: 图片高度（仅硅基流动备用方案使用）
        max_retries: 最大重试次数

    Returns:
        生成结果字典
    """
    # 生成提示词
    if not prompt:
        if title:
            prompt = generate_prompt_from_title(title)
        else:
            prompt = DEFAULT_STYLE

    # 加载配置
    keys = load_env()

    # 优先使用 Gemini API
    if keys.get("GEMINI_API_KEY"):
        result = _generate_via_gemini(
            prompt=prompt,
            output_path=output_path,
            api_key=keys["GEMINI_API_KEY"],
            max_retries=max_retries,
        )
        if result["success"]:
            return result
        # Gemini 失败，尝试硅基流动备用
        print(f"Gemini 生成失败: {result.get('error')}, 尝试备用方案...", file=sys.stderr)

    # 备用：硅基流动
    if keys.get("SILICONFLOW_API_KEY"):
        return _generate_via_siliconflow(
            prompt=prompt,
            output_path=output_path,
            api_key=keys["SILICONFLOW_API_KEY"],
            width=width,
            height=height,
            max_retries=max_retries,
        )

    return {
        "success": False,
        "error": "无可用的图片生成服务，请配置 GEMINI_API_KEY 或 SILICONFLOW_API_KEY"
    }


def main():
    parser = argparse.ArgumentParser(description="AI 封面图生成工具")
    parser.add_argument("--title", "-t", help="文章标题（自动生成提示词）")
    parser.add_argument("--prompt", "-p", help="自定义提示词")
    parser.add_argument("--output", "-o", default="./cover.jpg", help="输出路径 (默认: ./cover.jpg)")
    parser.add_argument("--mode", "-M", default=DEFAULT_CHAT_MODE,
                        choices=["agent", "agent team"],
                        help=f"CellCog 聊天模式 (默认: {DEFAULT_CHAT_MODE})")
    parser.add_argument("--width", "-W", type=int, default=900, help="宽度 (备用方案用, 默认: 900)")
    parser.add_argument("--height", "-H", type=int, default=383, help="高度 (备用方案用, 默认: 383)")
    parser.add_argument("--retry", "-r", type=int, default=DEFAULT_RETRY, help=f"重试次数 (默认: {DEFAULT_RETRY})")
    parser.add_argument("--json", action="store_true", help="JSON 格式输出")

    args = parser.parse_args()

    if not args.title and not args.prompt:
        parser.error("请提供 --title 或 --prompt")

    result = generate_cover(
        title=args.title,
        prompt=args.prompt,
        output_path=args.output,
        chat_mode=args.mode,
        width=args.width,
        height=args.height,
        max_retries=args.retry,
    )

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        if result["success"]:
            print(f"✅ 封面图已生成: {result['image_path']}")
            if result.get("attempts", 1) > 1:
                print(f"   重试次数: {result['attempts']}")
            print(f"   模型: {result['model']}")
            print(f"   提示词: {result['prompt'][:50]}...")
        else:
            print(f"❌ 生成失败: {result['error']}")

    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
