# Inspection VPC Module
# Creates VPC with AWS Network Firewall, NAT Gateway, and Cloud WAN attachment
# Designed for centralized network inspection and internet egress

# VPC for inspection workloads
resource "aws_vpc" "inspection" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = var.vpc_name
    Type = "inspection"
  })
}

# Internet Gateway for outbound internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-igw"
  })
}

# Availability Zone data source
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.region]
  }
}

locals {
  # Multi-AZ configuration
  az_count = var.multi_az ? 2 : 1
  azs      = var.multi_az ? slice(data.aws_availability_zones.available.names, 0, 2) : [var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]]

  # Subnet CIDR calculation for multi-AZ
  # Splits each /24 into two /25 subnets when multi-AZ is enabled
  public_subnet_cidrs = var.multi_az ? [
    cidrsubnet(var.public_subnet_cidr, 1, 0),
    cidrsubnet(var.public_subnet_cidr, 1, 1)
  ] : [var.public_subnet_cidr]

  firewall_subnet_cidrs = var.multi_az ? [
    cidrsubnet(var.firewall_subnet_cidr, 1, 0),
    cidrsubnet(var.firewall_subnet_cidr, 1, 1)
  ] : [var.firewall_subnet_cidr]

  attachment_subnet_cidrs = var.multi_az ? [
    cidrsubnet(var.attachment_subnet_cidr, 1, 0),
    cidrsubnet(var.attachment_subnet_cidr, 1, 1)
  ] : [var.attachment_subnet_cidr]
}

# Public Subnets - NAT Gateways (one per AZ)
resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id                  = aws_vpc.inspection.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-public-${local.azs[count.index]}"
    Type = "public"
    AZ   = local.azs[count.index]
  })
}

# Firewall Subnets - Network Firewall endpoints (one per AZ)
resource "aws_subnet" "firewall" {
  count = local.az_count

  vpc_id            = aws_vpc.inspection.id
  cidr_block        = local.firewall_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-firewall-${local.azs[count.index]}"
    Type = "firewall"
    AZ   = local.azs[count.index]
  })
}

# Attachment Subnets - Cloud WAN attachment (one per AZ)
resource "aws_subnet" "attachment" {
  count = local.az_count

  vpc_id            = aws_vpc.inspection.id
  cidr_block        = local.attachment_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-attachment-${local.azs[count.index]}"
    Type = "cloudwan-attachment"
    AZ   = local.azs[count.index]
  })
}
