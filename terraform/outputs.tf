output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "ecr_repository_url" {
  description = "ECR repository URL (image base)"
  value       = module.ecr.repository_url
}

output "aws_region" {
  description = "AWS region used for deployment"
  value       = var.aws_region
}

# Part 3: use this URL for load testing (Locust host)
output "alb_dns_name" {
  description = "ALB DNS name; use as host for load tests: http://<this_value>"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "Full URL for the Product API via ALB (port 80)"
  value       = "http://${module.alb.alb_dns_name}"
}
