# W8 Day 1 — Terraform Demo
# Demo tạo S3 bucket đơn giản (không cần EC2, tránh tốn tiền)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}

# Resource: S3 bucket
resource "aws_s3_bucket" "portfolio" {
  bucket = "${var.project_name}-${var.env}-${random_id.suffix.hex}"

  tags = local.common_tags
}

# Tắt public access (best practice)
resource "aws_s3_bucket_public_access_block" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Random suffix để tránh trùng tên bucket (globally unique)
resource "random_id" "suffix" {
  byte_length = 4
}
