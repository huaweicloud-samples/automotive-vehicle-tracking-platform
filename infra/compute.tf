# ============================================================
# 容器工作负载（无服务器容器工作负载）
# ============================================================

# 集群 API server 公网访问（按流量计费，仅用于 kubectl 管理；验证后可解绑）
resource "huaweicloud_vpc_eip" "cce_api" {
  name = "${var.name_prefix}-cce-api-eip"
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.name_prefix}-cce-api-bandwidth"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

# CCE 集群（小规格）
resource "huaweicloud_cce_cluster" "main" {
  name                   = "${var.name_prefix}-cce"
  cluster_type           = "VirtualMachine"
  flavor_id              = "cce.s1.small"
  vpc_id                 = huaweicloud_vpc.main.id
  subnet_id              = huaweicloud_vpc_subnet.private_1.id
  container_network_type = "overlay_l2"
  container_network_cidr = "172.16.0.0/16"
  authentication_mode    = "rbac"
  eip                    = huaweicloud_vpc_eip.cce_api.address

  # 集群自动委托由系统管理（CCE 自动创建），忽略 API 侧差异
  lifecycle {
    ignore_changes = [agency_name]
  }
}

# 两个工作节点（跨可用区），作为 ELB 后端成员
resource "huaweicloud_cce_node" "node_1" {
  cluster_id        = huaweicloud_cce_cluster.main.id
  name              = "${var.name_prefix}-cce-node-1"
  flavor_id         = var.cce_node_flavor
  availability_zone = var.availability_zone_1
  password          = var.cce_node_password
  subnet_id         = huaweicloud_vpc_subnet.private_1.id

  root_volume {
    size       = 40
    volumetype = "SAS"
  }

  data_volumes {
    size       = 100
    volumetype = "SAS"
  }
}

resource "huaweicloud_cce_node" "node_2" {
  cluster_id        = huaweicloud_cce_cluster.main.id
  name              = "${var.name_prefix}-cce-node-2"
  flavor_id         = var.cce_node_flavor
  availability_zone = var.availability_zone_2
  password          = var.cce_node_password
  subnet_id         = huaweicloud_vpc_subnet.private_2.id

  root_volume {
    size       = 40
    volumetype = "SAS"
  }

  data_volumes {
    size       = 100
    volumetype = "SAS"
  }
}

# ============================================================
# 私有 ELB：把 /tracking 流量分发到两个容器服务
# ============================================================
resource "huaweicloud_elb_loadbalancer" "internal" {
  name              = "${var.name_prefix}-elb"
  vpc_id            = huaweicloud_vpc.main.id
  ipv4_subnet_id    = huaweicloud_vpc_subnet.private_1.ipv4_subnet_id
  l7_flavor_id      = "66da67e5-e36b-4c9a-8c06-197ae9e92988" # L7_flavor.elb.s1.small（华北四实测最小 L7 规格）
  availability_zone = [var.availability_zone_1, var.availability_zone_2]
}

resource "huaweicloud_elb_pool" "connector" {
  name            = "${var.name_prefix}-pool-connector"
  loadbalancer_id = huaweicloud_elb_loadbalancer.internal.id
  protocol        = "HTTP"
  lb_method       = "ROUND_ROBIN"
}

resource "huaweicloud_elb_pool" "marketplace" {
  name            = "${var.name_prefix}-pool-marketplace"
  loadbalancer_id = huaweicloud_elb_loadbalancer.internal.id
  protocol        = "HTTP"
  lb_method       = "ROUND_ROBIN"
}

resource "huaweicloud_elb_listener" "http" {
  name            = "${var.name_prefix}-listener-http"
  loadbalancer_id = huaweicloud_elb_loadbalancer.internal.id
  protocol        = "HTTP"
  protocol_port   = 8080
  default_pool_id = huaweicloud_elb_pool.connector.id
}

# ELB 后端成员 = CCE 节点私有 IP（容器服务以 NodePort 暴露，详见部署指导书）
resource "huaweicloud_elb_member" "connector_1" {
  pool_id       = huaweicloud_elb_pool.connector.id
  address       = huaweicloud_cce_node.node_1.private_ip
  protocol_port = 30080
  subnet_id     = huaweicloud_vpc_subnet.private_1.ipv4_subnet_id
}

resource "huaweicloud_elb_member" "connector_2" {
  pool_id       = huaweicloud_elb_pool.connector.id
  address       = huaweicloud_cce_node.node_2.private_ip
  protocol_port = 30080
  subnet_id     = huaweicloud_vpc_subnet.private_2.ipv4_subnet_id
}

resource "huaweicloud_elb_member" "marketplace_1" {
  pool_id       = huaweicloud_elb_pool.marketplace.id
  address       = huaweicloud_cce_node.node_1.private_ip
  protocol_port = 30081
  subnet_id     = huaweicloud_vpc_subnet.private_1.ipv4_subnet_id
}
