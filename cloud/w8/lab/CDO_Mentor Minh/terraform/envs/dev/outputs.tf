output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "ec2_public_dns" {
  value = module.ec2.public_dns
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "s3_assets_bucket_name" {
  value = module.storage.bucket_name
}

output "cloudfront_url" {
  value       = "https://${module.cdn.domain_name}"
  description = "URL truy cập web app qua CloudFront"
}
