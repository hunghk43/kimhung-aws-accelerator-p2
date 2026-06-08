variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "mentor-web-demo-tf-locks"
}

variable "force_destroy_state_bucket" {
  description = "Allow deleting the state bucket even if it contains objects"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
