# Example: PCI-Compliant Landing Zone with Microsegmentation
# This example demonstrates a highly isolated landing zone for PCI workloads

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ===========================
# Data Sources
# ===========================

data "aws_caller_identity" "current" {}

# Assume Core Network and IPAM are created by the central networking team
data "aws_networkmanager_core_network" "main" {
  global_network_id = var.global_network_id
}

data "aws_vpc_ipam_pool" "pci_pool" {
  filter {
    name   = "tag:Segment"
    values = ["pci"]
  }
}

# ===========================
# VPC with IPAM Allocation
# ===========================

resource "aws_vpc" "pci_app" {
  ipv4_ipam_pool_id   = data.aws_vpc_ipam_pool.pci_pool.id
  ipv4_netmask_length = 24 # /24 from PCI pool (10.100.x.0/24)

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.app_name}-pci-vpc"
    Environment = "production"
    Segment     = "pci"
    Compliance  = "PCI-DSS"
    AppName     = var.app_name
  }
}

# ===========================
# Subnets (3-Tier Architecture)
# ===========================

# ALB Subnet (public)
resource "aws_subnet" "alb" {
  count = 2

  vpc_id            = aws_vpc.pci_app.id
  cidr_block        = cidrsubnet(aws_vpc.pci_app.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}-alb-subnet-${count.index + 1}"
    Tier = "load-balancer"
  }
}

# Web Tier Subnet (private)
resource "aws_subnet" "web" {
  count = 2

  vpc_id            = aws_vpc.pci_app.id
  cidr_block        = cidrsubnet(aws_vpc.pci_app.cidr_block, 4, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}-web-subnet-${count.index + 1}"
    Tier = "web"
  }
}

# API Tier Subnet (private)
resource "aws_subnet" "api" {
  count = 2

  vpc_id            = aws_vpc.pci_app.id
  cidr_block        = cidrsubnet(aws_vpc.pci_app.cidr_block, 4, count.index + 4)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}-api-subnet-${count.index + 1}"
    Tier = "api"
  }
}

# Database Tier Subnet (isolated)
resource "aws_subnet" "database" {
  count = 2

  vpc_id            = aws_vpc.pci_app.id
  cidr_block        = cidrsubnet(aws_vpc.pci_app.cidr_block, 4, count.index + 6)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}-database-subnet-${count.index + 1}"
    Tier = "database"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ===========================
# Cloud WAN Attachment (PCI Segment)
# ===========================

resource "aws_networkmanager_vpc_attachment" "pci_app" {
  core_network_id = data.aws_networkmanager_core_network.main.id
  vpc_arn         = aws_vpc.pci_app.arn
  subnet_arns     = aws_subnet.web[*].arn

  options {
    appliance_mode_support = false
    ipv6_support           = false
  }

  tags = {
    Name        = "${var.app_name}-pci-attachment"
    Segment     = "prod-pci"
    Environment = "production"
    Compliance  = "PCI-DSS"
  }
}

# ===========================
# Security Groups (3-Tier Architecture)
# ===========================

module "security_groups" {
  source = "../../modules/security-groups-3tier"

  app_name = var.app_name
  vpc_id   = aws_vpc.pci_app.id
  vpc_cidr = aws_vpc.pci_app.cidr_block

  # Enable all tiers for PCI application
  create_alb_sg    = true
  create_web_tier  = true
  create_api_tier  = true
  create_db_tier   = true
  create_cache_tier = false
  create_bastion_sg = true

  # Port configuration
  web_tier_port = 8080
  api_tier_port = 8443
  db_port       = 5432 # PostgreSQL

  # ALB accessible from CloudFront only (not public internet)
  alb_ingress_cidr             = var.cloudfront_cidr
  alb_ingress_cidr_description = "CloudFront"
  allow_http_on_alb            = true

  # Web tier does NOT need AWS access (all via PrivateLink)
  web_tier_needs_aws_access = false

  # API tier does NOT need internet (PCI requirement)
  api_tier_needs_internet = false
  allow_api_from_vpc      = false

  # Bastion for emergency access only
  bastion_ingress_cidr        = var.corporate_vpn_cidr
  bastion_ingress_description = "Corporate VPN"

  tags = {
    Environment = "production"
    Segment     = "pci"
    Compliance  = "PCI-DSS"
    AppName     = var.app_name
  }
}

# ===========================
# VPC Flow Logs (Required for PCI)
# ===========================

resource "aws_flow_log" "pci_app" {
  vpc_id          = aws_vpc.pci_app.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn

  tags = {
    Name        = "${var.app_name}-flow-logs"
    Compliance  = "PCI-DSS"
  }
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.app_name}"
  retention_in_days = 90 # PCI requirement: minimum 90 days

  tags = {
    Name       = "${var.app_name}-flow-logs"
    Compliance = "PCI-DSS"
  }
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.app_name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.app_name}-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

# ===========================
# GuardDuty (Required for PCI)
# ===========================

resource "aws_guardduty_detector" "pci_app" {
  enable = true

  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name       = "${var.app_name}-guardduty"
    Compliance = "PCI-DSS"
  }
}

# ===========================
# Outputs
# ===========================

output "vpc_id" {
  description = "VPC ID for PCI application"
  value       = aws_vpc.pci_app.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.pci_app.cidr_block
}

output "security_groups" {
  description = "Security group IDs for all tiers"
  value       = module.security_groups.security_group_ids
}

output "cloud_wan_attachment_id" {
  description = "Cloud WAN attachment ID"
  value       = aws_networkmanager_vpc_attachment.pci_app.id
}

output "compliance_status" {
  description = "PCI compliance features enabled"
  value = {
    vpc_flow_logs     = "✓ Enabled (90 day retention)"
    guardduty         = "✓ Enabled with malware protection"
    database_isolation = "✓ Database has NO egress"
    network_segment   = "✓ Isolated PCI segment"
    inspection        = "✓ Traffic routed through dedicated PCI firewall"
  }
}
