variable "name_prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "ec2_public_dns" {
  type        = string
  description = "Public DNS of the EC2 instance (origin)"
}

variable "app_port" {
  type        = number
  description = "Port the app listens on"
  default     = 8000
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
