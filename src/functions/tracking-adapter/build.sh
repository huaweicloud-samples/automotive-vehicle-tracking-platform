#!/usr/bin/env bash
# 打包三个供应商适配器为 FunctionGraph 可上传的 zip。
# 每个 zip 均自带 kafka-python 依赖（docs/09 打包护栏：缺依赖会导致 handler 静默崩溃）。
# 产物输出到 dist/，随后上传至 OBS（code_url 指向 OBS 对象）。
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p dist

for provider in gps sim ais140; do
  echo "==> 打包 ${provider}-adapter"
  workdir="dist/_build_${provider}"
  rm -rf "$workdir"
  mkdir -p "$workdir"
  cp index.py base_adapter.py "$workdir/"
  pip install -q -r requirements.txt -t "$workdir" --no-cache-dir
  # 过滤 pycache 与缓存，避免包体异常
  find "$workdir" -name "__pycache__" -type d -prune -exec rm -rf {} \; || true
  find "$workdir" -name "*.pyc" -delete
  find "$workdir" -name "*.dist-info" -type d -prune -exec rm -rf {} \; || true
  (cd "$workdir" && zip -qr "../${provider}-adapter.zip" .)
  rm -rf "$workdir"
  echo "==> 生成 dist/${provider}-adapter.zip"
done

echo "全部打包完成，产物在 dist/ 下："
ls -lh dist/*.zip
