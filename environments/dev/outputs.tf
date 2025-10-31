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
# Phase 4: Landing Zone VPC Outputs
# ===========================

output "landing_zone_prod_vpc_id" {
  description = "ID of the production landing zone VPC"
  value       = module.landing_zone_prod_useast1.vpc_id
}

output "landing_zone_prod_test_instance_ip" {
  description = "Private IP of production test instance"
  value       = module.landing_zone_prod_useast1.test_instance_private_ip
}

output "landing_zone_prod_attachment_id" {
  description = "Cloud WAN attachment ID for production VPC"
  value       = module.landing_zone_prod_useast1.cloudwan_attachment_id
}

output "landing_zone_nonprod_vpc_id" {
  description = "ID of the non-production landing zone VPC"
  value       = module.landing_zone_nonprod_uswest2.vpc_id
}

output "landing_zone_nonprod_test_instance_ip" {
  description = "Private IP of non-production test instance"
  value       = module.landing_zone_nonprod_uswest2.test_instance_private_ip
}

output "landing_zone_nonprod_attachment_id" {
  description = "Cloud WAN attachment ID for non-production VPC"
  value       = module.landing_zone_nonprod_uswest2.cloudwan_attachment_id
}

# ===========================
# Deployment Status
# ===========================

output "next_steps" {
  description = "Next steps for deployment"
  value       = <<-EOT
    Phase 4 Complete! ✅

    Deployed Resources:
    ==================
    Core Network:
    - ID: ${module.core_network.core_network_id}
    - Segments: ${join(", ", module.core_network.segment_names)}
    - Edge Locations: ${join(", ", module.core_network.edge_locations)}

    Inspection VPCs:
    - us-east-1: ${module.inspection_vpc_useast1.vpc_id} (NAT IP: ${module.inspection_vpc_useast1.nat_gateway_public_ip})
    - us-west-2: ${module.inspection_vpc_uswest2.vpc_id} (NAT IP: ${module.inspection_vpc_uswest2.nat_gateway_public_ip})

    Landing Zone VPCs:
    - Production (us-east-1): ${module.landing_zone_prod_useast1.vpc_id}
      * Test Instance: ${module.landing_zone_prod_useast1.test_instance_private_ip}
      * Segment: prod
    - Non-Production (us-west-2): ${module.landing_zone_nonprod_uswest2.vpc_id}
      * Test Instance: ${module.landing_zone_nonprod_uswest2.test_instance_private_ip}
      * Segment: non-prod

    Connectivity Testing:
    =====================
    1. SSH to test instances via AWS Systems Manager Session Manager:
       aws ssm start-session --target ${module.landing_zone_prod_useast1.test_instance_id}
       aws ssm start-session --target ${module.landing_zone_nonprod_uswest2.test_instance_id} --region us-west-2

    2. Test Internet Connectivity (from either instance):
       curl https://api.ipify.org  # Should return NAT Gateway IP
       ping 8.8.8.8                # Should work through inspection VPC

    3. Test Inter-Segment Isolation:
       # From prod instance, try to ping non-prod instance
       ping ${module.landing_zone_nonprod_uswest2.test_instance_private_ip}
       # Should FAIL (prod and non-prod are isolated)

    4. View Network Firewall Logs:
       # Check firewall is inspecting traffic
       aws logs tail /aws/network-firewall/useast1-inspection --follow

    5. Verify Cloud WAN Routes:
       # From inside instance
       ip route  # Should show Cloud WAN routes

    AWS Console Verification:
    =========================
    - VPC > Cloud WAN > Core Networks > Attachments (4 attachments)
    - EC2 > Instances (2 test instances running)
    - VPC > Network Firewall (2 firewalls active)
    - VPC > Route Tables (check Cloud WAN routes)

    Architecture Summary:
    ====================
    - Prod VPC (10.10.0.0/16) → Core Network (prod segment) → Inspection → Internet
    - Non-Prod VPC (172.16.0.0/16) → Core Network (non-prod segment) → Inspection → Internet
    - Prod and Non-Prod cannot communicate (isolated segments)
    - All traffic inspected by Network Firewall
    - Centralized internet egress via NAT Gateways

    Current Monthly Cost: ~$1,151
    - Core Network: $255
    - us-east-1 Inspection: $430
    - us-west-2 Inspection: $430
    - EC2 Instances (2x t2.micro): $16
    - Cloud WAN Attachments (4x): $20

    Ready for Production:
    ====================
    - Add more landing zone VPCs as needed
    - Configure firewall rules for specific traffic patterns
    - Enable CloudWatch monitoring and alarms
    - Add shared services VPC (DNS, Active Directory, etc.)
  EOT
}
