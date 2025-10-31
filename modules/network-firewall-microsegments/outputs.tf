# Network Firewall Microsegments Module Outputs

# ===========================
# PCI Segment Rule Groups
# ===========================

output "pci_egress_rule_group_id" {
  description = "ID of the PCI egress firewall rule group"
  value       = var.enable_pci_rules ? aws_networkfirewall_rule_group.pci_egress[0].id : null
}

output "pci_egress_rule_group_arn" {
  description = "ARN of the PCI egress firewall rule group"
  value       = var.enable_pci_rules ? aws_networkfirewall_rule_group.pci_egress[0].arn : null
}

# ===========================
# API Segment Rule Groups
# ===========================

output "api_allowlist_rule_group_id" {
  description = "ID of the API allowlist firewall rule group"
  value       = var.enable_api_rules ? aws_networkfirewall_rule_group.api_egress_allowlist[0].id : null
}

output "api_allowlist_rule_group_arn" {
  description = "ARN of the API allowlist firewall rule group"
  value       = var.enable_api_rules ? aws_networkfirewall_rule_group.api_egress_allowlist[0].arn : null
}

# ===========================
# Database Segment Rule Groups
# ===========================

output "database_deny_all_rule_group_id" {
  description = "ID of the database deny-all firewall rule group"
  value       = var.enable_database_rules ? aws_networkfirewall_rule_group.database_deny_all[0].id : null
}

output "database_deny_all_rule_group_arn" {
  description = "ARN of the database deny-all firewall rule group"
  value       = var.enable_database_rules ? aws_networkfirewall_rule_group.database_deny_all[0].arn : null
}

# ===========================
# Non-Production Segment Rule Groups
# ===========================

output "nonprod_rule_group_id" {
  description = "ID of the non-production firewall rule group"
  value       = var.enable_nonprod_rules ? aws_networkfirewall_rule_group.nonprod_rules[0].id : null
}

output "nonprod_rule_group_arn" {
  description = "ARN of the non-production firewall rule group"
  value       = var.enable_nonprod_rules ? aws_networkfirewall_rule_group.nonprod_rules[0].arn : null
}

# ===========================
# B2B Partner Segment Rule Groups
# ===========================

output "b2b_dmz_rule_group_id" {
  description = "ID of the B2B DMZ firewall rule group"
  value       = var.enable_b2b_rules ? aws_networkfirewall_rule_group.b2b_dmz_rules[0].id : null
}

output "b2b_dmz_rule_group_arn" {
  description = "ARN of the B2B DMZ firewall rule group"
  value       = var.enable_b2b_rules ? aws_networkfirewall_rule_group.b2b_dmz_rules[0].arn : null
}

# ===========================
# General Production Segment Rule Groups
# ===========================

output "prod_general_rule_group_id" {
  description = "ID of the general production firewall rule group"
  value       = var.enable_prod_general_rules ? aws_networkfirewall_rule_group.prod_general_rules[0].id : null
}

output "prod_general_rule_group_arn" {
  description = "ARN of the general production firewall rule group"
  value       = var.enable_prod_general_rules ? aws_networkfirewall_rule_group.prod_general_rules[0].arn : null
}

# ===========================
# Global Rule Groups
# ===========================

output "threat_intelligence_rule_group_id" {
  description = "ID of the threat intelligence firewall rule group"
  value       = var.enable_threat_intelligence ? aws_networkfirewall_rule_group.threat_intelligence[0].id : null
}

output "threat_intelligence_rule_group_arn" {
  description = "ARN of the threat intelligence firewall rule group"
  value       = var.enable_threat_intelligence ? aws_networkfirewall_rule_group.threat_intelligence[0].arn : null
}

output "ddos_protection_rule_group_id" {
  description = "ID of the DDoS protection firewall rule group"
  value       = var.enable_ddos_protection ? aws_networkfirewall_rule_group.ddos_protection[0].id : null
}

output "ddos_protection_rule_group_arn" {
  description = "ARN of the DDoS protection firewall rule group"
  value       = var.enable_ddos_protection ? aws_networkfirewall_rule_group.ddos_protection[0].arn : null
}

# ===========================
# All Rule Groups Map
# ===========================

output "rule_group_ids" {
  description = "Map of all firewall rule group IDs"
  value = {
    pci_egress           = var.enable_pci_rules ? aws_networkfirewall_rule_group.pci_egress[0].id : null
    api_allowlist        = var.enable_api_rules ? aws_networkfirewall_rule_group.api_egress_allowlist[0].id : null
    database_deny_all    = var.enable_database_rules ? aws_networkfirewall_rule_group.database_deny_all[0].id : null
    nonprod              = var.enable_nonprod_rules ? aws_networkfirewall_rule_group.nonprod_rules[0].id : null
    b2b_dmz              = var.enable_b2b_rules ? aws_networkfirewall_rule_group.b2b_dmz_rules[0].id : null
    prod_general         = var.enable_prod_general_rules ? aws_networkfirewall_rule_group.prod_general_rules[0].id : null
    threat_intelligence  = var.enable_threat_intelligence ? aws_networkfirewall_rule_group.threat_intelligence[0].id : null
    ddos_protection      = var.enable_ddos_protection ? aws_networkfirewall_rule_group.ddos_protection[0].id : null
  }
}

output "rule_group_arns" {
  description = "Map of all firewall rule group ARNs"
  value = {
    pci_egress           = var.enable_pci_rules ? aws_networkfirewall_rule_group.pci_egress[0].arn : null
    api_allowlist        = var.enable_api_rules ? aws_networkfirewall_rule_group.api_egress_allowlist[0].arn : null
    database_deny_all    = var.enable_database_rules ? aws_networkfirewall_rule_group.database_deny_all[0].arn : null
    nonprod              = var.enable_nonprod_rules ? aws_networkfirewall_rule_group.nonprod_rules[0].arn : null
    b2b_dmz              = var.enable_b2b_rules ? aws_networkfirewall_rule_group.b2b_dmz_rules[0].arn : null
    prod_general         = var.enable_prod_general_rules ? aws_networkfirewall_rule_group.prod_general_rules[0].arn : null
    threat_intelligence  = var.enable_threat_intelligence ? aws_networkfirewall_rule_group.threat_intelligence[0].arn : null
    ddos_protection      = var.enable_ddos_protection ? aws_networkfirewall_rule_group.ddos_protection[0].arn : null
  }
}

# ===========================
# Microsegmentation Summary
# ===========================

output "microsegmentation_summary" {
  description = "Summary of microsegmentation firewall rules"
  value = {
    enabled_rule_groups = {
      pci_segment        = var.enable_pci_rules
      api_segment        = var.enable_api_rules
      database_segment   = var.enable_database_rules
      nonprod_segments   = var.enable_nonprod_rules
      b2b_segment        = var.enable_b2b_rules
      prod_general       = var.enable_prod_general_rules
      threat_intel       = var.enable_threat_intelligence
      ddos_protection    = var.enable_ddos_protection
    }

    security_posture = {
      pci_isolation      = var.enable_pci_rules ? "✓ PCI segment has whitelist-only egress with alerts" : "✗ PCI rules not enabled"
      database_isolation = var.enable_database_rules ? "✓ Database egress completely blocked" : "✗ Database rules not enabled"
      nonprod_isolation  = var.enable_nonprod_rules ? "✓ Non-prod blocked from production segments" : "✗ Non-prod rules not enabled"
      b2b_isolation      = var.enable_b2b_rules ? "✓ B2B partners limited to API access only" : "✗ B2B rules not enabled"
      threat_protection  = var.enable_threat_intelligence ? "✓ Threat intelligence blocklist active" : "✗ Threat intel not enabled"
      ddos_protection    = var.enable_ddos_protection ? "✓ DDoS rate limiting active" : "✗ DDoS protection not enabled"
    }

    segment_cidrs = {
      pci          = var.pci_segment_cidr
      api          = var.api_segment_cidr
      database     = var.database_segment_cidr
      b2b          = var.b2b_segment_cidr
      prod_general = var.prod_general_segment_cidr
      nonprod      = var.nonprod_segment_cidrs
    }
  }
}
