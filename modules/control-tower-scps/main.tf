# Control Tower Service Control Policies Module
# Enforces network governance guardrails across AWS Organization

# Network Governance SCP - Forces IPAM usage and prevents rogue networking
resource "aws_organizations_policy" "network_governance" {
  name        = var.network_governance_policy_name
  description = "Enforces IPAM usage, prevents Transit Gateway/VPC Peering, centralizes internet egress"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Force IPAM usage for VPC creation
      var.enforce_ipam_usage ? [{
        Sid    = "DenyVPCCreationWithoutIPAM"
        Effect = "Deny"
        Action = "ec2:CreateVpc"
        Resource = "*"
        Condition = {
          Null = {
            "ec2:Ipv4IpamPoolId" = "true"
          }
        }
      }] : [],

      # Prevent Transit Gateway (force Cloud WAN)
      var.prevent_transit_gateway ? [{
        Sid    = "DenyTransitGatewayCreation"
        Effect = "Deny"
        Action = [
          "ec2:CreateTransitGateway",
          "ec2:CreateTransitGatewayVpcAttachment",
          "ec2:CreateTransitGatewayPeeringAttachment"
        ]
        Resource = "*"
      }] : [],

      # Prevent VPC Peering (force Cloud WAN)
      var.prevent_vpc_peering ? [{
        Sid    = "DenyVPCPeering"
        Effect = "Deny"
        Action = [
          "ec2:CreateVpcPeeringConnection",
          "ec2:AcceptVpcPeeringConnection"
        ]
        Resource = "*"
      }] : [],

      # Prevent Internet Gateway in workload accounts (centralized egress)
      var.centralize_internet_egress ? [{
        Sid    = "DenyInternetGatewayInWorkloadAccounts"
        Effect = "Deny"
        Action = [
          "ec2:AttachInternetGateway",
          "ec2:CreateInternetGateway"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount" = var.exempted_account_ids
          }
        }
      }] : [],

      # Prevent NAT Gateway in workload accounts (centralized egress)
      var.centralize_nat_gateway ? [{
        Sid    = "DenyNATGatewayInWorkloadAccounts"
        Effect = "Deny"
        Action = [
          "ec2:CreateNatGateway"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount" = var.exempted_account_ids
          }
        }
      }] : []
    )
  })

  tags = var.tags
}

# Region Restriction SCP - Limits AWS operations to approved regions
resource "aws_organizations_policy" "region_restriction" {
  count = var.enable_region_restriction ? 1 : 0

  name        = var.region_restriction_policy_name
  description = "Restricts AWS operations to approved regions only"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllOutsideAllowedRegions"
        Effect = "Deny"
        NotAction = [
          # Global services that don't support regions
          "cloudfront:*",
          "iam:*",
          "route53:*",
          "support:*",
          "organizations:*",
          "budgets:*",
          "ce:*",
          "globalaccelerator:*",
          "importexport:*",
          "trustedadvisor:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Security Baseline SCP - Ensures security services remain enabled
resource "aws_organizations_policy" "security_baseline" {
  count = var.enable_security_baseline ? 1 : 0

  name        = var.security_baseline_policy_name
  description = "Prevents disabling of critical security services"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDisableGuardDuty"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
          "guardduty:StopMonitoringMembers",
          "guardduty:UpdateDetector"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyDisableSecurityHub"
        Effect = "Deny"
        Action = [
          "securityhub:DisableSecurityHub",
          "securityhub:DeleteMembers",
          "securityhub:DisassociateFromMasterAccount"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyDisableConfig"
        Effect = "Deny"
        Action = [
          "config:DeleteConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:StopConfigurationRecorder"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyDisableCloudTrail"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:ResourceTag/ControlTower" = "*"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# VPC Flow Logs Enforcement SCP
resource "aws_organizations_policy" "vpc_flow_logs" {
  count = var.enforce_vpc_flow_logs ? 1 : 0

  name        = var.vpc_flow_logs_policy_name
  description = "Requires VPC Flow Logs for all VPCs"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyVPCCreationWithoutFlowLogs"
        Effect = "Deny"
        Action = "ec2:CreateVpc"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestTag/FlowLogsEnabled" = "true"
          }
        }
      },
      {
        Sid    = "DenyDeleteFlowLogs"
        Effect = "Deny"
        Action = "ec2:DeleteFlowLogs"
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# ===========================
# Policy Attachments to OUs
# ===========================

# Attach Network Governance to Workloads OU
resource "aws_organizations_policy_attachment" "network_governance_workloads" {
  count = length(var.workload_ou_ids)

  policy_id = aws_organizations_policy.network_governance.id
  target_id = var.workload_ou_ids[count.index]
}

# Attach Region Restriction to all OUs
resource "aws_organizations_policy_attachment" "region_restriction" {
  count = var.enable_region_restriction && length(var.all_ou_ids) > 0 ? length(var.all_ou_ids) : 0

  policy_id = aws_organizations_policy.region_restriction[0].id
  target_id = var.all_ou_ids[count.index]
}

# Attach Security Baseline to Workloads OU
resource "aws_organizations_policy_attachment" "security_baseline" {
  count = var.enable_security_baseline && length(var.workload_ou_ids) > 0 ? length(var.workload_ou_ids) : 0

  policy_id = aws_organizations_policy.security_baseline[0].id
  target_id = var.workload_ou_ids[count.index]
}

# Attach VPC Flow Logs enforcement to Workloads OU
resource "aws_organizations_policy_attachment" "vpc_flow_logs" {
  count = var.enforce_vpc_flow_logs && length(var.workload_ou_ids) > 0 ? length(var.workload_ou_ids) : 0

  policy_id = aws_organizations_policy.vpc_flow_logs[0].id
  target_id = var.workload_ou_ids[count.index]
}
