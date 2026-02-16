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
