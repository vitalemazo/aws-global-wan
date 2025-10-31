# Inspection VPC Module Outputs

# ===========================
# VPC Information
# ===========================

output "vpc_id" {
  description = "ID of the inspection VPC"
  value       = aws_vpc.inspection.id
}

output "vpc_arn" {
  description = "ARN of the inspection VPC"
  value       = aws_vpc.inspection.arn
}

output "vpc_cidr" {
  description = "CIDR block of the inspection VPC"
  value       = aws_vpc.inspection.cidr_block
}

# ===========================
# Subnet Information
# ===========================

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "firewall_subnet_id" {
  description = "ID of the firewall subnet"
  value       = aws_subnet.firewall.id
}

output "attachment_subnet_id" {
  description = "ID of the attachment subnet"
  value       = aws_subnet.attachment.id
}

output "availability_zones" {
  description = "Availability Zones used for deployment"
  value       = local.azs
}

output "multi_az_enabled" {
  description = "Whether multi-AZ deployment is enabled"
  value       = var.multi_az
}

# ===========================
# Gateway Information
# ===========================

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways (one per AZ)"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses of the NAT Gateways (one per AZ)"
  value       = aws_eip.nat[*].public_ip
}

# Backward compatibility - single NAT Gateway ID and IP
output "nat_gateway_id" {
  description = "ID of the first NAT Gateway (for backward compatibility)"
  value       = aws_nat_gateway.main[0].id
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the first NAT Gateway (for backward compatibility)"
  value       = aws_eip.nat[0].public_ip
}

# ===========================
# Network Firewall Information
# ===========================

output "firewall_id" {
  description = "ID of the AWS Network Firewall"
  value       = aws_networkfirewall_firewall.main.id
}

output "firewall_arn" {
  description = "ARN of the AWS Network Firewall"
  value       = aws_networkfirewall_firewall.main.arn
}

output "firewall_endpoint_id" {
  description = "Network Firewall endpoint ID"
  value       = local.firewall_endpoint_id
}

output "firewall_status" {
  description = "Status of the Network Firewall"
  value       = aws_networkfirewall_firewall.main.firewall_status
}

# ===========================
# Cloud WAN Attachment Information
# ===========================

output "cloudwan_attachment_id" {
  description = "ID of the Cloud WAN VPC attachment"
  value       = aws_networkmanager_vpc_attachment.inspection.id
}

output "cloudwan_attachment_arn" {
  description = "ARN of the Cloud WAN VPC attachment"
  value       = aws_networkmanager_vpc_attachment.inspection.arn
}

output "cloudwan_attachment_state" {
  description = "State of the Cloud WAN VPC attachment"
  value       = aws_networkmanager_vpc_attachment.inspection.state
}

# ===========================
# Route Table Information
# ===========================

output "public_route_table_id" {
  description = "ID of the public subnet route table"
  value       = aws_route_table.public.id
}

output "firewall_route_table_id" {
  description = "ID of the firewall subnet route table"
  value       = aws_route_table.firewall.id
}

output "attachment_route_table_id" {
  description = "ID of the attachment subnet route table"
  value       = aws_route_table.attachment.id
}

# ===========================
# Summary Output
# ===========================

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    vpc_id               = aws_vpc.inspection.id
    region               = var.region
    availability_zone    = local.availability_zone
    nat_gateway_ip       = aws_eip.nat.public_ip
    firewall_endpoint    = local.firewall_endpoint_id
    cloudwan_attachment  = aws_networkmanager_vpc_attachment.inspection.id
    network_function     = var.network_function_group_name
  }
}
