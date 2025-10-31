# Variables for B2B Cloudflare Tunnel Example

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "company_name" {
  description = "Company name (used for resource naming)"
  type        = string
  default     = "acme"
}

# ===========================
# Cloudflare Configuration
# ===========================

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID (for your domain)"
  type        = string
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare tunnel token (get from Cloudflare dashboard)"
  type        = string
  sensitive   = true
}

variable "tunnel_domain" {
  description = "Base domain for tunnel hostnames (e.g., tunnel.company.com)"
  type        = string
  default     = "tunnel.company.com"
}

variable "cloudflare_idp_ids" {
  description = "List of Cloudflare identity provider IDs (Google, Okta, etc.)"
  type        = list(string)
  default     = []
}

# ===========================
# Vendor Access Control
# ===========================

variable "vendor_emails" {
  description = "List of vendor email addresses allowed to access"
  type        = list(string)
  default = [
    "vendor1@example.com",
    "vendor2@example.com"
  ]
}

variable "vendor_domains" {
  description = "List of vendor email domains allowed to access"
  type        = list(string)
  default = [
    "vendor.com",
    "partner-company.com"
  ]
}

# ===========================
# Database Configuration
# ===========================

variable "database_identifier" {
  description = "RDS database instance identifier"
  type        = string
}

variable "database_engine_family" {
  description = "Database engine family (POSTGRESQL, MYSQL, SQLSERVER)"
  type        = string
  default     = "POSTGRESQL"
}

# ===========================
# Redis Configuration
# ===========================

variable "redis_replication_group_id" {
  description = "ElastiCache replication group ID"
  type        = string
}

# ===========================
# SSH Bastion Configuration
# ===========================

variable "enable_ssh_bastion" {
  description = "Enable SSH bastion access via tunnel"
  type        = bool
  default     = false
}

variable "bastion_host_ip" {
  description = "Bastion host private IP address"
  type        = string
  default     = ""
}

variable "bastion_security_group_id" {
  description = "Bastion host security group ID"
  type        = string
  default     = ""
}

# ===========================
# API Configuration
# ===========================

variable "internal_api_endpoint" {
  description = "Internal API endpoint (e.g., internal-alb.us-east-1.elb.amazonaws.com)"
  type        = string
}

# ===========================
# Monitoring Configuration
# ===========================

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = ""
}
