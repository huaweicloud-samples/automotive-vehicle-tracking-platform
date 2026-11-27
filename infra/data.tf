# DDS 文档数据库（MongoDB 兼容）：策略表 / 安全表 / 会话状态表
# 集合：policy_rules / security_rules / session_state
# 由应用初始化时建集合，显著减少实例数量
resource "huaweicloud_dds_instance" "mongo" {
  name              = "${var.name_prefix}-dds"
  mode              = "ReplicaSet"
  availability_zone = var.availability_zone_1
  vpc_id            = huaweicloud_vpc.main.id
  subnet_id         = huaweicloud_vpc_subnet.private_1.id
  security_group_id = huaweicloud_networking_secgroup.mongo.id
  password          = var.mongo_password

  datastore {
    type           = "DDS-Community"
    version        = "4.0"
    storage_engine = "wiredTiger"
  }

  flavor {
    type      = "replica" # 副本集节点类型
    num       = 3         # 副本集固定 3 节点（1 主 2 从）
    size      = 40        # 每节点磁盘 40GB
    storage   = "ULTRAHIGH"
    spec_code = "dds.mongodb.s6.medium.4.repset" # 华北四实测可用最小副本集规格（1vCPU/4GB）
  }
}
