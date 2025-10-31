# Cloud WAN Attachment Configuration
# Connects landing zone VPC to specified Core Network segment
# Segment is determined by tag-based attachment policy

# VPC Attachment to Core Network
resource "aws_networkmanager_vpc_attachment" "landing_zone" {
  core_network_id = var.core_network_id
  subnet_arns     = aws_subnet.cloudwan[*].arn
  vpc_arn         = aws_vpc.landing_zone.arn

  tags = merge(var.tags, {
    Name    = "${var.vpc_name}-attachment"
    segment = var.segment_name
  })
}

# Wait for attachment to be available
resource "time_sleep" "wait_for_attachment" {
  create_duration = "60s"

  depends_on = [aws_networkmanager_vpc_attachment.landing_zone]
}
