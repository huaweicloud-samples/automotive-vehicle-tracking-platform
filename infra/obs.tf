# OBS：承载 FunctionGraph 函数代码 zip（代码包由 src/functions/tracking-adapter/build.sh 产出）

resource "random_string" "bucket_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "huaweicloud_obs_bucket" "functions" {
  bucket        = "${var.name_prefix}-functions-${random_string.bucket_suffix.result}"
  acl           = "private"
  force_destroy = true
  tags = {
    Purpose = "function-code"
  }
}

resource "huaweicloud_obs_bucket_object" "gps_zip" {
  bucket       = huaweicloud_obs_bucket.functions.bucket
  key          = var.code_object_gps
  source       = "../src/functions/tracking-adapter/dist/gps-adapter.zip"
  content_type = "application/zip"
}

resource "huaweicloud_obs_bucket_object" "sim_zip" {
  bucket       = huaweicloud_obs_bucket.functions.bucket
  key          = var.code_object_sim
  source       = "../src/functions/tracking-adapter/dist/sim-adapter.zip"
  content_type = "application/zip"
}

resource "huaweicloud_obs_bucket_object" "ais140_zip" {
  bucket       = huaweicloud_obs_bucket.functions.bucket
  key          = var.code_object_ais140
  source       = "../src/functions/tracking-adapter/dist/ais140-adapter.zip"
  content_type = "application/zip"
}
