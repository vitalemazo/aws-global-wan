# Landing Zone VPC Module
# Creates application VPC with Cloud WAN attachment for workload deployment
# Includes optional EC2 test instances for connectivity validation

# VPC for application workloads
# Supports both static CIDR and IPAM-based allocation
resource "aws_vpc" "landing_zone" {
  # Use IPAM if pool_id is provided, otherwise use static CIDR
  cidr_block           = var.ipam_pool_id == null ? var.vpc_cidr : null
  ipv4_ipam_pool_id    = var.ipam_pool_id
  ipv4_netmask_length  = var.ipam_pool_id != null ? var.ipam_netmask_length : null

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name    = var.vpc_name
    Segment = var.segment_name
    Type    = "landing-zone"
  })

  lifecycle {
    precondition {
      condition     = (var.vpc_cidr != null && var.ipam_pool_id == null) || (var.vpc_cidr == null && var.ipam_pool_id != null)
      error_message = "Either vpc_cidr OR ipam_pool_id must be set, but not both."
    }
  }
}

# Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "region-name"
    values = [var.region]
  }
}

locals {
  # Select AZs for deployment
  az_count = var.multi_az ? 2 : 1
  azs      = slice(data.aws_availability_zones.available.names, 0, local.az_count)

  # Determine VPC CIDR - either from static var or from IPAM-allocated VPC
  vpc_cidr = var.ipam_pool_id != null ? aws_vpc.landing_zone.cidr_block : var.vpc_cidr
}

# Private Subnets (one per AZ)
resource "aws_subnet" "private" {
  count = local.az_count

  vpc_id            = aws_vpc.landing_zone.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 4, count.index)
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-private-${local.azs[count.index]}"
    Type = "private"
  })
}

# Cloud WAN Attachment Subnets (one per AZ)
resource "aws_subnet" "cloudwan" {
  count = local.az_count

  vpc_id            = aws_vpc.landing_zone.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 4, count.index + 10)
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-cloudwan-${local.azs[count.index]}"
    Type = "cloudwan-attachment"
  })
}
