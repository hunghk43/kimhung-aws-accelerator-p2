variable "name_prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones used by the subnets"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for private subnets"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
