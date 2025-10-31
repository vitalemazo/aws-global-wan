# Landing Zone VPC Module Outputs

# ===========================
# VPC Information
# ===========================

output "vpc_id" {
  description = "ID of the landing zone VPC"
  value       = aws_vpc.landing_zone.id
}

output "vpc_arn" {
  description = "ARN of the landing zone VPC"
  value       = aws_vpc.landing_zone.arn
}

output "vpc_cidr" {
  description = "CIDR block of the landing zone VPC"
  value       = aws_vpc.landing_zone.cidr_block
}

# ===========================
# Subnet Information
# ===========================

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "cloudwan_subnet_ids" {
  description = "IDs of the Cloud WAN attachment subnets"
  value       = aws_subnet.cloudwan[*].id
}

output "availability_zones" {
  description = "Availability Zones used for deployment"
  value       = local.azs
}

# ===========================
# Cloud WAN Attachment Information
# ===========================

output "cloudwan_attachment_id" {
  description = "ID of the Cloud WAN VPC attachment"
  value       = aws_networkmanager_vpc_attachment.landing_zone.id
}

output "cloudwan_attachment_arn" {
  description = "ARN of the Cloud WAN VPC attachment"
  value       = aws_networkmanager_vpc_attachment.landing_zone.arn
}

output "cloudwan_attachment_state" {
  description = "State of the Cloud WAN VPC attachment"
  value       = aws_networkmanager_vpc_attachment.landing_zone.state
}

output "segment_name" {
  description = "Cloud WAN segment this VPC is attached to"
  value       = var.segment_name
}

# ===========================
# EC2 Instance Information
# ===========================

output "test_instance_id" {
  description = "ID of the test EC2 instance (if created)"
  value       = var.create_test_instance ? aws_instance.test[0].id : null
}

output "test_instance_private_ip" {
  description = "Private IP address of the test EC2 instance (if created)"
  value       = var.create_test_instance ? aws_instance.test[0].private_ip : null
}

output "test_instance_az" {
  description = "Availability Zone of the test EC2 instance (if created)"
  value       = var.create_test_instance ? aws_instance.test[0].availability_zone : null
}

# ===========================
# Security Group Information
# ===========================

output "default_security_group_id" {
  description = "ID of the default security group (if created)"
  value       = var.create_test_instance ? aws_security_group.default[0].id : null
}

# ===========================
# Summary Output
# ===========================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    vpc_id              = aws_vpc.landing_zone.id
    vpc_cidr            = aws_vpc.landing_zone.cidr_block
    region              = var.region
    segment             = var.segment_name
    availability_zones  = local.azs
    multi_az            = var.multi_az
    cloudwan_attachment = aws_networkmanager_vpc_attachment.landing_zone.id
    test_instance       = var.create_test_instance ? aws_instance.test[0].id : "none"
    test_instance_ip    = var.create_test_instance ? aws_instance.test[0].private_ip : "none"
  }
}
