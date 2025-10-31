# Core Network Module Variables

variable "global_network_name" {
  description = "Name of the Global Network"
  type        = string
}

variable "global_network_description" {
  description = "Description of the Global Network"
  type        = string
  default     = "AWS Global WAN for multi-region connectivity"
}

variable "core_network_name" {
  description = "Name of the Core Network"
  type        = string
}

variable "core_network_description" {
  description = "Description of the Core Network"
  type        = string
  default     = "Core Network with prod/non-prod/shared segments"
}

variable "edge_locations" {
  description = "List of AWS regions where the Core Network operates"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]

  validation {
    condition     = length(var.edge_locations) > 0
    error_message = "At least one edge location is required."
  }
}

variable "segments" {
  description = "Map of network segments with their configurations"
  type = map(object({
    description = string
    isolate     = bool
  }))

  default = {
    prod = {
      description = "Production segment for customer-facing workloads"
      isolate     = true
    }
    non-prod = {
      description = "Non-production segment for dev/test/staging"
      isolate     = true
    }
    shared = {
      description = "Shared services accessible from all segments"
      isolate     = false
    }
  }
}

variable "enable_inspection_routing" {
  description = "Route all inter-segment traffic through inspection VPCs"
  type        = bool
  default     = true
}

variable "inspection_function_group_name" {
  description = "Name of the network function group for inspection VPCs"
  type        = string
  default     = "inspection"
}

variable "require_attachment_acceptance" {
  description = "Require manual approval for VPC attachments"
  type        = bool
  default     = false
}

variable "enable_vpn_ecmp" {
  description = "Enable ECMP for VPN connections"
  type        = bool
  default     = false
}

variable "asn_ranges" {
  description = "ASN ranges for BGP (for future VPN/DX use)"
  type        = list(string)
  default     = ["64512-64555"]
}

variable "custom_segment_actions" {
  description = "Additional custom segment actions for advanced routing"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
