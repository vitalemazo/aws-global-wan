# IPAM Module Outputs

# ===========================
# IPAM Core Resources
# ===========================

output "ipam_id" {
  description = "ID of the IPAM resource"
  value       = aws_vpc_ipam.main.id
}

output "ipam_arn" {
  description = "ARN of the IPAM resource"
  value       = aws_vpc_ipam.main.arn
}

output "ipam_scope_id" {
  description = "ID of the private IPAM scope"
  value       = aws_vpc_ipam_scope.private.id
}

output "ipam_scope_arn" {
  description = "ARN of the private IPAM scope"
  value       = aws_vpc_ipam_scope.private.arn
}

output "operating_regions" {
  description = "List of regions where IPAM operates"
  value       = var.operating_regions
}

# ===========================
# Top-Level Pool Outputs
# ===========================

output "production_pool_id" {
  description = "ID of the production top-level pool"
  value       = aws_vpc_ipam_pool.production.id
}

output "production_pool_arn" {
  description = "ARN of the production top-level pool"
  value       = aws_vpc_ipam_pool.production.arn
}

output "non_production_pool_id" {
  description = "ID of the non-production top-level pool"
  value       = aws_vpc_ipam_pool.non_production.id
}

output "non_production_pool_arn" {
  description = "ARN of the non-production top-level pool"
  value       = aws_vpc_ipam_pool.non_production.arn
}

output "shared_services_pool_id" {
  description = "ID of the shared services top-level pool"
  value       = aws_vpc_ipam_pool.shared_services.id
}

output "shared_services_pool_arn" {
  description = "ARN of the shared services top-level pool"
  value       = aws_vpc_ipam_pool.shared_services.arn
}

output "inspection_pool_id" {
  description = "ID of the inspection top-level pool"
  value       = aws_vpc_ipam_pool.inspection.id
}

output "inspection_pool_arn" {
  description = "ARN of the inspection top-level pool"
  value       = aws_vpc_ipam_pool.inspection.arn
}

# ===========================
# Regional Pool Outputs
# ===========================

output "production_regional_pool_ids" {
  description = "Map of region to production regional pool ID"
  value       = { for region, pool in aws_vpc_ipam_pool.production_regional : region => pool.id }
}

output "production_regional_pool_arns" {
  description = "Map of region to production regional pool ARN"
  value       = { for region, pool in aws_vpc_ipam_pool.production_regional : region => pool.arn }
}

output "non_production_regional_pool_ids" {
  description = "Map of region to non-production regional pool ID"
  value       = { for region, pool in aws_vpc_ipam_pool.non_production_regional : region => pool.id }
}

output "non_production_regional_pool_arns" {
  description = "Map of region to non-production regional pool ARN"
  value       = { for region, pool in aws_vpc_ipam_pool.non_production_regional : region => pool.arn }
}

output "shared_services_regional_pool_ids" {
  description = "Map of region to shared services regional pool ID"
  value       = { for region, pool in aws_vpc_ipam_pool.shared_services_regional : region => pool.id }
}

output "shared_services_regional_pool_arns" {
  description = "Map of region to shared services regional pool ARN"
  value       = { for region, pool in aws_vpc_ipam_pool.shared_services_regional : region => pool.arn }
}

output "inspection_regional_pool_ids" {
  description = "Map of region to inspection regional pool ID"
  value       = { for region, pool in aws_vpc_ipam_pool.inspection_regional : region => pool.id }
}

output "inspection_regional_pool_arns" {
  description = "Map of region to inspection regional pool ARN"
  value       = { for region, pool in aws_vpc_ipam_pool.inspection_regional : region => pool.arn }
}

# ===========================
# RAM Resource Share Outputs
# ===========================

output "ram_resource_share_id" {
  description = "ID of the RAM resource share (if enabled)"
  value       = var.share_with_organization ? aws_ram_resource_share.ipam[0].id : null
}

output "ram_resource_share_arn" {
  description = "ARN of the RAM resource share (if enabled)"
  value       = var.share_with_organization ? aws_ram_resource_share.ipam[0].arn : null
}

# ===========================
# Summary Output
# ===========================

output "ipam_summary" {
  description = "Summary of IPAM configuration"
  value = {
    ipam_id          = aws_vpc_ipam.main.id
    scope_id         = aws_vpc_ipam_scope.private.id
    operating_regions = var.operating_regions
    pools = {
      production = {
        top_level_id = aws_vpc_ipam_pool.production.id
        cidr         = "10.0.0.0/8"
        regions      = keys(aws_vpc_ipam_pool.production_regional)
      }
      non_production = {
        top_level_id = aws_vpc_ipam_pool.non_production.id
        cidr         = "172.16.0.0/12"
        regions      = keys(aws_vpc_ipam_pool.non_production_regional)
      }
      shared_services = {
        top_level_id = aws_vpc_ipam_pool.shared_services.id
        cidr         = "192.168.0.0/16"
        regions      = keys(aws_vpc_ipam_pool.shared_services_regional)
      }
      inspection = {
        top_level_id = aws_vpc_ipam_pool.inspection.id
        cidr         = "100.64.0.0/16"
        regions      = keys(aws_vpc_ipam_pool.inspection_regional)
      }
    }
    shared_with_organization = var.share_with_organization
  }
}
