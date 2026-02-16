variable "service_name" {
  type        = string
  description = "Used to name the log group"
}

variable "retention_in_days" {
  type        = number
  default     = 7
  description = "How long to keep logs"
}
