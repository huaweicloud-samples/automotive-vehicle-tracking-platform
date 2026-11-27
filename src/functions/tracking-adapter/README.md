# 供应商适配器（FunctionGraph）

三个无服务器函数，分别对接 GPS / SIM / AIS140 三类追踪供应商，
将位置事件标准化后发布到 DMS Kafka 事件总线，供 Tracking Connector 消费。

## 目录
- `base_adapter.py`：公共模块（响应格式、模拟位置、事件载荷、校验）
- `index.py`：统一 handler，按环境变量 `PROVIDER_TYPE` 区分供应商
- `requirements.txt`：依赖（kafka-python）
- `build.sh`：一键打包三个 zip（自带依赖，过滤 pycache）

## 打包与部署
```bash
./build.sh            # 产出 dist/gps-adapter.zip、sim-adapter.zip、ais140-adapter.zip
# 将 zip 上传到 OBS（对应 infra 中 code_url 的桶/对象名），
# 然后通过控制台/API 创建函数：运行时 Python 3.10、handler index.handler、
# 内存 256MB、超时 30s、VPC 指向私有子网、委托绑定 fgs-agency。
```

## 环境变量
| 变量 | 说明 |
|---|---|
| `PROVIDER_TYPE` | GPS / SIM / AIS140 |
| `KAFKA_BOOTSTRAP_SERVERS` | DMS Kafka 客户端连接地址（SASL_SSL） |
| `KAFKA_TOPIC` | 事件主题，默认 `vehicle-tracking-events` |
| `KAFKA_USERNAME` / `KAFKA_PASSWORD` | SASL/PLAIN 认证凭据（密码敏感） |
| `CACHE_ENDPOINT` | Redis 缓存地址（可选） |

> 说明：当前 provider 版本未开放函数环境变量的 Terraform 配置，
> 环境变量需在 FunctionGraph 控制台或调用 UpdateFunctionConfig API 设置
> （部署指导书有完整步骤）。
