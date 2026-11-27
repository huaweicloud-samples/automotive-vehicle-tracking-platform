terraform {
  required_version = ">= 1.9.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}

# 凭据从运行环境读取（HW_ACCESS_KEY / HW_SECRET_KEY / HW_REGION_NAME），
# 不写入任何文件，避免凭据落盘。
provider "huaweicloud" {
  region = var.region
}
