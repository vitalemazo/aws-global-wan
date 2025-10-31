# Development Environment Variables

variable "primary_region" {
  description = "Primary AWS region for Terraform provider"
  type        = string
  default     = "us-east-1"
}

variable "global_network_name" {
  description = "Name of the Global Network"
  type        = string
  default     = "dev-global-wan"
}

variable "core_network_name" {
  description = "Name of the Core Network"
  type        = string
  default     = "dev-core-network"
}

variable "edge_locations" {
  description = "List of regions where Core Network will operate"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    CostCenter = "NetworkInfra"
    Owner      = "NetworkTeam"
  }
}
