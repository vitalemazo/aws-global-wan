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
  # Select first AZ for single-AZ deployment (cost optimization)
  availability_zone = var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]
}

# Public Subnet - NAT Gateway
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.inspection.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = local.availability_zone
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-public-${local.availability_zone}"
    Type = "public"
  })
}

# Firewall Subnet - Network Firewall endpoints
resource "aws_subnet" "firewall" {
  vpc_id            = aws_vpc.inspection.id
  cidr_block        = var.firewall_subnet_cidr
  availability_zone = local.availability_zone

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-firewall-${local.availability_zone}"
    Type = "firewall"
  })
}

# Attachment Subnet - Cloud WAN attachment
resource "aws_subnet" "attachment" {
  vpc_id            = aws_vpc.inspection.id
  cidr_block        = var.attachment_subnet_cidr
  availability_zone = local.availability_zone

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-attachment-${local.availability_zone}"
    Type = "cloudwan-attachment"
  })
}
