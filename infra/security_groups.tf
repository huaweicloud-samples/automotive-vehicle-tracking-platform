# 安全组采用「最小入站」策略；出站默认全放行（华为云安全组默认规则，无需显式创建）。

# 私有 ELB：接收 APIG VPC 通道转发来的流量
resource "huaweicloud_networking_secgroup" "elb" {
  name        = "${var.name_prefix}-sg-elb"
  description = "安全组：私有弹性负载均衡"
}

resource "huaweicloud_networking_secgroup_rule" "elb_8080" {
  security_group_id = huaweicloud_networking_secgroup.elb.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = "8080"
  remote_ip_prefix  = var.vpc_cidr
}

# CCE 节点
resource "huaweicloud_networking_secgroup" "cce" {
  name        = "${var.name_prefix}-sg-cce"
  description = "安全组：CCE 节点"
}

resource "huaweicloud_networking_secgroup_rule" "cce_from_elb" {
  security_group_id = huaweicloud_networking_secgroup.cce.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = "8080"
  remote_group_id   = huaweicloud_networking_secgroup.elb.id
}

# DMS Kafka：允许 VPC 内工作负载（容器/函数）访问 9092-9094（含 SASL_SSL 9093）
resource "huaweicloud_networking_secgroup" "kafka" {
  name        = "${var.name_prefix}-sg-kafka"
  description = "安全组：DMS Kafka"
}

resource "huaweicloud_networking_secgroup_rule" "kafka_from_vpc" {
  security_group_id = huaweicloud_networking_secgroup.kafka.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = "9092-9094"
  remote_ip_prefix  = var.vpc_cidr
}

# DCS Redis
resource "huaweicloud_networking_secgroup" "redis" {
  name        = "${var.name_prefix}-sg-redis"
  description = "安全组：DCS Redis"
}

resource "huaweicloud_networking_secgroup_rule" "redis_from_vpc" {
  security_group_id = huaweicloud_networking_secgroup.redis.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = "6379"
  remote_ip_prefix  = var.vpc_cidr
}

# GeminiDB Mongo
resource "huaweicloud_networking_secgroup" "mongo" {
  name        = "${var.name_prefix}-sg-mongo"
  description = "安全组：GeminiDB Mongo"
}

resource "huaweicloud_networking_secgroup_rule" "mongo_from_vpc" {
  security_group_id = huaweicloud_networking_secgroup.mongo.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = "8635"
  remote_ip_prefix  = var.vpc_cidr
}

# APIG 专享实例：对客户端开放 HTTPS 443
resource "huaweicloud_networking_secgroup" "apig" {
  name        = "${var.name_prefix}-sg-apig"
  description = "安全组：APIG 专享实例"
}

resource "huaweicloud_networking_secgroup_rule" "apig_https" {
  security_group_id = huaweicloud_networking_secgroup.apig.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = "443"
  remote_ip_prefix  = "0.0.0.0/0"
}
