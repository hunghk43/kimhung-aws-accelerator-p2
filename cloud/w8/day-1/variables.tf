# Khai báo tất cả input variables

variable "aws_region" {
  description = "AWS region để deploy"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Tên project, dùng làm prefix cho resource"
  type        = string
  default     = "accelerator"
}

variable "env" {
  description = "Môi trường: dev | staging | prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env phải là dev, staging, hoặc prod."
  }
}
