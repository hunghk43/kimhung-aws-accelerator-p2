variable "bucket_name" {
  type        = string
  description = "Name of the static assets bucket"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
