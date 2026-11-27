# ============================================================
# 日志：LTS 日志组
# ============================================================
resource "huaweicloud_lts_group" "main" {
  group_name  = "${var.name_prefix}-logs"
  ttl_in_days = 14
}

# ============================================================
# FunctionGraph 函数：供应商适配器（GPS / SIM / AIS140）
# ============================================================
# 说明：
# 1) 函数暂不绑定 VPC / 委托——FGS 绑定 VPC 必须携带 IAM 委托（FSS.1020），
#    而 provider 的 delegated_service_name 对 FunctionGraph 不可用（IAM 404）。
# 2) 生产化收尾（控制台 2 分钟，见部署指导书 §6.1）：在「IAM → 委托 → 创建委托 →
#    云服务 → FunctionGraph」创建委托（勾选 VPC Administrator 及 DMS/DCS/
#    GaussDB NoSQL 相应权限），再在函数「设置 → 权限」挂载该委托、在
#    「设置 → 环境变量」配置 KAFKA_BOOTSTRAP_SERVERS 等变量，并把函数接入 VPC
#    私有子网，即可打通完整数据链路。

resource "huaweicloud_fgs_function" "gps_adapter" {
  name           = "${var.name_prefix}-gps-adapter"
  app            = "default"
  runtime        = "Python3.10"
  handler        = "index.handler"
  memory_size    = 256
  timeout        = 30
  code_type      = "zip"
  code_url       = "obs://${huaweicloud_obs_bucket.functions.bucket}/${var.code_object_gps}"
  enable_lts_log = true

  depends_on = [huaweicloud_obs_bucket_object.gps_zip]

  # code_url 仅在创建时生效，创建后不可更新（FGS API 限制），忽略后续差异
  lifecycle {
    ignore_changes = [code_url]
  }
}

resource "huaweicloud_fgs_function" "sim_adapter" {
  name           = "${var.name_prefix}-sim-adapter"
  app            = "default"
  runtime        = "Python3.10"
  handler        = "index.handler"
  memory_size    = 256
  timeout        = 30
  code_type      = "zip"
  code_url       = "obs://${huaweicloud_obs_bucket.functions.bucket}/${var.code_object_sim}"
  enable_lts_log = true

  depends_on = [huaweicloud_obs_bucket_object.sim_zip]

  # code_url 仅在创建时生效，创建后不可更新（FGS API 限制），忽略后续差异
  lifecycle {
    ignore_changes = [code_url]
  }
}

resource "huaweicloud_fgs_function" "ais140_adapter" {
  name           = "${var.name_prefix}-ais140-adapter"
  app            = "default"
  runtime        = "Python3.10"
  handler        = "index.handler"
  memory_size    = 256
  timeout        = 30
  code_type      = "zip"
  code_url       = "obs://${huaweicloud_obs_bucket.functions.bucket}/${var.code_object_ais140}"
  enable_lts_log = true

  depends_on = [huaweicloud_obs_bucket_object.ais140_zip]

  # code_url 仅在创建时生效，创建后不可更新（FGS API 限制），忽略后续差异
  lifecycle {
    ignore_changes = [code_url]
  }
}
