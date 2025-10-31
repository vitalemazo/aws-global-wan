# Control Tower SCPs Module Outputs

output "network_governance_policy_id" {
  description = "ID of the network governance SCP"
  value       = aws_organizations_policy.network_governance.id
}

output "network_governance_policy_arn" {
  description = "ARN of the network governance SCP"
  value       = aws_organizations_policy.network_governance.arn
}

output "region_restriction_policy_id" {
  description = "ID of the region restriction SCP (if enabled)"
  value       = var.enable_region_restriction ? aws_organizations_policy.region_restriction[0].id : null
}

output "region_restriction_policy_arn" {
  description = "ARN of the region restriction SCP (if enabled)"
  value       = var.enable_region_restriction ? aws_organizations_policy.region_restriction[0].arn : null
}

output "security_baseline_policy_id" {
  description = "ID of the security baseline SCP (if enabled)"
  value       = var.enable_security_baseline ? aws_organizations_policy.security_baseline[0].id : null
}

output "security_baseline_policy_arn" {
  description = "ARN of the security baseline SCP (if enabled)"
  value       = var.enable_security_baseline ? aws_organizations_policy.security_baseline[0].arn : null
}

output "vpc_flow_logs_policy_id" {
  description = "ID of the VPC Flow Logs enforcement SCP (if enabled)"
  value       = var.enforce_vpc_flow_logs ? aws_organizations_policy.vpc_flow_logs[0].id : null
}

output "vpc_flow_logs_policy_arn" {
  description = "ARN of the VPC Flow Logs enforcement SCP (if enabled)"
  value       = var.enforce_vpc_flow_logs ? aws_organizations_policy.vpc_flow_logs[0].arn : null
}

output "policy_summary" {
  description = "Summary of all SCPs created"
  value = {
    network_governance = {
      id                          = aws_organizations_policy.network_governance.id
      enforce_ipam                = var.enforce_ipam_usage
      prevent_transit_gateway     = var.prevent_transit_gateway
      prevent_vpc_peering         = var.prevent_vpc_peering
      centralize_internet_egress  = var.centralize_internet_egress
      centralize_nat_gateway      = var.centralize_nat_gateway
      attached_to_ou_count        = length(var.workload_ou_ids)
    }
    region_restriction = var.enable_region_restriction ? {
      id               = aws_organizations_policy.region_restriction[0].id
      allowed_regions  = var.allowed_regions
      attached_to_ou_count = length(var.all_ou_ids)
    } : null
    security_baseline = var.enable_security_baseline ? {
      id               = aws_organizations_policy.security_baseline[0].id
      attached_to_ou_count = length(var.workload_ou_ids)
    } : null
    vpc_flow_logs = var.enforce_vpc_flow_logs ? {
      id               = aws_organizations_policy.vpc_flow_logs[0].id
      attached_to_ou_count = length(var.workload_ou_ids)
    } : null
  }
}
