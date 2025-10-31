# Security Groups 3-Tier Module Outputs

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = var.create_alb_sg ? aws_security_group.alb[0].id : null
}

output "web_tier_security_group_id" {
  description = "ID of the web tier security group"
  value       = var.create_web_tier ? aws_security_group.web[0].id : null
}

output "api_tier_security_group_id" {
  description = "ID of the API tier security group"
  value       = var.create_api_tier ? aws_security_group.api[0].id : null
}

output "database_security_group_id" {
  description = "ID of the database tier security group"
  value       = var.create_db_tier ? aws_security_group.database[0].id : null
}

output "cache_security_group_id" {
  description = "ID of the cache tier security group"
  value       = var.create_cache_tier ? aws_security_group.cache[0].id : null
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group"
  value       = var.create_bastion_sg ? aws_security_group.bastion[0].id : null
}

output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    alb      = var.create_alb_sg ? aws_security_group.alb[0].id : null
    web      = var.create_web_tier ? aws_security_group.web[0].id : null
    api      = var.create_api_tier ? aws_security_group.api[0].id : null
    database = var.create_db_tier ? aws_security_group.database[0].id : null
    cache    = var.create_cache_tier ? aws_security_group.cache[0].id : null
    bastion  = var.create_bastion_sg ? aws_security_group.bastion[0].id : null
  }
}

output "security_architecture_summary" {
  description = "Summary of security group architecture"
  value = {
    app_name = var.app_name

    tiers_created = {
      alb      = var.create_alb_sg
      web      = var.create_web_tier
      api      = var.create_api_tier
      database = var.create_db_tier
      cache    = var.create_cache_tier
      bastion  = var.create_bastion_sg
    }

    traffic_flow = var.create_web_tier && var.create_api_tier && var.create_db_tier ? [
      "Internet → ALB (${var.alb_ingress_cidr})",
      "ALB → Web Tier (port ${var.web_tier_port})",
      "Web Tier → API Tier (port ${var.api_tier_port})",
      "API Tier → Database (port ${var.db_port})",
      "Database → ISOLATED (no egress)"
    ] : []

    isolation_status = {
      database_isolated = var.create_db_tier ? "✓ Database has NO internet access" : "N/A"
      web_to_api_only   = var.create_web_tier && var.create_api_tier ? "✓ Web can only talk to API" : "N/A"
      api_to_db_only    = var.create_api_tier && var.create_db_tier ? "✓ API can only talk to DB" : "N/A"
    }
  }
}
