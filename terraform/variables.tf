variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "Region to deploy into"
}

variable "ecr_repository_name" {
  type        = string
  default     = "product-api"
  description = "ECR repository name"
}

variable "service_name" {
  type        = string
  default     = "product-api"
  description = "Base name for ECS service and related resources"
}

variable "container_port" {
  type        = number
  default     = 8080
  description = "Port the Product API listens on"
}

variable "ecs_count" {
  type        = number
  default     = 1
  description = "Desired Fargate task count"
}

variable "log_retention_days" {
  type        = number
  default     = 7
  description = "CloudWatch log retention in days"
}
