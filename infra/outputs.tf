output "vpc_id" {
  value = huaweicloud_vpc.main.id
}

output "kafka_connect_address" {
  description = "Kafka 客户端连接地址（SASL_SSL）"
  value       = huaweicloud_dms_kafka_instance.main.connect_address
}

output "kafka_management_address" {
  description = "Kafka 管理面连接地址"
  value       = huaweicloud_dms_kafka_instance.main.vpc_client_plain
}

output "redis_domain_name" {
  description = "Redis 连接域名"
  value       = huaweicloud_dcs_instance.redis.domain_name
}

output "redis_port" {
  value = huaweicloud_dcs_instance.redis.port
}

output "elb_private_ip" {
  description = "私有 ELB 私网地址（APIG VPC 通道后端）"
  value       = huaweicloud_elb_loadbalancer.internal.ipv4_address
}

output "apig_instance_id" {
  value = huaweicloud_apig_instance.main.id
}

output "mongo_db_id" {
  value = huaweicloud_dds_instance.mongo.id
}

output "cce_cluster_id" {
  value = huaweicloud_cce_cluster.main.id
}
