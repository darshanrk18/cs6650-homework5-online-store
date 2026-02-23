variable "service_name" {
  type        = string
  description = "Base name for ECS resources"
}

variable "image" {
  type        = string
  description = "ECR image URI (with tag)"
}

variable "container_port" {
  type        = number
  description = "Port the container listens on"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for Fargate tasks"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security groups for Fargate tasks"
}

variable "execution_role_arn" {
  type        = string
  description = "ECS Task Execution Role ARN"
}

variable "task_role_arn" {
  type        = string
  description = "IAM Role ARN for task"
}

variable "log_group_name" {
  type        = string
  description = "CloudWatch log group name"
}

variable "ecs_count" {
  type        = number
  default     = 1
  description = "Desired Fargate task count"
}

variable "region" {
  type        = string
  description = "AWS region (for awslogs driver)"
}

variable "cpu" {
  type        = string
  default     = "256"
  description = "vCPU units"
}

variable "memory" {
  type        = string
  default     = "512"
  description = "Memory (MiB)"
}

variable "target_group_arn" {
  type        = string
  default     = null
  description = "ARN of ALB target group to attach; if set, service is registered with the load balancer"
}

variable "container_name" {
  type        = string
  default     = null
  description = "Container name for load_balancer block; required when target_group_arn is set"
}

variable "health_check_grace_period_seconds" {
  type        = number
  default     = 60
  description = "Grace period before health check failures count (for ALB target health)"
}

variable "min_capacity" {
  type        = number
  default     = 2
  description = "Minimum number of tasks (for auto scaling)"
}

variable "max_capacity" {
  type        = number
  default     = 4
  description = "Maximum number of tasks (for auto scaling)"
}

variable "autoscaling_cpu_target" {
  type        = number
  default     = 70.0
  description = "Target average CPU utilization % for auto scaling"
}
