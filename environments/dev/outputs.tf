# Development Environment Outputs

output "global_network_id" {
  description = "ID of the Global Network"
  value       = module.core_network.global_network_id
}

output "core_network_id" {
  description = "ID of the Core Network"
  value       = module.core_network.core_network_id
}

output "core_network_arn" {
  description = "ARN of the Core Network"
  value       = module.core_network.core_network_arn
}

output "segment_names" {
  description = "List of network segment names"
  value       = module.core_network.segment_names
}

output "edge_locations" {
  description = "Regions where Core Network operates"
  value       = module.core_network.edge_locations
}

# ===========================
# Phase 2: Inspection VPC Outputs
# ===========================

output "inspection_vpc_useast1_id" {
  description = "ID of the us-east-1 inspection VPC"
  value       = module.inspection_vpc_useast1.vpc_id
}

output "inspection_vpc_useast1_nat_ip" {
  description = "Public IP of us-east-1 NAT Gateway"
  value       = module.inspection_vpc_useast1.nat_gateway_public_ip
}

output "inspection_vpc_useast1_firewall_id" {
  description = "ID of the us-east-1 Network Firewall"
  value       = module.inspection_vpc_useast1.firewall_id
}

output "inspection_vpc_useast1_attachment_id" {
  description = "Cloud WAN attachment ID for us-east-1 inspection VPC"
  value       = module.inspection_vpc_useast1.cloudwan_attachment_id
}

output "inspection_vpc_useast1_summary" {
  description = "Deployment summary for us-east-1 inspection VPC"
  value       = module.inspection_vpc_useast1.deployment_summary
}

# ===========================
# Phase 3: us-west-2 Inspection VPC Outputs
# ===========================

output "inspection_vpc_uswest2_id" {
  description = "ID of the us-west-2 inspection VPC"
  value       = module.inspection_vpc_uswest2.vpc_id
}

output "inspection_vpc_uswest2_nat_ip" {
  description = "Public IP of us-west-2 NAT Gateway"
  value       = module.inspection_vpc_uswest2.nat_gateway_public_ip
}

output "inspection_vpc_uswest2_firewall_id" {
  description = "ID of the us-west-2 Network Firewall"
  value       = module.inspection_vpc_uswest2.firewall_id
}

output "inspection_vpc_uswest2_attachment_id" {
  description = "Cloud WAN attachment ID for us-west-2 inspection VPC"
  value       = module.inspection_vpc_uswest2.cloudwan_attachment_id
}

output "inspection_vpc_uswest2_summary" {
  description = "Deployment summary for us-west-2 inspection VPC"
  value       = module.inspection_vpc_uswest2.deployment_summary
}

# ===========================
# Deployment Status
# ===========================

output "next_steps" {
  description = "Next steps for deployment"
  value       = <<-EOT
    Phase 3 Complete! ✅

    Deployed Resources:
    ==================
    Core Network:
    - ID: ${module.core_network.core_network_id}
    - Segments: ${join(", ", module.core_network.segment_names)}
    - Edge Locations: ${join(", ", module.core_network.edge_locations)}

    Inspection VPC (us-east-1):
    - VPC: ${module.inspection_vpc_useast1.vpc_id}
    - NAT Gateway IP: ${module.inspection_vpc_useast1.nat_gateway_public_ip}
    - Network Firewall: ${module.inspection_vpc_useast1.firewall_id}
    - Attachment: ${module.inspection_vpc_useast1.cloudwan_attachment_id}

    Inspection VPC (us-west-2):
    - VPC: ${module.inspection_vpc_uswest2.vpc_id}
    - NAT Gateway IP: ${module.inspection_vpc_uswest2.nat_gateway_public_ip}
    - Network Firewall: ${module.inspection_vpc_uswest2.firewall_id}
    - Attachment: ${module.inspection_vpc_uswest2.cloudwan_attachment_id}

    Verification Steps:
    ===================
    1. AWS Console:
       - VPC > Cloud WAN > Core Networks > Attachments
       - VPC > Network Firewall (both regions)
       - Verify "network-function: inspection" tags

    2. CLI Verification:
       # Core Network
       aws networkmanager get-core-network --core-network-id ${module.core_network.core_network_id}

       # us-east-1 attachment
       aws networkmanager get-vpc-attachment --attachment-id ${module.inspection_vpc_useast1.cloudwan_attachment_id}

       # us-west-2 attachment
       aws networkmanager get-vpc-attachment --attachment-id ${module.inspection_vpc_uswest2.cloudwan_attachment_id} --region us-west-2

    3. Test Connectivity:
       - Deploy landing zone VPC (Phase 4)
       - Verify inter-segment traffic flows through inspection
       - Check NAT Gateway for internet egress

    Ready for Phase 4:
    ==================
    - Deploy first landing zone VPC
    - Attach to production segment
    - Test end-to-end connectivity
    - See: DEPLOYMENT_PLAN.md > Phase 4

    Current Monthly Cost: ~$1,115
    - Core Network: $255
    - us-east-1 Inspection: $430
    - us-west-2 Inspection: $430
  EOT
}
