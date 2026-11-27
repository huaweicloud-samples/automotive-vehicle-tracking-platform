#!/usr/bin/env bash
# 构建两个容器镜像并推送到 SWR（镜像仓库推送工作流）。
# 前置：docker 已登录 SWR（swr login），凭据不落盘。
set -euo pipefail

# 从环境变量读取（勿写死在脚本/仓库中）
SWR_ADDR="${SWR_ADDR:?请设置 SWR_ADDR，例如 swr.cn-north-4.myhuaweicloud.com}"
SWR_ORG="${SWR_ORG:-vehicle-tracking}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

build_push() {
  local name="$1" dir="$2"
  echo "==> 构建 ${name}"
  docker build -t "${SWR_ADDR}/${SWR_ORG}/${name}:latest" "${REPO_ROOT}/containers/${dir}"
  echo "==> 推送 ${name}"
  docker push "${SWR_ADDR}/${SWR_ORG}/${name}:latest"
}

# 容器源码位于 huaweicloud/产物同级的容器目录；此处假定源码已适配到 containers/<svc>/
build_push tracking-connector tracking-connector
build_push marketplace-mgmt marketplace-mgmt

echo "镜像推送完成。请将 SWR_ADDR/SWR_ORG 填入 k8s.yaml 的 {{SWR_ADDR}}/{{SWR_ORG}} 占位符。"
