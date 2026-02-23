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
  default     = 2
  description = "Desired Fargate task count (initial; auto scaling applies min/max)"
}

variable "health_check_grace_period_seconds" {
  type        = number
  default     = 60
  description = "Grace period for ECS service before ALB health checks count"
}

variable "ecs_min_capacity" {
  type        = number
  default     = 2
  description = "Minimum number of ECS tasks (auto scaling)"
}

variable "ecs_max_capacity" {
  type        = number
  default     = 4
  description = "Maximum number of ECS tasks (auto scaling)"
}

variable "ecs_autoscaling_cpu_target" {
  type        = number
  default     = 70
  description = "Target average CPU % for ECS auto scaling"
}

variable "log_retention_days" {
  type        = number
  default     = 7
  description = "CloudWatch log retention in days"
}
