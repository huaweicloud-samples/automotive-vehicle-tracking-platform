# DCS Redis（分布式缓存服务）：低延迟会话缓存
resource "huaweicloud_dcs_instance" "redis" {
  name               = "${var.name_prefix}-redis"
  engine             = "Redis"
  engine_version     = "7.0"
  flavor             = "redis.ha.xu1.large.r2.4"
  capacity           = 4
  vpc_id             = huaweicloud_vpc.main.id
  subnet_id          = huaweicloud_vpc_subnet.private_1.id
  security_group_id  = huaweicloud_networking_secgroup.redis.id
  availability_zones = [var.availability_zone_1]

  # 传输加密 + 密码认证
  ssl_enable = true
  password   = var.redis_auth_token
  port       = 6379

  tags = {
    Purpose = "low-latency-tracking-data-cache"
  }

  # 该 DCS 版本不支持安全组白名单更新（创建时已生效），避免后续 plan 持续报更新
  lifecycle {
    ignore_changes = [security_group_id]
  }
}
