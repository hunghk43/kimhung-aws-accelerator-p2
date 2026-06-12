variable "identifier" {
  type        = string
  description = "RDS instance identifier"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet ids for the DB subnet group"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups attached to the DB instance"
}

variable "db_name" {
  type        = string
  description = "Initial database name"
}

variable "username" {
  type        = string
  description = "Master username"
}

variable "password" {
  type        = string
  description = "Master password"
  sensitive   = true
}

variable "engine_version" {
  type        = string
  description = "MySQL engine version"
  default     = "8.0.42"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
  default     = 20
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
