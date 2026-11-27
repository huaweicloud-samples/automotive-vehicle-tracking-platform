# 车辆追踪平台部署指导书

## 1. 前置条件

- 华为云账号，具备 VPC / CCE / ELB / APIG / DMS / DCS / DDS / FunctionGraph / SWR / KMS 权限。
- 本地已安装 Terraform（≥1.9）、kubectl、docker、bash。
- 已准备好：
  - 密钥对名称（CCE 节点登录，`cce_key_pair`）；
  - 各服务密码（Kafka / Redis / Mongo，填入部署脚本，勿提交到仓库）；
  - 目标区域与可用区（默认 `cn-north-4` / `cn-north-4a` / `cn-north-4b`，请按实际修改 `infra/variables.tf`）。

## 2. 凭据配置（安全须知）

```bash
export HW_ACCESS_KEY="<AK>"
export HW_SECRET_KEY="<SK>"
export TF_VAR_kafka_password="<KAFKA_PASSWORD>"
export TF_VAR_redis_auth_token="<REDIS_PASSWORD>"
export TF_VAR_mongo_password="<MONGO_PASSWORD>"
```

> 真实 AK/SK 与密码只通过环境变量传递，不写入任何文件、截图或报告。

## 3. 部署基础设施

```bash
cd infra
terraform init
terraform plan                 # 审阅资源清单与费用
terraform apply                # 确认费用（见第 8 节）后执行
```

输出将给出：Kafka 连接地址、Redis 域名与端口、ELB 私网地址、APIG 实例 ID 等。


## 4. 构建并推送镜像

```bash
cd src/containers
# 先在容器源码目录构建（tracking-connector / marketplace-mgmt 各自 Dockerfile）
SWR_ADDR=swr.cn-north-4.myhuaweicloud.com SWR_ORG=vehicle-tracking ./build-push.sh
```

## 5. 部署容器工作负载

将 `terraform output` 得到的值替换 `k8s.yaml` 中的占位符，然后：

```bash
# 使用 CCE 集群 kubeconfig
kubectl config use-context <cce-cluster>
kubectl apply -f src/containers/tracking-connector/k8s.yaml
kubectl apply -f src/containers/marketplace-mgmt/k8s.yaml
```

> ELB 后端成员已指向 CCE 节点私有 IP（NodePort 30080 / 30081），
> 若 NodePort 与清单不一致，请同步调整 `infra/compute.tf` 中 `elb_member.protocol_port`。

## 6. 部署供应商适配器函数

```bash
cd src/functions/tracking-adapter
./build.sh                      # 产出 gps/sim/ais140 三个 zip
# 将 zip 上传到 OBS（与 infra 中 code_url 对应），然后：
# 控制台创建函数：运行时 Python 3.10、handler index.handler、内存 256MB、超时 30s、
# VPC 指向私有子网、委托绑定 fgs-agency；再设置环境变量（见 src/functions/tracking-adapter/README.md）。
```

## 7. 验证

1. **连通性**：`curl -k https://<APIG-域名>/tracking` 应返回 401（IAM 鉴权生效）。
2. **健康检查**：容器内 `curl http://localhost:8080/health` → `{"status":"healthy"}`。
3. **端到端**：向适配器 API 发起 `POST /tracking {"vehicleId":"MH01AB1234"}`，
   返回 `trackingId`；随后在 Kafka 消费端可见 `LOCATION_UPDATE` 事件。
4. **数据落库**：查询 DDS `session_state` 集合，应出现对应会话记录。

## 8. 资源规格（apply 前必读）


## 9. 清理

```bash
cd infra
terraform destroy        # 删除所有基础设施
kubectl delete -f src/containers/tracking-connector/k8s.yaml
kubectl delete -f src/containers/marketplace-mgmt/k8s.yaml
# 检查是否有残留（EIP / 云硬盘 / SWR 仓库）并手动释放
```
