# Security Group Configuration
# Allows testing of inter-segment connectivity and internet access

# Default Security Group for EC2 instances
resource "aws_security_group" "default" {
  count = var.create_test_instance ? 1 : 0

  name_prefix = "${var.vpc_name}-default-"
  description = "Default security group for ${var.vpc_name}"
  vpc_id      = aws_vpc.landing_zone.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-default-sg"
  })
}

# Allow ICMP (ping) from RFC1918 ranges for connectivity testing
resource "aws_vpc_security_group_ingress_rule" "icmp" {
  count = var.create_test_instance ? 1 : 0

  security_group_id = aws_security_group.default[0].id
  description       = "Allow ICMP from RFC1918 networks"

  ip_protocol = "icmp"
  from_port   = -1
  to_port     = -1
  cidr_ipv4   = "10.0.0.0/8"
}

resource "aws_vpc_security_group_ingress_rule" "icmp_172" {
  count = var.create_test_instance ? 1 : 0

  security_group_id = aws_security_group.default[0].id
  description       = "Allow ICMP from 172.16.0.0/12"

  ip_protocol = "icmp"
  from_port   = -1
  to_port     = -1
  cidr_ipv4   = "172.16.0.0/12"
}

resource "aws_vpc_security_group_ingress_rule" "icmp_192" {
  count = var.create_test_instance ? 1 : 0

  security_group_id = aws_security_group.default[0].id
  description       = "Allow ICMP from 192.168.0.0/16"

  ip_protocol = "icmp"
  from_port   = -1
  to_port     = -1
  cidr_ipv4   = "192.168.0.0/16"
}

# Allow SSH from RFC1918 ranges (optional)
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count = var.create_test_instance && var.enable_ssh ? 1 : 0

  security_group_id = aws_security_group.default[0].id
  description       = "Allow SSH from RFC1918 networks"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = "10.0.0.0/8"
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "all" {
  count = var.create_test_instance ? 1 : 0

  security_group_id = aws_security_group.default[0].id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}
