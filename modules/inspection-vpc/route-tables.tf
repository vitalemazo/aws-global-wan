# Route Table Configuration - Multi-AZ Support
# Implements traffic flow patterns for centralized inspection across multiple AZs
#
# Traffic Flow Pattern:
# 1. Internet → IGW → Public Subnet (NAT Gateway in same AZ)
# 2. NAT Gateway → Firewall Subnet → Network Firewall (same AZ)
# 3. Network Firewall → Attachment Subnet → Cloud WAN
# 4. Cloud WAN → Attachment Subnet → Network Firewall → Internet

# ===========================
# Public Subnet Route Tables (one per AZ)
# ===========================
# Routes internet-bound traffic from NAT Gateway through IGW
# Routes RFC1918 traffic to Network Firewall endpoint in same AZ

resource "aws_route_table" "public" {
  count = local.az_count

  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-public-rt-${local.azs[count.index]}"
    AZ   = local.azs[count.index]
  })
}

# Default route to Internet Gateway
resource "aws_route" "public_internet" {
  count = local.az_count

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# RFC1918 routes to Network Firewall endpoint (same AZ)
resource "aws_route" "public_to_firewall_10" {
  count = local.az_count

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "10.0.0.0/8"
  vpc_endpoint_id        = local.firewall_endpoints[local.azs[count.index]]

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route" "public_to_firewall_172" {
  count = local.az_count

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "172.16.0.0/12"
  vpc_endpoint_id        = local.firewall_endpoints[local.azs[count.index]]

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route" "public_to_firewall_192" {
  count = local.az_count

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "192.168.0.0/16"
  vpc_endpoint_id        = local.firewall_endpoints[local.azs[count.index]]

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

# ===========================
# Firewall Subnet Route Tables (one per AZ)
# ===========================
# Routes internet-bound traffic to NAT Gateway in same AZ
# Routes RFC1918 traffic to Cloud WAN attachment

resource "aws_route_table" "firewall" {
  count = local.az_count

  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-firewall-rt-${local.azs[count.index]}"
    AZ   = local.azs[count.index]
  })
}

# Default route to NAT Gateway in same AZ for internet egress
resource "aws_route" "firewall_internet" {
  count = local.az_count

  route_table_id         = aws_route_table.firewall[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}

# RFC1918 routes to Cloud WAN attachment
resource "aws_route" "firewall_to_cloudwan_10" {
  count = local.az_count

  route_table_id         = aws_route_table.firewall[count.index].id
  destination_cidr_block = "10.0.0.0/8"
  core_network_arn       = var.core_network_arn

  depends_on = [time_sleep.wait_for_attachment]
}

resource "aws_route" "firewall_to_cloudwan_172" {
  count = local.az_count

  route_table_id         = aws_route_table.firewall[count.index].id
  destination_cidr_block = "172.16.0.0/12"
  core_network_arn       = var.core_network_arn

  depends_on = [time_sleep.wait_for_attachment]
}

resource "aws_route" "firewall_to_cloudwan_192" {
  count = local.az_count

  route_table_id         = aws_route_table.firewall[count.index].id
  destination_cidr_block = "192.168.0.0/16"
  core_network_arn       = var.core_network_arn

  depends_on = [time_sleep.wait_for_attachment]
}

resource "aws_route_table_association" "firewall" {
  count = local.az_count

  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall[count.index].id
}

# ===========================
# Attachment Subnet Route Tables (one per AZ)
# ===========================
# Routes all traffic to Network Firewall endpoint in same AZ for inspection

resource "aws_route_table" "attachment" {
  count = local.az_count

  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-attachment-rt-${local.azs[count.index]}"
    AZ   = local.azs[count.index]
  })
}

# Default route to Network Firewall endpoint in same AZ
resource "aws_route" "attachment_default" {
  count = local.az_count

  route_table_id         = aws_route_table.attachment[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoints[local.azs[count.index]]

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route_table_association" "attachment" {
  count = local.az_count

  subnet_id      = aws_subnet.attachment[count.index].id
  route_table_id = aws_route_table.attachment[count.index].id
}

# ===========================
# Internet Gateway Route Tables (one per AZ)
# ===========================
# Edge association to route return traffic from internet
# Directs return traffic to Network Firewall endpoint in appropriate AZ

resource "aws_route_table" "igw_edge" {
  count = local.az_count

  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-igw-edge-rt-${local.azs[count.index]}"
    AZ   = local.azs[count.index]
  })
}

# Route inspection VPC CIDR back to Network Firewall in same AZ
# Use subnet CIDR for AZ-specific routing
resource "aws_route" "igw_to_firewall" {
  count = local.az_count

  route_table_id         = aws_route_table.igw_edge[count.index].id
  destination_cidr_block = local.public_subnet_cidrs[count.index]
  vpc_endpoint_id        = local.firewall_endpoints[local.azs[count.index]]

  depends_on = [aws_networkfirewall_firewall.main]
}

# IGW edge associations - only for first AZ in multi-AZ (shared IGW)
# Note: IGW is shared across AZs, so we only need one edge association
resource "aws_route_table_association" "igw_edge" {
  gateway_id     = aws_internet_gateway.main.id
  route_table_id = aws_route_table.igw_edge[0].id
}
