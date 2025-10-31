# Variables for General Production Landing Zone Example

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "web-app"
}

variable "global_network_id" {
  description = "ID of the AWS Cloud WAN Global Network"
  type        = string
}

variable "enable_cache" {
  description = "Enable Redis/Memcached cache tier"
  type        = bool
  default     = false
}
