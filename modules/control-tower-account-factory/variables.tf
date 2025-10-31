# Control Tower Account Factory Module Variables

# ===========================
# Account Configuration
# ===========================

variable "account_name" {
  description = "Name of the AWS account being provisioned"
  type        = string
}

variable "environment" {
  description = "Environment type: production, non-production, or shared"
  type        = string

  validation {
    condition     = contains(["production", "non-production", "shared"], var.environment)
    error_message = "Environment must be one of: production, non-production, shared"
  }
}

variable "region" {
  description = "AWS region for landing zone VPC deployment"
  type        = string
}

# ===========================
# IPAM Configuration
# ===========================

variable "ipam_production_pool_id" {
  description = "IPAM pool ID for production environment"
  type        = string
}

variable "ipam_non_production_pool_id" {
  description = "IPAM pool ID for non-production environment"
  type        = string
}

variable "ipam_shared_services_pool_id" {
  description = "IPAM pool ID for shared services environment"
  type        = string
}

variable "vpc_netmask_length" {
  description = "Netmask length for VPC CIDR allocation from IPAM"
  type        = number
  default     = 16
}

# ===========================
# Cloud WAN Configuration
# ===========================

variable "core_network_id" {
  description = "ID of the Cloud WAN Core Network"
  type        = string
}

variable "core_network_arn" {
  description = "ARN of the Cloud WAN Core Network"
  type        = string
}

# ===========================
# VPC Configuration
# ===========================

variable "enable_multi_az" {
  description = "Deploy landing zone VPC across multiple availability zones"
  type        = bool
  default     = false
}

variable "create_test_instance" {
  description = "Create EC2 test instance for connectivity validation"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs for EC2 instances"
  type        = bool
  default     = false
}

# ===========================
# VPC Flow Logs
# ===========================

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for the landing zone VPC"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "CloudWatch Logs retention period for VPC Flow Logs"
  type        = number
  default     = 30
}

# ===========================
# GuardDuty Configuration
# ===========================

variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty threat detection"
  type        = bool
  default     = true
}

variable "guardduty_finding_frequency" {
  description = "GuardDuty finding publishing frequency"
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.guardduty_finding_frequency)
    error_message = "Must be one of: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS"
  }
}

variable "guardduty_enable_s3_logs" {
  description = "Enable S3 protection in GuardDuty"
  type        = bool
  default     = true
}

variable "guardduty_enable_kubernetes_logs" {
  description = "Enable Kubernetes audit logs in GuardDuty"
  type        = bool
  default     = false
}

# ===========================
# Security Hub Configuration
# ===========================

variable "enable_security_hub" {
  description = "Enable AWS Security Hub"
  type        = bool
  default     = true
}

variable "security_hub_enable_default_standards" {
  description = "Enable default Security Hub standards"
  type        = bool
  default     = true
}

variable "security_hub_enable_cis" {
  description = "Enable CIS AWS Foundations Benchmark"
  type        = bool
  default     = true
}

variable "security_hub_enable_aws_foundational" {
  description = "Enable AWS Foundational Security Best Practices"
  type        = bool
  default     = true
}

# ===========================
# AWS Config Configuration
# ===========================

variable "enable_config" {
  description = "Enable AWS Config for compliance monitoring"
  type        = bool
  default     = true
}

variable "config_use_account_bucket" {
  description = "Create account-specific S3 bucket for Config (false to use organization bucket)"
  type        = bool
  default     = false
}

variable "config_organization_bucket" {
  description = "S3 bucket name for Config in organization account (used if config_use_account_bucket is false)"
  type        = string
  default     = ""
}

# ===========================
# Tags
# ===========================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
