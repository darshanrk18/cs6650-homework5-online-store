variable "service_name" {
  type        = string
  description = "Base name for security group"
}

variable "container_port" {
  type        = number
  description = "Port to allow in the security group"
}

variable "cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDRs allowed to reach the service"
}
