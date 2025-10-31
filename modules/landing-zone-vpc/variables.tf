# Landing Zone VPC Module Variables

# ===========================
# Required Variables
# ===========================

variable "vpc_name" {
  description = "Name for the landing zone VPC and related resources"
  type        = string
}

variable "region" {
  description = "AWS region where the landing zone VPC will be deployed"
  type        = string
}

# ===========================
# VPC CIDR Configuration (Choose One)
# ===========================

variable "vpc_cidr" {
  description = "CIDR block for the landing zone VPC (use this OR ipam_pool_id, not both)"
  type        = string
  default     = null

  validation {
    condition     = var.vpc_cidr == null || can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "ipam_pool_id" {
  description = "IPAM pool ID for automatic CIDR allocation (use this OR vpc_cidr, not both)"
  type        = string
  default     = null
}

variable "ipam_netmask_length" {
  description = "Netmask length for IPAM-allocated CIDR (only used if ipam_pool_id is set)"
  type        = number
  default     = 16
}

# ===========================
# Cloud WAN Configuration
# ===========================

variable "segment_name" {
  description = "Cloud WAN segment name for VPC attachment (prod, non-prod, or shared)"
  type        = string

  validation {
    condition     = contains(["prod", "non-prod", "shared"], var.segment_name)
    error_message = "Segment name must be one of: prod, non-prod, shared"
  }
}

variable "core_network_id" {
  description = "ID of the Cloud WAN Core Network to attach to"
  type        = string
}

variable "core_network_arn" {
  description = "ARN of the Cloud WAN Core Network for routing"
  type        = string
}

# ===========================
# Optional Variables
# ===========================

variable "multi_az" {
  description = "Deploy across multiple availability zones (2 AZs)"
  type        = bool
  default     = false
}

variable "create_test_instance" {
  description = "Create a t2.micro EC2 instance for connectivity testing"
  type        = bool
  default     = true
}

variable "enable_ssh" {
  description = "Allow SSH access to test instances from RFC1918 ranges"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs for EC2 instance console output"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
