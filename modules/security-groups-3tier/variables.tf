# Security Groups 3-Tier Module Variables

# ===========================
# Required Variables
# ===========================

variable "app_name" {
  description = "Name of the application (used for security group naming)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

# ===========================
# Tier Configuration
# ===========================

variable "create_alb_sg" {
  description = "Create Application Load Balancer security group"
  type        = bool
  default     = true
}

variable "create_web_tier" {
  description = "Create web tier security group"
  type        = bool
  default     = true
}

variable "create_api_tier" {
  description = "Create API tier security group"
  type        = bool
  default     = true
}

variable "create_db_tier" {
  description = "Create database tier security group"
  type        = bool
  default     = true
}

variable "create_cache_tier" {
  description = "Create cache tier security group (Redis/Memcached)"
  type        = bool
  default     = false
}

variable "create_bastion_sg" {
  description = "Create bastion/jump host security group"
  type        = bool
  default     = false
}

# ===========================
# Port Configuration
# ===========================

variable "web_tier_port" {
  description = "Port for web tier (e.g., 8080, 3000)"
  type        = number
  default     = 8080
}

variable "api_tier_port" {
  description = "Port for API tier (e.g., 8443, 4000)"
  type        = number
  default     = 8443
}

variable "db_port" {
  description = "Database port (PostgreSQL: 5432, MySQL: 3306, etc.)"
  type        = number
  default     = 5432
}

variable "cache_port" {
  description = "Cache port (Redis: 6379, Memcached: 11211)"
  type        = number
  default     = 6379
}

# ===========================
# ALB Configuration
# ===========================

variable "alb_ingress_cidr" {
  description = "CIDR block allowed to access ALB (0.0.0.0/0 for public, CloudFront CIDR for CDN)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "alb_ingress_cidr_description" {
  description = "Description of ALB ingress CIDR (for documentation)"
  type        = string
  default     = "internet"
}

variable "allow_http_on_alb" {
  description = "Allow HTTP on ALB (will redirect to HTTPS)"
  type        = bool
  default     = true
}

# ===========================
# Web Tier Configuration
# ===========================

variable "web_tier_needs_aws_access" {
  description = "Web tier needs access to AWS services (S3, DynamoDB, etc.)"
  type        = bool
  default     = false
}

# ===========================
# API Tier Configuration
# ===========================

variable "api_tier_needs_internet" {
  description = "API tier needs outbound internet access (for external APIs)"
  type        = bool
  default     = false
}

variable "allow_api_from_vpc" {
  description = "Allow API access from other services in VPC (microservices pattern)"
  type        = bool
  default     = false
}

# ===========================
# Bastion Configuration
# ===========================

variable "bastion_ingress_cidr" {
  description = "CIDR block allowed to SSH to bastion (corporate VPN/IP)"
  type        = string
  default     = "10.0.0.0/8"
}

variable "bastion_ingress_description" {
  description = "Description of bastion ingress CIDR"
  type        = string
  default     = "corporate VPN"
}

# ===========================
# Tags
# ===========================

variable "tags" {
  description = "Tags to apply to all security groups"
  type        = map(string)
  default     = {}
}
