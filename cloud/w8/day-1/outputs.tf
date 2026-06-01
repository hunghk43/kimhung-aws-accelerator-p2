# Output values — hiển thị sau khi apply xong

output "bucket_name" {
  description = "Tên S3 bucket đã tạo"
  value       = aws_s3_bucket.portfolio.bucket
}

output "bucket_arn" {
  description = "ARN của S3 bucket"
  value       = aws_s3_bucket.portfolio.arn
}

output "bucket_region" {
  description = "Region của bucket"
  value       = aws_s3_bucket.portfolio.region
}
