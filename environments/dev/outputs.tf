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
# Deployment Status
# ===========================

output "next_steps" {
  description = "Next steps for deployment"
  value       = <<-EOT
    Phase 2 Complete! ✅

    Deployed Resources:
    - Core Network: ${module.core_network.core_network_id}
    - Segments: ${join(", ", module.core_network.segment_names)}
    - Inspection VPC (us-east-1): ${module.inspection_vpc_useast1.vpc_id}
    - NAT Gateway IP: ${module.inspection_vpc_useast1.nat_gateway_public_ip}
    - Network Firewall: ${module.inspection_vpc_useast1.firewall_id}

    Next Steps:
    1. Verify in AWS Console:
       - VPC > Cloud WAN > Core Networks > Attachments
       - VPC > Network Firewall
       - Check attachment shows "network-function: inspection" tag

    2. CLI Verification:
       # Check Core Network
       aws networkmanager get-core-network --core-network-id ${module.core_network.core_network_id}

       # Check attachment
       aws networkmanager get-vpc-attachment --attachment-id ${module.inspection_vpc_useast1.cloudwan_attachment_id}

       # Check firewall status
       aws network-firewall describe-firewall --firewall-arn ${module.inspection_vpc_useast1.firewall_arn}

    3. Ready for Phase 3:
       - Deploy inspection VPC in us-west-2
       - See: DEPLOYMENT_PLAN.md > Phase 3

    Current Monthly Cost: ~$685 ($255 Core Network + $430 Inspection VPC)
  EOT
}
