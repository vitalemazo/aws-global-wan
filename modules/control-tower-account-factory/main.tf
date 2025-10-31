# Control Tower Account Factory Module
# Automates account provisioning with landing zone VPC, Cloud WAN attachment, and baseline security

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source to get current account information
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# ===========================
# Account Creation (Service Catalog)
# ===========================

# Note: In production, use AWS Service Catalog Product for Account Factory
# This module focuses on the post-provisioning landing zone setup

# ===========================
# Landing Zone VPC with IPAM
# ===========================

# Determine IPAM pool based on environment
locals {
  ipam_pool_id = (
    var.environment == "production" ? var.ipam_production_pool_id :
    var.environment == "non-production" ? var.ipam_non_production_pool_id :
    var.environment == "shared" ? var.ipam_shared_services_pool_id :
    null
  )

  cloud_wan_segment = (
    var.environment == "production" ? "prod" :
    var.environment == "non-production" ? "non-prod" :
    var.environment == "shared" ? "shared" :
    "shared"
  )
}

# Landing Zone VPC
module "landing_zone_vpc" {
  source = "../landing-zone-vpc"

  # Basic configuration
  vpc_name     = "${var.account_name}-${var.environment}-vpc"
  region       = var.region
  segment_name = local.cloud_wan_segment

  # IPAM-based CIDR allocation
  ipam_pool_id        = local.ipam_pool_id
  ipam_netmask_length = var.vpc_netmask_length

  # Cloud WAN integration
  core_network_id  = var.core_network_id
  core_network_arn = var.core_network_arn

  # High availability
  multi_az = var.enable_multi_az

  # Test instance (optional)
  create_test_instance   = var.create_test_instance
  enable_ssh             = false
  enable_cloudwatch_logs = var.enable_cloudwatch_logs

  # Tags
  tags = merge(var.tags, {
    Account     = var.account_name
    Environment = var.environment
    ManagedBy   = "ControlTower-AccountFactory"
  })
}

# ===========================
# VPC Flow Logs (Baseline Security)
# ===========================

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name              = "/aws/vpc/flowlogs/${var.account_name}-${var.environment}"
  retention_in_days = var.flow_logs_retention_days

  tags = merge(var.tags, {
    Name = "${var.account_name}-vpc-flow-logs"
  })
}

# IAM role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "${var.account_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Logs
resource "aws_flow_log" "main" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  vpc_id          = module.landing_zone_vpc.vpc_id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.vpc_flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn

  tags = merge(var.tags, {
    Name = "${var.account_name}-vpc-flow-logs"
  })
}

# ===========================
# GuardDuty (Baseline Security)
# ===========================

resource "aws_guardduty_detector" "main" {
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = var.guardduty_finding_frequency

  datasources {
    s3_logs {
      enable = var.guardduty_enable_s3_logs
    }
    kubernetes {
      audit_logs {
        enable = var.guardduty_enable_kubernetes_logs
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.account_name}-guardduty"
  })
}

# ===========================
# Security Hub (Baseline Security)
# ===========================

resource "aws_securityhub_account" "main" {
  count = var.enable_security_hub ? 1 : 0

  enable_default_standards = var.security_hub_enable_default_standards

  depends_on = [aws_guardduty_detector.main]
}

# Enable CIS AWS Foundations Benchmark
resource "aws_securityhub_standards_subscription" "cis" {
  count = var.enable_security_hub && var.security_hub_enable_cis ? 1 : 0

  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.4.0"

  depends_on = [aws_securityhub_account.main]
}

# Enable AWS Foundational Security Best Practices
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count = var.enable_security_hub && var.security_hub_enable_aws_foundational ? 1 : 0

  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"

  depends_on = [aws_securityhub_account.main]
}

# ===========================
# AWS Config (Baseline Compliance)
# ===========================

# S3 bucket for Config (optional, can use organization bucket)
resource "aws_s3_bucket" "config" {
  count = var.enable_config && var.config_use_account_bucket ? 1 : 0

  bucket = "${var.account_name}-config-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.account_name}-config-bucket"
  })
}

resource "aws_s3_bucket_versioning" "config" {
  count = var.enable_config && var.config_use_account_bucket ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for Config
resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0

  name = "${var.account_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/ConfigRole"]

  tags = var.tags
}

# Config Recorder
resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config ? 1 : 0

  name     = "${var.account_name}-config-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

# Config Delivery Channel
resource "aws_config_delivery_channel" "main" {
  count = var.enable_config ? 1 : 0

  name           = "${var.account_name}-config-delivery"
  s3_bucket_name = var.config_use_account_bucket ? aws_s3_bucket.config[0].id : var.config_organization_bucket

  depends_on = [aws_config_configuration_recorder.main]
}

# Start Config Recorder
resource "aws_config_configuration_recorder_status" "main" {
  count = var.enable_config ? 1 : 0

  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}
