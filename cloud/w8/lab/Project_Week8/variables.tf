variable "aws_region" {
  description = "AWS region for the lab."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Base name for all resources."
  type        = string
  default     = "week8-k8s-lab"
}

variable "instance_type" {
  description = "EC2 instance type for the kind host."
  type        = string
  default     = "t3.medium"
}

variable "allowed_ssh_cidr" {
  description = "Unused on purpose; SSH is not opened. Kept for audit clarity."
  type        = string
  default     = "0.0.0.0/32"
}
