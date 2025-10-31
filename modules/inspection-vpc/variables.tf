# Inspection VPC Module Variables

# ===========================
# Required Variables
# ===========================

variable "vpc_name" {
  description = "Name for the inspection VPC and related resources"
  type        = string
}

variable "region" {
  description = "AWS region where the inspection VPC will be deployed"
  type        = string
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
# VPC CIDR Configuration (Choose One)
# ===========================

variable "vpc_cidr" {
  description = "CIDR block for the inspection VPC (use this OR ipam_pool_id, not both)"
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
  default     = 20
}

# ===========================
# Subnet Configuration (Optional - auto-calculated if using IPAM)
# ===========================

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (NAT Gateway) - auto-calculated if using IPAM"
  type        = string
  default     = null
}

variable "firewall_subnet_cidr" {
  description = "CIDR block for the firewall subnet (Network Firewall endpoints) - auto-calculated if using IPAM"
  type        = string
  default     = null
}

variable "attachment_subnet_cidr" {
  description = "CIDR block for the attachment subnet (Cloud WAN) - auto-calculated if using IPAM"
  type        = string
  default     = null
}

# ===========================
# Optional Variables
# ===========================

variable "multi_az" {
  description = "Deploy across multiple availability zones for high availability (2 AZs)"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Availability Zone for single-AZ deployment (leave empty for automatic selection, ignored if multi_az is true)"
  type        = string
  default     = ""
}

variable "segment_name" {
  description = "Cloud WAN segment name for attachment tagging"
  type        = string
  default     = "shared"
}

variable "network_function_group_name" {
  description = "Network function group name for inspection routing"
  type        = string
  default     = "inspection"
}

variable "enable_firewall_logging" {
  description = "Enable AWS Network Firewall logging to S3 (increases cost)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
