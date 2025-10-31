# Cloud WAN Attachment Configuration
# Connects inspection VPC to Core Network
# Tagged for network function group to enable inspection routing

# VPC Attachment to Core Network
resource "aws_networkmanager_vpc_attachment" "inspection" {
  core_network_id = var.core_network_id
  subnet_arns     = [aws_subnet.attachment.arn]
  vpc_arn         = aws_vpc.inspection.arn

  tags = merge(var.tags, {
    Name    = "${var.vpc_name}-attachment"
    segment = var.segment_name
    # Network function group tag enables inspection routing
    network-function = var.network_function_group_name
  })
}

# Wait for attachment to be available before proceeding
resource "time_sleep" "wait_for_attachment" {
  create_duration = "60s"

  depends_on = [aws_networkmanager_vpc_attachment.inspection]
}
