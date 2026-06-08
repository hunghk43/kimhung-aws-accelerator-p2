variable "aws_region" {
  description = "AWS region for application resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name used in resource tags and names"
  type        = string
  default     = "mentor-web-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "admin_cidr" {
  description = "Your IP/CIDR for SSH access to EC2"
  type        = string
}

variable "key_name" {
  description = "Optional EC2 key pair name"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for the web app"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port exposed by the Node.js app"
  type        = number
  default     = 8000
}

variable "mysql_db_name" {
  description = "MySQL database name"
  type        = string
  default     = "mentor_web"
}

variable "mysql_master_username" {
  description = "MySQL master username"
  type        = string
  default     = "admin"
}

variable "mysql_master_password" {
  description = "MySQL master password"
  type        = string
  sensitive   = true
}

variable "mysql_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0.42"
}

variable "mysql_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "mysql_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 20
}

variable "s3_assets_bucket_name" {
  description = "S3 bucket name for static assets"
  type        = string
}

variable "source_bundle_url" {
  description = "Optional URL to a zip bundle containing the app source for EC2 bootstrap"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
