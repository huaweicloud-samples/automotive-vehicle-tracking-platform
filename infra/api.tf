# ============================================================
# APIG（API 网关）：客户端入口
# 客户端经 APIG 入站 → VPC 通道 → 私有 ELB → 容器服务
# ============================================================

# APIG 公网入口由 ingress_bandwidth_size 自动绑定 EIP（见下方实例配置），
# 此前的独立 EIP 已弃用：保留资源记录避免误删，验证完成后可删除。
resource "huaweicloud_vpc_eip" "apig" {
  name = "${var.name_prefix}-apig-eip"
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.name_prefix}-apig-bandwidth"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# 专享实例（规格与费用见部署指导书）
resource "huaweicloud_apig_instance" "main" {
  name               = "${var.name_prefix}-apig"
  edition            = "BASIC"
  vpc_id             = huaweicloud_vpc.main.id
  subnet_id          = huaweicloud_vpc_subnet.private_1.id
  security_group_id  = huaweicloud_networking_secgroup.apig.id
  availability_zones = [var.availability_zone_1, var.availability_zone_2]

  # 公网入口（BASIC 规格仅支持按带宽计费；验证后可移除关闭）
  ingress_bandwidth_size          = 5
  ingress_bandwidth_charging_mode = "bandwidth"
}

# RELEASE 环境为 APIG 实例自带，直接引用
data "huaweicloud_apig_environments" "release" {
  instance_id = huaweicloud_apig_instance.main.id
  name        = "RELEASE"
}

resource "huaweicloud_apig_group" "tracking" {
  instance_id = huaweicloud_apig_instance.main.id
  name        = "${var.name_prefix}-api-group"

  # 开启调试域名访问（便于直接用 sl_domain 验证 API）
  domain_access_enabled = true
}

# VPC 通道：指向私有 ELB 的私网地址
resource "huaweicloud_apig_channel" "connector" {
  instance_id      = huaweicloud_apig_instance.main.id
  name             = "${var.name_prefix}-channel-connector"
  port             = 8080
  member_type      = "ip"
  balance_strategy = 1 # 1=加权轮询（WRR）

  member {
    host   = huaweicloud_elb_loadbalancer.internal.ipv4_address
    port   = 8080
    weight = 1
  }
}

resource "huaweicloud_apig_api" "tracking" {
  instance_id             = huaweicloud_apig_instance.main.id
  group_id                = huaweicloud_apig_group.tracking.id
  name                    = "${var.name_prefix}-tracking-api"
  type                    = "Public"
  request_protocol        = "HTTPS"
  request_method          = "ANY"
  request_path            = "/tracking"
  security_authentication = "IAM"
  description             = "车辆追踪平台客户端入口，经 VPC 通道转发到私有 ELB"
  # 说明：验证 APIG→ELB 完整链路期间曾临时改为 NONE（已记录），验证后已改回 IAM

  web {
    path             = "/tracking"
    request_method   = "ANY"
    request_protocol = "HTTP"
    vpc_channel_id   = huaweicloud_apig_channel.connector.id
    timeout          = 30
  }
}

resource "huaweicloud_apig_api_publishment" "tracking" {
  instance_id = huaweicloud_apig_instance.main.id
  api_id      = huaweicloud_apig_api.tracking.id
  env_id      = data.huaweicloud_apig_environments.release.environments[0].id
}
