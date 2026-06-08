variable "name_prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "ami_id" {
  type        = string
  description = "AMI id for the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "Instance type"
}

variable "subnet_id" {
  type        = string
  description = "Public subnet id"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group ids for the instance"
}

variable "key_name" {
  type        = string
  description = "Optional EC2 key pair"
  default     = null
}

variable "app_name" {
  type        = string
  description = "Application name"
}

variable "app_port" {
  type        = number
  description = "Application port"
}

variable "mysql_host" {
  type        = string
  description = "RDS endpoint"
}

variable "mysql_port" {
  type        = number
  description = "MySQL port"
  default     = 3306
}

variable "mysql_database" {
  type        = string
  description = "Database name"
}

variable "mysql_user" {
  type        = string
  description = "Database user"
}

variable "mysql_password" {
  type        = string
  description = "Database password"
  sensitive   = true
}

variable "s3_bucket_name" {
  type        = string
  description = "Static assets bucket name"
}

variable "source_bundle_url" {
  type        = string
  description = "Optional zip url for app source bundle"
  default     = null
}

variable "service_name" {
  type        = string
  description = "systemd service name"
  default     = "mentor-web-demo"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
