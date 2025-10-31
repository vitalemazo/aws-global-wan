# Control Tower Account Factory Module Outputs

# ===========================
# Landing Zone VPC Outputs
# ===========================

output "vpc_id" {
  description = "ID of the landing zone VPC"
  value       = module.landing_zone_vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the landing zone VPC (IPAM-allocated)"
  value       = module.landing_zone_vpc.vpc_cidr
}

output "cloudwan_attachment_id" {
  description = "Cloud WAN attachment ID"
  value       = module.landing_zone_vpc.cloudwan_attachment_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.landing_zone_vpc.private_subnet_ids
}

output "cloudwan_subnet_ids" {
  description = "IDs of Cloud WAN attachment subnets"
  value       = module.landing_zone_vpc.cloudwan_subnet_ids
}

output "test_instance_id" {
  description = "ID of test EC2 instance (if created)"
  value       = module.landing_zone_vpc.test_instance_id
}

output "test_instance_private_ip" {
  description = "Private IP of test EC2 instance (if created)"
  value       = module.landing_zone_vpc.test_instance_private_ip
}

# ===========================
# Security Baseline Outputs
# ===========================

output "vpc_flow_logs_log_group" {
  description = "CloudWatch Log Group for VPC Flow Logs"
  value       = var.enable_vpc_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "security_hub_enabled" {
  description = "Whether Security Hub is enabled"
  value       = var.enable_security_hub
}

output "config_recorder_name" {
  description = "AWS Config recorder name"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].name : null
}

# ===========================
# Account Summary
# ===========================

output "account_provisioning_summary" {
  description = "Summary of account provisioning"
  value = {
    account_name = var.account_name
    environment  = var.environment
    region       = var.region

    vpc = {
      id                  = module.landing_zone_vpc.vpc_id
      cidr                = module.landing_zone_vpc.vpc_cidr
      ipam_allocated      = true
      multi_az            = var.enable_multi_az
      cloudwan_segment    = local.cloud_wan_segment
      cloudwan_attachment = module.landing_zone_vpc.cloudwan_attachment_id
    }

    security_baseline = {
      vpc_flow_logs  = var.enable_vpc_flow_logs
      guardduty      = var.enable_guardduty
      security_hub   = var.enable_security_hub
      config_enabled = var.enable_config
    }

    test_resources = {
      test_instance_created = var.create_test_instance
      instance_id           = var.create_test_instance ? module.landing_zone_vpc.test_instance_id : null
      instance_ip           = var.create_test_instance ? module.landing_zone_vpc.test_instance_private_ip : null
    }
  }
}

# ===========================
# Deployment Instructions
# ===========================

output "next_steps" {
  description = "Next steps after account provisioning"
  value = <<-EOT
    Account Provisioned: ${var.account_name} (${var.environment})

    Landing Zone VPC:
    ================
    VPC ID: ${module.landing_zone_vpc.vpc_id}
    CIDR: ${module.landing_zone_vpc.vpc_cidr} (IPAM-allocated)
    Cloud WAN Segment: ${local.cloud_wan_segment}
    Cloud WAN Attachment: ${module.landing_zone_vpc.cloudwan_attachment_id}
    Multi-AZ: ${var.enable_multi_az}

    Security Baseline:
    =================
    ✓ VPC Flow Logs: ${var.enable_vpc_flow_logs ? "Enabled" : "Disabled"}
    ✓ GuardDuty: ${var.enable_guardduty ? "Enabled" : "Disabled"}
    ✓ Security Hub: ${var.enable_security_hub ? "Enabled" : "Disabled"}
    ✓ AWS Config: ${var.enable_config ? "Enabled" : "Disabled"}

    Network Connectivity:
    ====================
    - VPC is attached to Cloud WAN ${local.cloud_wan_segment} segment
    - Internet egress via centralized inspection VPCs
    - All traffic inspected by AWS Network Firewall
    - Cross-segment isolation enforced by Cloud WAN policies

    AWS Console Verification:
    ========================
    - VPC > Your VPCs > ${module.landing_zone_vpc.vpc_id}
    - VPC > Cloud WAN > Attachments > ${module.landing_zone_vpc.cloudwan_attachment_id}
    - VPC > IPAM > View allocations
    - GuardDuty > Summary
    - Security Hub > Summary
    - Config > Dashboard

    Ready for Workload Deployment!
  EOT
}
