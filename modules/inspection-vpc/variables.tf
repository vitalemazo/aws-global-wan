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

variable "vpc_cidr" {
  description = "CIDR block for the inspection VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
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
# Subnet Configuration
# ===========================

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (NAT Gateway)"
  type        = string
}

variable "firewall_subnet_cidr" {
  description = "CIDR block for the firewall subnet (Network Firewall endpoints)"
  type        = string
}

variable "attachment_subnet_cidr" {
  description = "CIDR block for the attachment subnet (Cloud WAN)"
  type        = string
}

# ===========================
# Optional Variables
# ===========================

variable "availability_zone" {
  description = "Availability Zone for single-AZ deployment (leave empty for automatic selection)"
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
