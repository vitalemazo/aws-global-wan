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
# Phase 6: IPAM Outputs
# ===========================

output "ipam_id" {
  description = "ID of the IPAM resource"
  value       = module.ipam.ipam_id
}

output "ipam_scope_id" {
  description = "ID of the private IPAM scope"
  value       = module.ipam.ipam_scope_id
}

output "ipam_summary" {
  description = "IPAM configuration summary"
  value       = module.ipam.ipam_summary
}

# ===========================
# Phase 2: Inspection VPC Outputs
# ===========================

output "inspection_vpc_useast1_id" {
  description = "ID of the us-east-1 inspection VPC"
  value       = module.inspection_vpc_useast1.vpc_id
}

output "inspection_vpc_useast1_nat_ips" {
  description = "Public IPs of us-east-1 NAT Gateways (multi-AZ)"
  value       = module.inspection_vpc_useast1.nat_gateway_public_ips
}

output "inspection_vpc_useast1_azs" {
  description = "Availability Zones for us-east-1 inspection VPC"
  value       = module.inspection_vpc_useast1.availability_zones
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

output "inspection_vpc_uswest2_nat_ips" {
  description = "Public IPs of us-west-2 NAT Gateways (multi-AZ)"
  value       = module.inspection_vpc_uswest2.nat_gateway_public_ips
}

output "inspection_vpc_uswest2_azs" {
  description = "Availability Zones for us-west-2 inspection VPC"
  value       = module.inspection_vpc_uswest2.availability_zones
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
    Phase 6 Complete! ✅ IPAM Integration

    Deployed Resources:
    ==================
    Core Network:
    - ID: ${module.core_network.core_network_id}
    - Segments: ${join(", ", module.core_network.segment_names)}
    - Edge Locations: ${join(", ", module.core_network.edge_locations)}

    IPAM (Centralized IP Management):
    - IPAM ID: ${module.ipam.ipam_id}
    - Scope ID: ${module.ipam.ipam_scope_id}
    - Production Pool: 10.0.0.0/8 → Regional pools in us-east-1, us-west-2, us-east-2
    - Non-Production Pool: 172.16.0.0/12 → Regional pools in us-east-1, us-west-2, us-east-2
    - Shared Services Pool: 192.168.0.0/16 → Regional pools in us-east-1, us-west-2, us-east-2
    - Inspection Pool: 100.64.0.0/16 → Regional pools in us-east-1, us-west-2, us-east-2

    Inspection VPCs (Multi-AZ, IPAM-allocated):
    - us-east-1: ${module.inspection_vpc_useast1.vpc_id}
      * CIDR: Auto-allocated by IPAM from inspection pool (/20)
      * AZs: ${join(", ", module.inspection_vpc_useast1.availability_zones)}
      * NAT IPs: ${join(", ", module.inspection_vpc_useast1.nat_gateway_public_ips)}
    - us-west-2: ${module.inspection_vpc_uswest2.vpc_id}
      * CIDR: Auto-allocated by IPAM from inspection pool (/20)
      * AZs: ${join(", ", module.inspection_vpc_uswest2.availability_zones)}
      * NAT IPs: ${join(", ", module.inspection_vpc_uswest2.nat_gateway_public_ips)}

    Landing Zone VPCs (IPAM-allocated):
    - Production (us-east-1): ${module.landing_zone_prod_useast1.vpc_id}
      * CIDR: Auto-allocated by IPAM from production pool (/16)
      * Test Instance: ${module.landing_zone_prod_useast1.test_instance_private_ip}
      * Segment: prod
    - Non-Production (us-west-2): ${module.landing_zone_nonprod_uswest2.vpc_id}
      * CIDR: Auto-allocated by IPAM from non-production pool (/16)
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
    - VPC > IPAM > IPAM (view pools and allocations)
    - VPC > Cloud WAN > Core Networks > Attachments (4 attachments)
    - EC2 > Instances (2 test instances running)
    - VPC > Network Firewall (2 firewalls active)
    - VPC > Route Tables (check Cloud WAN routes)

    Architecture Summary:
    ====================
    - IPAM manages all CIDR allocations across organization
    - Prod VPC (IPAM-allocated /16) → Core Network (prod segment) → Inspection → Internet
    - Non-Prod VPC (IPAM-allocated /16) → Core Network (non-prod segment) → Inspection → Internet
    - Inspection VPCs (IPAM-allocated /20) provide centralized egress
    - Prod and Non-Prod cannot communicate (isolated segments)
    - All traffic inspected by Network Firewall
    - Centralized internet egress via NAT Gateways

    Current Monthly Cost: ~$1,233 (Phase 6: IPAM Integration)
    - Core Network: $255
    - IPAM: $18 (3 regions)
    - us-east-1 Inspection (Multi-AZ): $462 (+$32 for 2nd NAT)
    - us-west-2 Inspection (Multi-AZ): $462 (+$32 for 2nd NAT)
    - EC2 Instances (2x t2.micro): $16
    - Cloud WAN Attachments (4x): $20

    Phase 6 Benefits:
    =================
    - Centralized IP address management across all VPCs and accounts
    - Automatic CIDR allocation prevents IP conflicts
    - Hierarchical pool structure (top-level → regional)
    - Support for multi-account environments via RAM sharing
    - Foundation for Control Tower integration (Phase 7)

    Ready for Production:
    ====================
    - Add more landing zone VPCs (IPAM will auto-allocate CIDRs)
    - Configure firewall rules for specific traffic patterns
    - Enable CloudWatch monitoring and alarms
    - Add shared services VPC (DNS, Active Directory, etc.)
    - Integrate with AWS Control Tower for account factory
    - Enable organization-wide IPAM pool sharing
  EOT
}
