# Route Table Configuration
# Implements traffic flow patterns for centralized inspection
#
# Traffic Flow Pattern:
# 1. Internet → IGW → Public Subnet (NAT Gateway)
# 2. NAT Gateway → Firewall Subnet → Network Firewall
# 3. Network Firewall → Attachment Subnet → Cloud WAN
# 4. Cloud WAN → Attachment Subnet → Network Firewall → Internet

# ===========================
# Public Subnet Route Table
# ===========================
# Routes internet-bound traffic from NAT Gateway through IGW
# Routes RFC1918 traffic to Network Firewall for inspection

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-public-rt"
  })
}

# Default route to Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# RFC1918 routes to Network Firewall endpoint
resource "aws_route" "public_to_firewall_10" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "10.0.0.0/8"
  vpc_endpoint_id        = local.firewall_endpoint_id

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route" "public_to_firewall_172" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "172.16.0.0/12"
  vpc_endpoint_id        = local.firewall_endpoint_id

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route" "public_to_firewall_192" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "192.168.0.0/16"
  vpc_endpoint_id        = local.firewall_endpoint_id

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ===========================
# Firewall Subnet Route Table
# ===========================
# Routes internet-bound traffic to NAT Gateway
# Routes RFC1918 traffic to Cloud WAN attachment

resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-firewall-rt"
  })
}

# Default route to NAT Gateway for internet egress
resource "aws_route" "firewall_internet" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

# RFC1918 routes to Cloud WAN attachment
resource "aws_route" "firewall_to_cloudwan_10" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "10.0.0.0/8"
  core_network_arn       = var.core_network_arn

  depends_on = [time_sleep.wait_for_attachment]
}

resource "aws_route" "firewall_to_cloudwan_172" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "172.16.0.0/12"
  core_network_arn       = var.core_network_arn

  depends_on = [time_sleep.wait_for_attachment]
}

resource "aws_route" "firewall_to_cloudwan_192" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "192.168.0.0/16"
  core_network_arn       = var.core_network_arn

  depends_on = [time_sleep.wait_for_attachment]
}

resource "aws_route_table_association" "firewall" {
  subnet_id      = aws_subnet.firewall.id
  route_table_id = aws_route_table.firewall.id
}

# ===========================
# Attachment Subnet Route Table
# ===========================
# Routes all traffic to Network Firewall for inspection
# This includes both internet-bound and inter-segment traffic

resource "aws_route_table" "attachment" {
  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-attachment-rt"
  })
}

# Default route to Network Firewall endpoint
resource "aws_route" "attachment_default" {
  route_table_id         = aws_route_table.attachment.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoint_id

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route_table_association" "attachment" {
  subnet_id      = aws_subnet.attachment.id
  route_table_id = aws_route_table.attachment.id
}

# ===========================
# Internet Gateway Route Table
# ===========================
# Edge association to route return traffic from internet
# Directs return traffic to Network Firewall for stateful tracking

resource "aws_route_table" "igw_edge" {
  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-igw-edge-rt"
  })
}

# Route inspection VPC CIDR back to Network Firewall
resource "aws_route" "igw_to_firewall" {
  route_table_id         = aws_route_table.igw_edge.id
  destination_cidr_block = var.vpc_cidr
  vpc_endpoint_id        = local.firewall_endpoint_id

  depends_on = [aws_networkfirewall_firewall.main]
}

# Associate IGW edge route table
resource "aws_route_table_association" "igw_edge" {
  gateway_id     = aws_internet_gateway.main.id
  route_table_id = aws_route_table.igw_edge.id
}
