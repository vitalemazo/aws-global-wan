# Route Table Configuration
# Routes all traffic to Cloud WAN for inter-segment and internet connectivity

# Private Subnet Route Tables
resource "aws_route_table" "private" {
  count = local.az_count

  vpc_id = aws_vpc.landing_zone.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-private-rt-${local.azs[count.index]}"
  })
}

# Default route to Cloud WAN Core Network
resource "aws_route" "private_to_cloudwan" {
  count = local.az_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  core_network_arn       = var.core_network_arn

  depends_on = [time_sleep.wait_for_attachment]
}

# Associate private subnets with route tables
resource "aws_route_table_association" "private" {
  count = local.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Cloud WAN Attachment Subnet Route Tables
resource "aws_route_table" "cloudwan" {
  count = local.az_count

  vpc_id = aws_vpc.landing_zone.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-cloudwan-rt-${local.azs[count.index]}"
  })
}

# No routes needed for attachment subnets - Cloud WAN handles routing

# Associate Cloud WAN subnets with route tables
resource "aws_route_table_association" "cloudwan" {
  count = local.az_count

  subnet_id      = aws_subnet.cloudwan[count.index].id
  route_table_id = aws_route_table.cloudwan[count.index].id
}
