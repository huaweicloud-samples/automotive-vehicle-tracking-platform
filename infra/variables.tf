variable "region" {
  description = "华为云目标区域，例如 cn-north-4"
  type        = string
  default     = "cn-north-4"
}

variable "name_prefix" {
  description = "所有资源名称前缀，便于区分与清理"
  type        = string
  default     = "vehicle-tracking"
}

variable "vpc_cidr" {
  description = "VPC CIDR 块"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_1" {
  description = "第一个可用区"
  type        = string
  default     = "cn-north-4a"
}

variable "availability_zone_2" {
  description = "第二个可用区"
  type        = string
  default     = "cn-north-4b"
}

variable "availability_zone_3" {
  description = "第三个可用区（DMS Kafka 3 broker 跨 3 AZ）"
  type        = string
  default     = "cn-north-4c"
}

variable "public_subnet_1_cidr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "public_subnet_2_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_1_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "tracking_connector_cpu" {
  description = "Tracking Connector 容器 CPU（毫核）"
  type        = number
  default     = 1024
}

variable "tracking_connector_memory" {
  description = "Tracking Connector 容器内存（MiB）"
  type        = number
  default     = 2048
}

variable "tracking_connector_replicas" {
  type    = number
  default = 2
}

variable "marketplace_mgmt_cpu" {
  type    = number
  default = 512
}

variable "marketplace_mgmt_memory" {
  type    = number
  default = 1024
}

variable "marketplace_mgmt_replicas" {
  type    = number
  default = 1
}

variable "dms_kafka_flavor" {
  description = "DMS Kafka 实例规格"
  type        = string
  default     = "c6.2u4g.cluster"
}

variable "msk_broker_count" {
  description = "Kafka 代理节点数（跨 AZ 部署）"
  type        = number
  default     = 2
}

variable "msk_storage_size" {
  type    = number
  default = 100
}

variable "redis_flavor" {
  description = "DCS Redis 实例规格"
  type        = string
  default     = "redis.single.xu1.tiny.100"
}

variable "redis_node_count" {
  type    = number
  default = 2
}

variable "redis_auth_token" {
  description = "Redis 访问密码（transit 加密），填入部署脚本，勿落盘"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cce_node_flavor" {
  description = "CCE 节点池 ECS 规格"
  type        = string
  default     = "s6.large.2"
}

variable "cce_node_count" {
  type    = number
  default = 2
}

variable "cce_node_password" {
  description = "CCE 节点登录密码（敏感，填入部署脚本，勿落盘）"
  type        = string
  sensitive   = true
  default     = ""
}

variable "swr_org" {
  description = "SWR 组织名（镜像仓库命名空间）"
  type        = string
  default     = "vehicle-tracking"
}

variable "swr_region" {
  description = "SWR 镜像仓库所在区域端点，例如 swr.cn-north-4.myhuaweicloud.com"
  type        = string
  default     = "swr.cn-north-4.myhuaweicloud.com"
}

variable "kafka_password" {
  description = "Kafka SASL 密码（敏感，填入部署脚本，勿落盘）"
  type        = string
  sensitive   = true
  default     = ""
}

variable "mongo_password" {
  description = "GeminiDB Mongo 密码（敏感，填入部署脚本，勿落盘）"
  type        = string
  sensitive   = true
  default     = ""
}

variable "code_object_gps" {
  type    = string
  default = "gps-adapter.zip"
}

variable "code_object_sim" {
  type    = string
  default = "sim-adapter.zip"
}

variable "code_object_ais140" {
  type    = string
  default = "ais140-adapter.zip"
}
