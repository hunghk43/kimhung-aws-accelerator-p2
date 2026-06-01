# Local values — tính toán trung gian, tái sử dụng trong module

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "terraform"
    Owner       = "cloud-accelerator-w8"
  }
}
