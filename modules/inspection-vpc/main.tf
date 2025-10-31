# Inspection VPC Module
# Creates VPC with AWS Network Firewall, NAT Gateway, and Cloud WAN attachment
# Designed for centralized network inspection and internet egress

# VPC for inspection workloads
# Supports both static CIDR and IPAM-based allocation
resource "aws_vpc" "inspection" {
  # Use IPAM if pool_id is provided, otherwise use static CIDR
  cidr_block           = var.ipam_pool_id == null ? var.vpc_cidr : null
  ipv4_ipam_pool_id    = var.ipam_pool_id
  ipv4_netmask_length  = var.ipam_pool_id != null ? var.ipam_netmask_length : null

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = var.vpc_name
    Type = "inspection"
  })

  lifecycle {
    precondition {
      condition     = (var.vpc_cidr != null && var.ipam_pool_id == null) || (var.vpc_cidr == null && var.ipam_pool_id != null)
      error_message = "Either vpc_cidr OR ipam_pool_id must be set, but not both."
    }
  }
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

  # Determine VPC CIDR - either from static var or from IPAM-allocated VPC
  vpc_cidr = var.ipam_pool_id != null ? aws_vpc.inspection.cidr_block : var.vpc_cidr

  # Subnet CIDR calculation
  # When using IPAM: automatically calculate subnets from VPC CIDR
  # When using static: use provided subnet CIDRs (or auto-calculate if not provided)

  # For IPAM mode: Calculate /24 subnets from VPC CIDR (e.g., /20 VPC -> 16x /24 subnets)
  # Public: .0.0/24, Firewall: .1.0/24, Attachment: .2.0/24
  base_public_cidr     = var.ipam_pool_id != null ? cidrsubnet(local.vpc_cidr, 24 - tonumber(split("/", local.vpc_cidr)[1]), 0) : var.public_subnet_cidr
  base_firewall_cidr   = var.ipam_pool_id != null ? cidrsubnet(local.vpc_cidr, 24 - tonumber(split("/", local.vpc_cidr)[1]), 1) : var.firewall_subnet_cidr
  base_attachment_cidr = var.ipam_pool_id != null ? cidrsubnet(local.vpc_cidr, 24 - tonumber(split("/", local.vpc_cidr)[1]), 2) : var.attachment_subnet_cidr

  # Multi-AZ: Split each /24 into two /25 subnets
  public_subnet_cidrs = var.multi_az ? [
    cidrsubnet(local.base_public_cidr, 1, 0),
    cidrsubnet(local.base_public_cidr, 1, 1)
  ] : [local.base_public_cidr]

  firewall_subnet_cidrs = var.multi_az ? [
    cidrsubnet(local.base_firewall_cidr, 1, 0),
    cidrsubnet(local.base_firewall_cidr, 1, 1)
  ] : [local.base_firewall_cidr]

  attachment_subnet_cidrs = var.multi_az ? [
    cidrsubnet(local.base_attachment_cidr, 1, 0),
    cidrsubnet(local.base_attachment_cidr, 1, 1)
  ] : [local.base_attachment_cidr]
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
