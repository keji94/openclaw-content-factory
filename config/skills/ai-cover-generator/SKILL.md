---
name: ai-cover-generator
description: "AI 封面图生成工具。使用 CellCog SDK（底层为 Gemini 3.1 Flash Image / Nano Banana 2 模型）生成文章封面图。当发布公众号文章时自动触发，或用户请求生成配图时使用。"
version: 2.0.0
---

# AI 封面图生成工具

使用 CellCog SDK（底层模型：Gemini 3.1 Flash Image / Nano Banana 2）生成文章封面图。

## 在内容工厂中的位置

```
素材入库 → 选题推荐 → 大纲生成 → 初稿写作 → 修改定稿 → 📱 发布到公众号
                                                    ↓
                                              🎨 AI生成封面图
                                                    ↓
                                              上传到微信素材库
```

**触发时机**：
1. 发布公众号文章时，若无封面图，自动生成
2. 用户请求「生成封面图」「生成配图」时

---

## 环境要求

### 前置依赖

需要安装 CellCog skill：

```bash
clawhub install cellcog
```

### Python 依赖

```bash
pip install -r requirements.txt
```

### API 密钥

需要 Gemini API Key（用于 Nano Banana 2 模型）：
1. 获取 Gemini API Key：https://aistudio.google.com/apikey
2. 配置到 `.env` 文件

可选：硅基流动 API Key（备用模型）：
1. 注册：https://cloud.siliconflow.cn/
2. 创建 API Key

### 配置文件

```bash
# 创建配置
cat > .env << 'EOF'
# Gemini API Key（主模型 Nano Banana 2）
GEMINI_API_KEY=your_gemini_api_key_here

# 硅基流动 API Key（备用模型，可选）
SILICONFLOW_API_KEY=your_siliconflow_key_here
EOF
chmod 600 .env
```

---

## 模型说明

### Nano Banana 2（Gemini 3.1 Flash Image）— 默认推荐
- **特点**: 高质量、照片级真实感、支持复杂构图、文字渲染、多轮角色一致性
- **适用**: 通用封面图、产品摄影、场景生成
- **API Key**: `GEMINI_API_KEY`

### GPT Image 1.5 — 透明背景专用
- **特点**: 支持透明背景 PNG
- **适用**: Logo、贴纸、产品抠图、叠加图形
- **自动路由**: CellCog 在需要透明背景时自动使用

### Recraft — 矢量图专用
- **特点**: 生成 SVG 矢量图和图标
- **适用**: 图标设计、矢量插画
- **自动路由**: CellCog 在需要矢量图时自动使用

### 尺寸建议

| 用途 | 尺寸 | 比例 | 说明 |
|------|------|------|------|
| 公众号封面（大图） | 900 x 383 | 2.35:1 | **默认值**，官方推荐 |
| 公众号封面（高清） | 1024 x 435 | 2.35:1 | 更高清晰度 |
| 公众号封面（小图） | 200 x 200 | 1:1 | 列表展示 |
| 小红书封面 | 1080 x 1440 | 3:4 | 竖版封面 |

---

## 使用方法

### 方式一：命令行

```bash
# 生成封面图（根据文章标题自动生成提示词）
python generate_cover.py --title "文章标题" --output ./cover.jpg

# 自定义提示词
python generate_cover.py --prompt "一个科技感的蓝色背景，中央有发光的代码符号" --output ./cover.jpg

# 指定尺寸（默认 900x383，公众号推荐比例）
python generate_cover.py --title "文章标题" --width 1024 --height 435 --output ./cover.jpg

# 使用 agent team 模式（复杂场景推荐）
python generate_cover.py --title "文章标题" --mode "agent team" --output ./cover.jpg

# 指定重试次数（默认 3 次）
python generate_cover.py --title "文章标题" --retry 5 --output ./cover.jpg
```

### 方式二：Python 调用

```python
from generate_cover import generate_cover

# 根据标题生成
result = generate_cover(
    title="如何用AI提升写作效率",
    output_path="./cover.jpg"
)

# 自定义提示词
result = generate_cover(
    prompt="现代简约风格，蓝色渐变背景，白色几何图形装饰",
    output_path="./cover.jpg",
    width=1024,
    height=435
)

print(f"封面图已保存: {result['image_path']}")
```

---

## 提示词自动生成

当只提供 `--title` 时，脚本会自动生成提示词：

```python
# 根据标题关键词匹配风格
style_map = {
    "AI": "科技感，蓝色调，神经网络图案",
    "教程": "简约风格，步骤流程图示",
    "案例": "商务风格，数据图表元素",
    "观点": "抽象艺术，对比色块",
    # ...
}

# 生成提示词模板
prompt = f"{matched_style}，适合公众号封面，高清，无文字"
```

---

## 返回格式

```json
{
  "success": true,
  "image_path": "./cover.jpg",
  "model": "Nano Banana 2 (Gemini 3.1 Flash Image)",
  "prompt": "科技感蓝色背景...",
  "chat_mode": "agent",
  "attempts": 1
}
```

---

## 错误处理

| 错误 | 处理 |
|------|------|
| GEMINI_API_KEY 未配置 | 提示用户配置 GEMINI_API_KEY |
| CellCog SDK 未安装 | 提示执行 `clawhub install cellcog` |
| 生成失败 | 自动重试 3 次（可通过 --retry 调整） |
| 重试后仍失败 | 提示用户手动上传封面图 |
| 图片保存失败 | 检查目录权限 |

---

## 与 md2wechat 集成

生成封面图后，自动上传到微信素材库：

```bash
# Step 1: 生成封面图
python generate_cover.py --title "文章标题" --output /tmp/cover.jpg

# Step 2: 上传到微信
md2wechat upload_image /tmp/cover.jpg --json

# 输出: {"success": true, "data": {"media_id": "xxx", "url": "https://..."}}
```

---

## License

MIT
