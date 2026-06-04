output "alb_dns_name" {
  description = "Public DNS name of the ALB."
  value       = aws_lb.app.dns_name
}

output "app_url" {
  description = "Public URL of the demo app."
  value       = "http://${aws_lb.app.dns_name}"
}

output "ec2_instance_id" {
  description = "Instance ID of the kind host."
  value       = aws_instance.kind_host.id
}

output "target_group_arn" {
  description = "ARN of the ALB target group."
  value       = aws_lb_target_group.app.arn
}

output "ssm_note" {
  description = "Use AWS Systems Manager Session Manager instead of SSH."
  value       = "Connect via SSM Session Manager; port 22 is intentionally closed."
}
