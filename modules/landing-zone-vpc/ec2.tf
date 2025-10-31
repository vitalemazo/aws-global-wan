# EC2 Test Instance Configuration
# Creates t2.micro instances (free tier eligible) for connectivity testing

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  count = var.create_test_instance ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Test EC2 Instance (one in first AZ)
resource "aws_instance" "test" {
  count = var.create_test_instance ? 1 : 0

  ami           = data.aws_ami.amazon_linux_2023[0].id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private[0].id

  vpc_security_group_ids = [aws_security_group.default[0].id]

  # User data for basic setup
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    vpc_name     = var.vpc_name
    segment_name = var.segment_name
    region       = var.region
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(var.tags, {
    Name    = "${var.vpc_name}-test-instance"
    Purpose = "connectivity-testing"
  })
}

# CloudWatch Logs for instance console output (optional)
resource "aws_cloudwatch_log_group" "instance" {
  count = var.create_test_instance && var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/ec2/${var.vpc_name}-test-instance"
  retention_in_days = 7

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-instance-logs"
  })
}
