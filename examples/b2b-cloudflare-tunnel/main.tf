# Example: B2B Integration via Cloudflare Tunnel
# Vendors can access S3, databases, Redis, and SSH bastion WITHOUT VPN
# Uses new Cloudflare feature: All ports and protocols (2025-10-28)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ===========================
# Data Sources
# ===========================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC for b2b-vendors segment
data "aws_vpc" "b2b_vendors" {
  filter {
    name   = "tag:Segment"
    values = ["b2b-vendors"]
  }
}

data "aws_subnets" "b2b_vendors_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.b2b_vendors.id]
  }
  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

# Existing database (from prod-data segment)
data "aws_db_instance" "production" {
  db_instance_identifier = var.database_identifier
}

# Existing Redis cluster (from prod-data segment)
data "aws_elasticache_replication_group" "production" {
  replication_group_id = var.redis_replication_group_id
}

# ===========================
# S3 Bucket for Vendor File Exchange
# ===========================

resource "aws_s3_bucket" "vendor_exchange" {
  bucket = "${var.company_name}-vendor-exchange"

  tags = {
    Name    = "${var.company_name}-vendor-exchange"
    Purpose = "Vendor file uploads/downloads via Cloudflare Tunnel"
  }
}

resource "aws_s3_bucket_versioning" "vendor_exchange" {
  bucket = aws_s3_bucket.vendor_exchange.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vendor_exchange" {
  bucket = aws_s3_bucket.vendor_exchange.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vendor_exchange" {
  bucket = aws_s3_bucket.vendor_exchange.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "vendor_exchange" {
  bucket = aws_s3_bucket.vendor_exchange.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 bucket policy (restrict to cloudflared task role only)
resource "aws_s3_bucket_policy" "vendor_exchange" {
  bucket = aws_s3_bucket.vendor_exchange.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.vendor_exchange.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.vendor_exchange.arn,
          "${aws_s3_bucket.vendor_exchange.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ===========================
# RDS Proxy for Vendor Database Access
# ===========================

resource "aws_db_proxy" "vendor_access" {
  name                   = "${var.company_name}-vendor-db-proxy"
  engine_family          = var.database_engine_family
  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "REQUIRED"
    secret_arn  = aws_secretsmanager_secret.vendor_db_readonly.arn
  }
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = data.aws_subnets.b2b_vendors_private.ids
  require_tls            = true

  tags = {
    Name    = "${var.company_name}-vendor-db-proxy"
    Purpose = "Vendor read-only database access"
  }
}

resource "aws_db_proxy_default_target_group" "vendor_access" {
  db_proxy_name = aws_db_proxy.vendor_access.name

  connection_pool_config {
    max_connections_percent      = 50
    max_idle_connections_percent = 25
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "vendor_access" {
  db_proxy_name         = aws_db_proxy.vendor_access.name
  target_group_name     = aws_db_proxy_default_target_group.vendor_access.name
  db_instance_identifier = data.aws_db_instance.production.id
}

# Secrets Manager secret for vendor database user
resource "aws_secretsmanager_secret" "vendor_db_readonly" {
  name                    = "${var.company_name}-vendor-db-readonly"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.company_name}-vendor-db-readonly"
  }
}

resource "aws_secretsmanager_secret_version" "vendor_db_readonly" {
  secret_id = aws_secretsmanager_secret.vendor_db_readonly.id
  secret_string = jsonencode({
    username = "vendor_readonly"
    password = random_password.vendor_db_password.result
  })
}

resource "random_password" "vendor_db_password" {
  length  = 32
  special = true
}

# IAM role for RDS Proxy
resource "aws_iam_role" "rds_proxy" {
  name = "${var.company_name}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.company_name}-rds-proxy-role"
  }
}

resource "aws_iam_role_policy" "rds_proxy_secrets" {
  name = "${var.company_name}-rds-proxy-secrets"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = aws_secretsmanager_secret.vendor_db_readonly.arn
    }]
  })
}

# ===========================
# Security Groups
# ===========================

# Allow cloudflared to access RDS Proxy
resource "aws_security_group_rule" "rds_proxy_from_cloudflared" {
  type                     = "ingress"
  from_port                = data.aws_db_instance.production.port
  to_port                  = data.aws_db_instance.production.port
  protocol                 = "tcp"
  source_security_group_id = module.cloudflare_tunnel.cloudflared_security_group_id
  security_group_id        = data.aws_db_instance.production.vpc_security_groups[0]
  description              = "Allow cloudflared to access RDS Proxy for vendor access"
}

# Allow cloudflared to access Redis
resource "aws_security_group_rule" "redis_from_cloudflared" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = module.cloudflare_tunnel.cloudflared_security_group_id
  security_group_id        = data.aws_elasticache_replication_group.production.security_group_ids[0]
  description              = "Allow cloudflared to access Redis for vendor access"
}

# ===========================
# Cloudflare Tunnel
# ===========================

# Generate tunnel secret
resource "random_password" "tunnel_secret" {
  length  = 32
  special = false
}

module "cloudflare_tunnel" {
  source = "../../modules/cloudflare-tunnel-b2b"

  tunnel_name_prefix      = var.company_name
  cloudflare_account_id   = var.cloudflare_account_id
  cloudflare_zone_id      = var.cloudflare_zone_id
  cloudflare_tunnel_token = var.cloudflare_tunnel_token
  tunnel_secret           = base64encode(random_password.tunnel_secret.result)

  vpc_id     = data.aws_vpc.b2b_vendors.id
  vpc_cidr   = data.aws_vpc.b2b_vendors.cidr_block
  subnet_ids = data.aws_subnets.b2b_vendors_private.ids

  # Enable S3 access
  enable_s3_access     = true
  s3_tunnel_hostname   = "s3.${var.tunnel_domain}"
  s3_bucket_name       = aws_s3_bucket.vendor_exchange.id

  # Enable database access
  enable_database_access       = true
  database_tunnel_hostname     = "db.${var.tunnel_domain}"
  database_endpoint            = aws_db_proxy.vendor_access.endpoint
  database_port                = data.aws_db_instance.production.port
  database_security_group_id   = data.aws_db_instance.production.vpc_security_groups[0]

  # Enable Redis access
  enable_redis_access       = true
  redis_tunnel_hostname     = "redis.${var.tunnel_domain}"
  redis_endpoint            = data.aws_elasticache_replication_group.production.configuration_endpoint_address
  redis_port                = 6379
  redis_security_group_id   = data.aws_elasticache_replication_group.production.security_group_ids[0]

  # Enable SSH bastion (optional)
  enable_ssh_bastion         = var.enable_ssh_bastion
  ssh_tunnel_hostname        = "ssh.${var.tunnel_domain}"
  bastion_host               = var.bastion_host_ip
  bastion_security_group_id  = var.bastion_security_group_id

  # API endpoints
  api_endpoints = [
    {
      hostname = "api.${var.tunnel_domain}"
      service  = "http://${var.internal_api_endpoint}"
    }
  ]

  # Access control
  allowed_identity_providers = var.cloudflare_idp_ids
  allowed_vendor_emails      = var.vendor_emails
  allowed_vendor_domains     = var.vendor_domains
  session_duration           = "8h"

  # ECS configuration
  cloudflared_desired_count = 2  # High availability
  cloudflared_cpu           = "512"
  cloudflared_memory        = "1024"

  # Monitoring
  alarm_sns_topic_arn = var.alarm_sns_topic_arn

  tags = {
    Environment = "production"
    Purpose     = "B2B vendor access via Cloudflare Tunnel"
    ManagedBy   = "Terraform"
  }
}

# ===========================
# CloudWatch Alarms
# ===========================

resource "aws_cloudwatch_metric_alarm" "s3_4xx_errors" {
  alarm_name          = "${var.company_name}-s3-vendor-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "High number of S3 4xx errors from vendor access"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    BucketName = aws_s3_bucket.vendor_exchange.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_proxy_connections" {
  alarm_name          = "${var.company_name}-rds-proxy-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 50
  alarm_description   = "High number of RDS Proxy connections from vendors"
  alarm_actions       = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  dimensions = {
    DBProxyName = aws_db_proxy.vendor_access.name
  }
}

# ===========================
# CloudTrail for S3 API Logging
# ===========================

resource "aws_cloudtrail" "vendor_s3_access" {
  name                          = "${var.company_name}-vendor-s3-access"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = false
  is_multi_region_trail         = false

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.vendor_exchange.arn}/*"]
    }
  }

  tags = {
    Name    = "${var.company_name}-vendor-s3-access"
    Purpose = "Log all vendor S3 operations"
  }
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.company_name}-vendor-cloudtrail-logs"

  tags = {
    Name = "${var.company_name}-vendor-cloudtrail-logs"
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# ===========================
# Outputs
# ===========================

output "cloudflare_tunnel_summary" {
  description = "Summary of Cloudflare Tunnel configuration"
  value       = module.cloudflare_tunnel.tunnel_summary
}

output "vendor_connection_instructions" {
  description = "Instructions for vendors to connect"
  value       = module.cloudflare_tunnel.vendor_connection_instructions
}

output "s3_bucket_name" {
  description = "S3 bucket name for vendor file exchange"
  value       = aws_s3_bucket.vendor_exchange.id
}

output "s3_access_url" {
  description = "URL for vendor S3 access"
  value       = "https://s3.${var.tunnel_domain}"
}

output "database_access_url" {
  description = "URL for vendor database access"
  value       = "tcp://db.${var.tunnel_domain}:${data.aws_db_instance.production.port}"
}

output "redis_access_url" {
  description = "URL for vendor Redis access"
  value       = "tcp://redis.${var.tunnel_domain}:6379"
}

output "api_access_url" {
  description = "URL for vendor API access"
  value       = "https://api.${var.tunnel_domain}"
}
