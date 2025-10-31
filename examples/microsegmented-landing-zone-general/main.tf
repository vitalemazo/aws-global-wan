# Example: General Production Landing Zone with Microsegmentation
# This example demonstrates a standard production application with moderate isolation

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

# Assume Core Network and IPAM are created by central networking team
data "aws_networkmanager_core_network" "main" {
  global_network_id = var.global_network_id
}

data "aws_vpc_ipam_pool" "prod_general_pool" {
  filter {
    name   = "tag:Segment"
    values = ["prod-general"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# ===========================
# VPC with IPAM Allocation
# ===========================

resource "aws_vpc" "app" {
  ipv4_ipam_pool_id   = data.aws_vpc_ipam_pool.prod_general_pool.id
  ipv4_netmask_length = 24 # /24 from prod-general pool

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.app_name}-vpc"
    Environment = "production"
    Segment     = "prod-general"
    AppName     = var.app_name
  }
}

# ===========================
# Subnets (3-Tier Architecture)
# ===========================

# Public Subnets for ALB
resource "aws_subnet" "public" {
  count = 2

  vpc_id            = aws_vpc.app.id
  cidr_block        = cidrsubnet(aws_vpc.app.cidr_block, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name}-public-subnet-${count.index + 1}"
    Tier = "public"
  }
}

# Private Subnets for Application
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.app.id
  cidr_block        = cidrsubnet(aws_vpc.app.cidr_block, 4, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}-private-subnet-${count.index + 1}"
    Tier = "application"
  }
}

# Database Subnets (isolated)
resource "aws_subnet" "database" {
  count = 2

  vpc_id            = aws_vpc.app.id
  cidr_block        = cidrsubnet(aws_vpc.app.cidr_block, 4, count.index + 4)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.app_name}-database-subnet-${count.index + 1}"
    Tier = "database"
  }
}

# ===========================
# Internet Gateway (for ALB)
# ===========================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.app.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

# ===========================
# Route Tables
# ===========================

# Public Route Table (ALB subnets)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.app_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table (Application subnets)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.app.id

  # Route to other segments via Cloud WAN
  route {
    cidr_block           = "10.0.0.0/8"
    core_network_arn     = data.aws_networkmanager_core_network.main.arn
  }

  tags = {
    Name = "${var.app_name}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Database Route Table (isolated - no internet)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.app.id

  # Only routes to VPC CIDR (no internet, no Cloud WAN)
  # Implicit local route only

  tags = {
    Name = "${var.app_name}-database-rt"
  }
}

resource "aws_route_table_association" "database" {
  count = 2

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# ===========================
# Cloud WAN Attachment (prod-general Segment)
# ===========================

resource "aws_networkmanager_vpc_attachment" "app" {
  core_network_id = data.aws_networkmanager_core_network.main.id
  vpc_arn         = aws_vpc.app.arn
  subnet_arns     = aws_subnet.private[*].arn

  options {
    appliance_mode_support = false
    ipv6_support           = false
  }

  tags = {
    Name        = "${var.app_name}-attachment"
    Segment     = "prod-general"
    Environment = "production"
  }
}

# ===========================
# Security Groups (3-Tier Architecture)
# ===========================

module "security_groups" {
  source = "../../modules/security-groups-3tier"

  app_name = var.app_name
  vpc_id   = aws_vpc.app.id
  vpc_cidr = aws_vpc.app.cidr_block

  # Enable standard 3-tier architecture
  create_alb_sg     = true
  create_web_tier   = true
  create_api_tier   = true
  create_db_tier    = true
  create_cache_tier = var.enable_cache

  # Port configuration
  web_tier_port = 3000  # Node.js / React
  api_tier_port = 8080  # API service
  db_port       = 5432  # PostgreSQL

  # ALB accessible from internet
  alb_ingress_cidr             = "0.0.0.0/0"
  alb_ingress_cidr_description = "internet"
  allow_http_on_alb            = true

  # Web tier needs access to AWS services (S3, DynamoDB)
  web_tier_needs_aws_access = true

  # API tier needs internet for external APIs (Stripe, Twilio, etc.)
  api_tier_needs_internet = true

  # Allow microservices to call API tier
  allow_api_from_vpc = true

  tags = {
    Environment = "production"
    Segment     = "prod-general"
    AppName     = var.app_name
  }
}

# ===========================
# VPC Flow Logs
# ===========================

resource "aws_flow_log" "app" {
  vpc_id          = aws_vpc.app.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn

  tags = {
    Name = "${var.app_name}-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.app_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.app_name}-flow-logs"
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
# Outputs
# ===========================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.app.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.app.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs (for ALB)"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (for application)"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = aws_subnet.database[*].id
}

output "security_groups" {
  description = "Security group IDs for all tiers"
  value       = module.security_groups.security_group_ids
}

output "cloud_wan_attachment_id" {
  description = "Cloud WAN attachment ID"
  value       = aws_networkmanager_vpc_attachment.app.id
}

output "architecture_summary" {
  description = "Summary of deployed architecture"
  value = {
    vpc_cidr           = aws_vpc.app.cidr_block
    segment            = "prod-general"
    internet_access    = "✓ ALB has internet access via IGW"
    api_internet       = "✓ API tier can reach external APIs"
    database_isolation = "✓ Database has NO internet route"
    cloud_wan          = "✓ Connected to Cloud WAN for cross-region/account communication"
  }
}
