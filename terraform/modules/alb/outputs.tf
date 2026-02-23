output "target_group_arn" {
  description = "ARN of the target group for ECS service"
  value       = aws_lb_target_group.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the ALB (use for load testing: http://<dns_name>)"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = aws_lb.this.zone_id
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}
