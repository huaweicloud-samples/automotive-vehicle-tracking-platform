resource "huaweicloud_vpc" "main" {
  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr
}

# 两个私有子网（跨可用区）：容器、函数、Kafka/Redis/数据库全部在私有网段
# 说明：本部署不创建公网 NAT/IGW——所有组件仅访问同区域服务内部端点
# （SWR/APIG 等经 100.125.x.x 服务网络可达），无需公网出站。
resource "huaweicloud_vpc_subnet" "private_1" {
  name              = "${var.name_prefix}-private-subnet-1"
  vpc_id            = huaweicloud_vpc.main.id
  cidr              = var.private_subnet_1_cidr
  gateway_ip        = cidrhost(var.private_subnet_1_cidr, 1)
  availability_zone = var.availability_zone_1
}

resource "huaweicloud_vpc_subnet" "private_2" {
  name              = "${var.name_prefix}-private-subnet-2"
  vpc_id            = huaweicloud_vpc.main.id
  cidr              = var.private_subnet_2_cidr
  gateway_ip        = cidrhost(var.private_subnet_2_cidr, 1)
  availability_zone = var.availability_zone_2
}
