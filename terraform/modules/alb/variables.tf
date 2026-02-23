variable "service_name" {
  type        = string
  description = "Name prefix for ALB and target group"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for ALB and target group"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for ALB (typically public)"
}

variable "container_port" {
  type        = number
  default     = 8080
  description = "Target group port (container port)"
}

variable "task_security_group_id" {
  type        = string
  description = "Security group ID of ECS tasks; ALB will be allowed to send traffic to this SG on container_port"
}
