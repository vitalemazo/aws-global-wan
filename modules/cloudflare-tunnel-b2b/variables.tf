# Cloudflare Tunnel B2B Module Variables

# ===========================
# Required Variables
# ===========================

variable "tunnel_name_prefix" {
  description = "Prefix for tunnel and resource names"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for Access applications"
  type        = string
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare tunnel token (sensitive)"
  type        = string
  sensitive   = true
}

variable "tunnel_secret" {
  description = "Cloudflare tunnel secret (32-byte base64 encoded)"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID where cloudflared will run"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for cloudflared ECS tasks"
  type        = list(string)
}

# ===========================
# Feature Toggles
# ===========================

variable "enable_s3_access" {
  description = "Enable S3 bucket access via tunnel"
  type        = bool
  default     = false
}

variable "enable_database_access" {
  description = "Enable database access via tunnel"
  type        = bool
  default     = false
}

variable "enable_redis_access" {
  description = "Enable Redis access via tunnel"
  type        = bool
  default     = false
}

variable "enable_ssh_bastion" {
  description = "Enable SSH bastion access via tunnel"
  type        = bool
  default     = false
}

variable "enable_time_limited_access" {
  description = "Enable time-limited access policies"
  type        = bool
  default     = false
}

variable "enable_container_insights" {
  description = "Enable Container Insights for ECS cluster"
  type        = bool
  default     = true
}

# ===========================
# S3 Configuration
# ===========================

variable "s3_tunnel_hostname" {
  description = "Hostname for S3 tunnel access (e.g., s3.tunnel.company.com)"
  type        = string
  default     = ""
}

variable "s3_bucket_name" {
  description = "S3 bucket name for vendor access"
  type        = string
  default     = ""
}

variable "s3_proxy_image" {
  description = "Docker image for S3 proxy sidecar"
  type        = string
  default     = "public.ecr.aws/aws-samples/s3-presigned-url-proxy:latest"
}

# ===========================
# Database Configuration
# ===========================

variable "database_tunnel_hostname" {
  description = "Hostname for database tunnel access (e.g., db.tunnel.company.com)"
  type        = string
  default     = ""
}

variable "database_endpoint" {
  description = "Database endpoint (RDS Proxy or RDS instance)"
  type        = string
  default     = ""
}

variable "database_port" {
  description = "Database port (e.g., 5432 for PostgreSQL, 3306 for MySQL)"
  type        = number
  default     = 5432
}

variable "database_security_group_id" {
  description = "Security group ID of the database"
  type        = string
  default     = ""
}

# ===========================
# Redis Configuration
# ===========================

variable "redis_tunnel_hostname" {
  description = "Hostname for Redis tunnel access (e.g., redis.tunnel.company.com)"
  type        = string
  default     = ""
}

variable "redis_endpoint" {
  description = "Redis endpoint (ElastiCache cluster)"
  type        = string
  default     = ""
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "redis_security_group_id" {
  description = "Security group ID of the Redis cluster"
  type        = string
  default     = ""
}

# ===========================
# SSH Bastion Configuration
# ===========================

variable "ssh_tunnel_hostname" {
  description = "Hostname for SSH bastion access (e.g., ssh.tunnel.company.com)"
  type        = string
  default     = ""
}

variable "bastion_host" {
  description = "Bastion host private IP or DNS"
  type        = string
  default     = ""
}

variable "bastion_security_group_id" {
  description = "Security group ID of the bastion host"
  type        = string
  default     = ""
}

# ===========================
# API Endpoints Configuration
# ===========================

variable "api_endpoints" {
  description = "List of API endpoints to expose via tunnel"
  type = list(object({
    hostname = string
    service  = string
    path     = optional(string)
  }))
  default = []
}

# ===========================
# Cloudflare Access Configuration
# ===========================

variable "allowed_identity_providers" {
  description = "List of identity provider IDs (e.g., Google, Okta, Azure AD)"
  type        = list(string)
  default     = []
}

variable "allowed_vendor_emails" {
  description = "List of vendor email addresses allowed to access"
  type        = list(string)
  default     = []
}

variable "allowed_vendor_domains" {
  description = "List of vendor email domains allowed to access (e.g., vendor.com)"
  type        = list(string)
  default     = []
}

variable "allowed_access_groups" {
  description = "List of Cloudflare Access group IDs allowed to access"
  type        = list(string)
  default     = []
}

variable "time_limited_vendor_emails" {
  description = "List of vendor emails with time-limited access"
  type        = list(string)
  default     = []
}

variable "session_duration" {
  description = "Session duration for Access applications (e.g., 8h, 4h, 24h)"
  type        = string
  default     = "8h"
}

variable "cloudflare_tags" {
  description = "Tags for Cloudflare resources"
  type        = list(string)
  default     = ["b2b", "vendor-access"]
}

# ===========================
# ECS Configuration
# ===========================

variable "cloudflared_version" {
  description = "Cloudflared Docker image version"
  type        = string
  default     = "latest"
}

variable "cloudflared_cpu" {
  description = "CPU units for cloudflared task (256 = 0.25 vCPU)"
  type        = string
  default     = "256"
}

variable "cloudflared_memory" {
  description = "Memory for cloudflared task (MB)"
  type        = string
  default     = "512"
}

variable "cloudflared_desired_count" {
  description = "Desired number of cloudflared tasks (for high availability)"
  type        = number
  default     = 2
}

variable "metrics_port" {
  description = "Port for cloudflared metrics endpoint"
  type        = number
  default     = 2000
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

# ===========================
# Monitoring Configuration
# ===========================

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
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
