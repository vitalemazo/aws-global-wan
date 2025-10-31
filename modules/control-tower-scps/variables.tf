# Control Tower SCPs Module Variables

# ===========================
# Network Governance Policy
# ===========================

variable "network_governance_policy_name" {
  description = "Name for the network governance SCP"
  type        = string
  default     = "NetworkGovernancePolicy"
}

variable "enforce_ipam_usage" {
  description = "Require all VPCs to be created from IPAM pools"
  type        = bool
  default     = true
}

variable "prevent_transit_gateway" {
  description = "Prevent Transit Gateway creation (force Cloud WAN)"
  type        = bool
  default     = true
}

variable "prevent_vpc_peering" {
  description = "Prevent VPC peering connections (force Cloud WAN)"
  type        = bool
  default     = true
}

variable "centralize_internet_egress" {
  description = "Prevent Internet Gateways in workload accounts"
  type        = bool
  default     = true
}

variable "centralize_nat_gateway" {
  description = "Prevent NAT Gateways in workload accounts"
  type        = bool
  default     = true
}

variable "exempted_account_ids" {
  description = "Account IDs exempted from Internet Gateway/NAT Gateway restrictions (e.g., Network account)"
  type        = list(string)
  default     = []
}

# ===========================
# Region Restriction Policy
# ===========================

variable "enable_region_restriction" {
  description = "Enable region restriction SCP"
  type        = bool
  default     = true
}

variable "region_restriction_policy_name" {
  description = "Name for the region restriction SCP"
  type        = string
  default     = "RegionRestrictionPolicy"
}

variable "allowed_regions" {
  description = "List of allowed AWS regions"
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "us-east-2"]
}

# ===========================
# Security Baseline Policy
# ===========================

variable "enable_security_baseline" {
  description = "Enable security baseline SCP"
  type        = bool
  default     = true
}

variable "security_baseline_policy_name" {
  description = "Name for the security baseline SCP"
  type        = string
  default     = "SecurityBaselinePolicy"
}

# ===========================
# VPC Flow Logs Policy
# ===========================

variable "enforce_vpc_flow_logs" {
  description = "Enforce VPC Flow Logs for all VPCs"
  type        = bool
  default     = false
}

variable "vpc_flow_logs_policy_name" {
  description = "Name for the VPC Flow Logs enforcement SCP"
  type        = string
  default     = "VPCFlowLogsPolicy"
}

# ===========================
# Organizational Units
# ===========================

variable "workload_ou_ids" {
  description = "List of Workload OU IDs to attach network governance policies"
  type        = list(string)
  default     = []
}

variable "all_ou_ids" {
  description = "List of all OU IDs for organization-wide policies (e.g., region restriction)"
  type        = list(string)
  default     = []
}

# ===========================
# Tags
# ===========================

variable "tags" {
  description = "Tags to apply to all SCP resources"
  type        = map(string)
  default     = {}
}
