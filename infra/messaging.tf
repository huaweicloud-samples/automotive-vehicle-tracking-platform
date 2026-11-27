# DMS Kafka（云消息队列 Kafka）：托管 Apache Kafka 事件总线
# 客户端协议/库完全兼容
resource "huaweicloud_dms_kafka_instance" "main" {
  name               = "${var.name_prefix}-kafka"
  engine_version     = "2.7"
  vpc_id             = huaweicloud_vpc.main.id
  network_id         = huaweicloud_vpc_subnet.private_1.id
  security_group_id  = huaweicloud_networking_secgroup.kafka.id
  storage_spec_code  = "dms.physical.storage.high.v2"
  flavor_id          = var.dms_kafka_flavor
  broker_num         = 3
  storage_space      = 300
  # c6.2u4g.cluster 实测仅支持 cn-north-4a/4b/4g（4c 无货）
  availability_zones = [var.availability_zone_1, var.availability_zone_2, "cn-north-4g"]

  # 传输加密 + SASL 认证（SASL_SSL + PLAIN）
  ssl_enable         = true
  security_protocol  = "SASL_SSL"
  enabled_mechanisms = ["PLAIN"]
  access_user        = "vehicle-tracking"
  password           = var.kafka_password

  # topic 自动创建 + 按时间保留日志（7 天）
  enable_auto_topic = true
  retention_policy  = "time_base"

  tags = {
    Purpose = "vehicle-tracking-event-streaming"
  }
}
