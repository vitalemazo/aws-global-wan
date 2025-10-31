# Cloudflare Tunnel B2B Module Outputs

# ===========================
# Cloudflare Tunnel Outputs
# ===========================

output "tunnel_id" {
  description = "Cloudflare tunnel ID"
  value       = cloudflare_tunnel.b2b.id
}

output "tunnel_name" {
  description = "Cloudflare tunnel name"
  value       = cloudflare_tunnel.b2b.name
}

output "tunnel_cname" {
  description = "CNAME target for tunnel (format: <tunnel-id>.cfargotunnel.com)"
  value       = "${cloudflare_tunnel.b2b.id}.cfargotunnel.com"
}

# ===========================
# Access Application Outputs
# ===========================

output "s3_access_url" {
  description = "URL for S3 access via tunnel"
  value       = var.enable_s3_access ? "https://${var.s3_tunnel_hostname}" : null
}

output "database_access_url" {
  description = "URL for database access via tunnel"
  value       = var.enable_database_access ? "tcp://${var.database_tunnel_hostname}:${var.database_port}" : null
}

output "redis_access_url" {
  description = "URL for Redis access via tunnel"
  value       = var.enable_redis_access ? "tcp://${var.redis_tunnel_hostname}:${var.redis_port}" : null
}

output "ssh_bastion_url" {
  description = "URL for SSH bastion access via tunnel"
  value       = var.enable_ssh_bastion ? "tcp://${var.ssh_tunnel_hostname}:22" : null
}

output "api_endpoints" {
  description = "List of API endpoint URLs exposed via tunnel"
  value = {
    for endpoint in var.api_endpoints : endpoint.hostname => "https://${endpoint.hostname}${try(endpoint.path, "")}"
  }
}

# ===========================
# ECS Outputs
# ===========================

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.cloudflared.id
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.cloudflared.arn
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.cloudflared.name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.cloudflared.arn
}

output "cloudflared_security_group_id" {
  description = "Security group ID for cloudflared tasks"
  value       = aws_security_group.cloudflared.id
}

# ===========================
# IAM Outputs
# ===========================

output "ecs_execution_role_arn" {
  description = "ECS execution role ARN"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN"
  value       = aws_iam_role.ecs_task.arn
}

# ===========================
# CloudWatch Outputs
# ===========================

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for cloudflared"
  value       = aws_cloudwatch_log_group.cloudflared.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.cloudflared.arn
}

# ===========================
# Summary Output
# ===========================

output "tunnel_summary" {
  description = "Summary of Cloudflare Tunnel configuration"
  value = {
    tunnel_id   = cloudflare_tunnel.b2b.id
    tunnel_name = cloudflare_tunnel.b2b.name
    tunnel_cname = "${cloudflare_tunnel.b2b.id}.cfargotunnel.com"

    enabled_features = {
      s3_access        = var.enable_s3_access
      database_access  = var.enable_database_access
      redis_access     = var.enable_redis_access
      ssh_bastion      = var.enable_ssh_bastion
      api_endpoints    = length(var.api_endpoints) > 0
    }

    access_urls = merge(
      var.enable_s3_access ? { s3 = "https://${var.s3_tunnel_hostname}" } : {},
      var.enable_database_access ? { database = "tcp://${var.database_tunnel_hostname}:${var.database_port}" } : {},
      var.enable_redis_access ? { redis = "tcp://${var.redis_tunnel_hostname}:${var.redis_port}" } : {},
      var.enable_ssh_bastion ? { ssh = "tcp://${var.ssh_tunnel_hostname}:22" } : {},
      { for endpoint in var.api_endpoints : endpoint.hostname => "https://${endpoint.hostname}" }
    )

    vendor_access = {
      allowed_emails  = var.allowed_vendor_emails
      allowed_domains = var.allowed_vendor_domains
      session_duration = var.session_duration
    }

    ecs_deployment = {
      cluster_name  = aws_ecs_cluster.cloudflared.name
      service_name  = aws_ecs_service.cloudflared.name
      desired_count = var.cloudflared_desired_count
      cpu           = var.cloudflared_cpu
      memory        = var.cloudflared_memory
    }
  }
}

# ===========================
# Vendor Connection Instructions
# ===========================

output "vendor_connection_instructions" {
  description = "Instructions for vendors to connect via Cloudflare Tunnel"
  value = {
    s3_access = var.enable_s3_access ? {
      url = "https://${var.s3_tunnel_hostname}"
      instructions = [
        "1. Navigate to: https://${var.s3_tunnel_hostname}",
        "2. Authenticate with your email (${join(", ", var.allowed_vendor_domains)})",
        "3. Upload/download files via web interface",
        "4. Session expires after ${var.session_duration}"
      ]
    } : null

    database_access = var.enable_database_access ? {
      url = "tcp://${var.database_tunnel_hostname}:${var.database_port}"
      instructions = [
        "1. Install cloudflared: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/",
        "2. Run: cloudflared access tcp --hostname ${var.database_tunnel_hostname} --url localhost:${var.database_port}",
        "3. Authenticate in browser",
        "4. Connect database client to localhost:${var.database_port}",
        "5. Example (PostgreSQL): psql -h localhost -p ${var.database_port} -U vendoruser -d production"
      ]
    } : null

    redis_access = var.enable_redis_access ? {
      url = "tcp://${var.redis_tunnel_hostname}:${var.redis_port}"
      instructions = [
        "1. Install cloudflared: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/",
        "2. Run: cloudflared access tcp --hostname ${var.redis_tunnel_hostname} --url localhost:${var.redis_port}",
        "3. Authenticate in browser",
        "4. Connect Redis client to localhost:${var.redis_port}",
        "5. Example: redis-cli -h localhost -p ${var.redis_port}"
      ]
    } : null

    ssh_bastion = var.enable_ssh_bastion ? {
      url = "tcp://${var.ssh_tunnel_hostname}:22"
      instructions = [
        "1. Install cloudflared: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/",
        "2. Configure SSH config (~/.ssh/config):",
        "   Host ${var.ssh_tunnel_hostname}",
        "     ProxyCommand cloudflared access ssh --hostname %h",
        "3. SSH: ssh user@${var.ssh_tunnel_hostname}",
        "4. Authenticate in browser"
      ]
    } : null
  }
}
