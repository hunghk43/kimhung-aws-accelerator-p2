variable "name_prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "vpc_id" {
  type        = string
  description = "Target VPC id"
}

variable "admin_cidr" {
  type        = string
  description = "CIDR allowed to SSH into EC2"
}

variable "app_port" {
  type        = number
  description = "Port exposed by the application"
}

variable "database_port" {
  type        = number
  description = "Database port for MySQL"
  default     = 3306
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
