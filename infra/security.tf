# ============================================================
# 加密与镜像仓库
# ============================================================

# 客户主密钥：用于 DMS 盘加密等
resource "huaweicloud_kms_key" "main" {
  key_alias        = "${var.name_prefix}-encryption"
  key_description  = "DMS 等服务的静态加密主密钥"
  key_usage        = "ENCRYPT_DECRYPT"
  rotation_enabled = false
}

# SWR（容器镜像服务）：承载两个服务镜像
resource "huaweicloud_swr_organization" "main" {
  name = var.swr_org
}

resource "huaweicloud_swr_repository" "tracking_connector" {
  organization = huaweicloud_swr_organization.main.name
  name         = "tracking-connector"
  description  = "Tracking Connector 容器镜像"
  is_public    = false

  # category 为 API 默认值，忽略避免持续漂移
  lifecycle {
    ignore_changes = [category]
  }
}

resource "huaweicloud_swr_repository" "marketplace_mgmt" {
  organization = huaweicloud_swr_organization.main.name
  name         = "marketplace-mgmt"
  description  = "Marketplace 订阅管理容器镜像"
  is_public    = false

  # category 为 API 默认值，忽略避免持续漂移
  lifecycle {
    ignore_changes = [category]
  }
}
