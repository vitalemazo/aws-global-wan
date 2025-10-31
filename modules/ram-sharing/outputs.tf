# RAM Sharing Module Outputs

# ===========================
# Core Network RAM Share
# ===========================

output "core_network_share_id" {
  description = "ID of the Core Network RAM resource share"
  value       = var.share_core_network ? aws_ram_resource_share.core_network[0].id : null
}

output "core_network_share_arn" {
  description = "ARN of the Core Network RAM resource share"
  value       = var.share_core_network ? aws_ram_resource_share.core_network[0].arn : null
}

output "core_network_share_status" {
  description = "Status of the Core Network RAM resource share"
  value       = var.share_core_network ? aws_ram_resource_share.core_network[0].status : null
}

# ===========================
# IPAM Pools RAM Share
# ===========================

output "ipam_pools_share_id" {
  description = "ID of the IPAM pools RAM resource share"
  value       = var.share_ipam_regional_pools ? aws_ram_resource_share.ipam_regional_pools[0].id : null
}

output "ipam_pools_share_arn" {
  description = "ARN of the IPAM pools RAM resource share"
  value       = var.share_ipam_regional_pools ? aws_ram_resource_share.ipam_regional_pools[0].arn : null
}

output "ipam_pools_shared_count" {
  description = "Number of IPAM pools shared"
  value       = length(var.ipam_pool_arns)
}

# ===========================
# Transit Gateway RAM Share
# ===========================

output "transit_gateway_share_id" {
  description = "ID of the Transit Gateway RAM resource share"
  value       = var.share_transit_gateway && var.transit_gateway_arn != "" ? aws_ram_resource_share.transit_gateway[0].id : null
}

output "transit_gateway_share_arn" {
  description = "ARN of the Transit Gateway RAM resource share"
  value       = var.share_transit_gateway && var.transit_gateway_arn != "" ? aws_ram_resource_share.transit_gateway[0].arn : null
}

# ===========================
# Route 53 Resolver Rules RAM Share
# ===========================

output "resolver_rules_share_id" {
  description = "ID of the Route 53 Resolver rules RAM resource share"
  value       = var.share_resolver_rules && length(var.resolver_rule_arns) > 0 ? aws_ram_resource_share.resolver_rules[0].id : null
}

output "resolver_rules_share_arn" {
  description = "ARN of the Route 53 Resolver rules RAM resource share"
  value       = var.share_resolver_rules && length(var.resolver_rule_arns) > 0 ? aws_ram_resource_share.resolver_rules[0].arn : null
}

output "resolver_rules_shared_count" {
  description = "Number of Route 53 Resolver rules shared"
  value       = length(var.resolver_rule_arns)
}

# ===========================
# Summary
# ===========================

output "ram_sharing_summary" {
  description = "Summary of all RAM resource shares"
  value = {
    core_network = var.share_core_network ? {
      share_id     = aws_ram_resource_share.core_network[0].id
      share_arn    = aws_ram_resource_share.core_network[0].arn
      share_status = aws_ram_resource_share.core_network[0].status
      shared_with  = var.organization_arn != "" ? "Organization" : length(var.target_ou_arns) > 0 ? "OUs" : "Accounts"
    } : null

    ipam_pools = var.share_ipam_regional_pools ? {
      share_id     = aws_ram_resource_share.ipam_regional_pools[0].id
      share_arn    = aws_ram_resource_share.ipam_regional_pools[0].arn
      pools_count  = length(var.ipam_pool_arns)
      shared_with  = var.organization_arn != "" ? "Organization" : length(var.target_ou_arns) > 0 ? "OUs" : "Accounts"
    } : null

    transit_gateway = var.share_transit_gateway && var.transit_gateway_arn != "" ? {
      share_id     = aws_ram_resource_share.transit_gateway[0].id
      share_arn    = aws_ram_resource_share.transit_gateway[0].arn
      shared_with  = var.organization_arn != "" ? "Organization" : "OUs/Accounts"
    } : null

    resolver_rules = var.share_resolver_rules && length(var.resolver_rule_arns) > 0 ? {
      share_id     = aws_ram_resource_share.resolver_rules[0].id
      share_arn    = aws_ram_resource_share.resolver_rules[0].arn
      rules_count  = length(var.resolver_rule_arns)
      shared_with  = var.organization_arn != "" ? "Organization" : "OUs/Accounts"
    } : null
  }
}
