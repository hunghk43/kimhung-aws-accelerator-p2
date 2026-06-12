output "domain_name" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "CloudFront domain name — truy cập qua https://<domain_name>"
}

output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}
