# NAT Gateway Configuration
# Single NAT Gateway for single-AZ (cost optimization)
# Multiple NAT Gateways for multi-AZ (high availability)
# Provides outbound internet access for Cloud WAN attached workloads

# Elastic IPs for NAT Gateways (one per AZ)
resource "aws_eip" "nat" {
  count = local.az_count

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-nat-eip-${local.azs[count.index]}"
    AZ   = local.azs[count.index]
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways in public subnets (one per AZ)
resource "aws_nat_gateway" "main" {
  count = local.az_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-nat-${local.azs[count.index]}"
    AZ   = local.azs[count.index]
  })

  depends_on = [aws_internet_gateway.main]
}
