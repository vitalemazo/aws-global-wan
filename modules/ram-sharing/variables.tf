# RAM Sharing Module Variables

# ===========================
# General Configuration
# ===========================

variable "resource_share_name_prefix" {
  description = "Prefix for RAM resource share names"
  type        = string
  default     = "global-wan"
}

variable "organization_arn" {
  description = "ARN of AWS Organization to share resources with entire org (leave empty for OU/account-specific sharing)"
  type        = string
  default     = ""
}

variable "target_ou_arns" {
  description = "List of OU ARNs to share resources with (used if organization_arn is empty)"
  type        = list(string)
  default     = []
}

variable "target_account_ids" {
  description = "List of specific account IDs to share resources with"
  type        = list(string)
  default     = []
}

# ===========================
# Cloud WAN Core Network
# ===========================

variable "share_core_network" {
  description = "Share Cloud WAN Core Network with organization/OUs/accounts"
  type        = bool
  default     = true
}

variable "core_network_arn" {
  description = "ARN of the Cloud WAN Core Network to share"
  type        = string
  default     = ""
}

# ===========================
# IPAM Pools
# ===========================

variable "share_ipam_regional_pools" {
  description = "Share IPAM regional pools with organization/OUs/accounts"
  type        = bool
  default     = true
}

variable "ipam_pool_arns" {
  description = "List of IPAM pool ARNs to share (regional pools)"
  type        = list(string)
  default     = []
}

# ===========================
# Transit Gateway (Optional)
# ===========================

variable "share_transit_gateway" {
  description = "Share Transit Gateway (for hybrid architectures)"
  type        = bool
  default     = false
}

variable "transit_gateway_arn" {
  description = "ARN of Transit Gateway to share"
  type        = string
  default     = ""
}

# ===========================
# Route 53 Resolver Rules
# ===========================

variable "share_resolver_rules" {
  description = "Share Route 53 Resolver rules for centralized DNS"
  type        = bool
  default     = false
}

variable "resolver_rule_arns" {
  description = "List of Route 53 Resolver rule ARNs to share"
  type        = list(string)
  default     = []
}

# ===========================
# Tags
# ===========================

variable "tags" {
  description = "Tags to apply to all RAM resource shares"
  type        = map(string)
  default     = {}
}
