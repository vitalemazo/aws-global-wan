# IPAM Module Variables

variable "ipam_name" {
  description = "Name for the IPAM resource"
  type        = string
  default     = "global-wan-ipam"
}

variable "ipam_description" {
  description = "Description for the IPAM resource"
  type        = string
  default     = "Centralized IP Address Management for Global WAN"
}

variable "operating_regions" {
  description = "List of AWS regions where IPAM will operate"
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "us-east-2"]
}

# Pool allocation rules
variable "production_pool" {
  description = "Production pool allocation rules"
  type = object({
    min_netmask     = number
    max_netmask     = number
    default_netmask = number
  })
  default = {
    min_netmask     = 16
    max_netmask     = 24
    default_netmask = 20
  }
}

variable "non_production_pool" {
  description = "Non-production pool allocation rules"
  type = object({
    min_netmask     = number
    max_netmask     = number
    default_netmask = number
  })
  default = {
    min_netmask     = 18
    max_netmask     = 24
    default_netmask = 22
  }
}

variable "shared_services_pool" {
  description = "Shared services pool allocation rules"
  type = object({
    min_netmask     = number
    max_netmask     = number
    default_netmask = number
  })
  default = {
    min_netmask     = 20
    max_netmask     = 24
    default_netmask = 24
  }
}

variable "inspection_pool" {
  description = "Inspection VPC pool allocation rules"
  type = object({
    min_netmask     = number
    max_netmask     = number
    default_netmask = number
  })
  default = {
    min_netmask     = 16
    max_netmask     = 20
    default_netmask = 20
  }
}

# Regional pool CIDRs
variable "regional_pool_cidrs" {
  description = "CIDR allocations for regional pools"
  type = object({
    production = map(string)
    non_production = map(string)
    shared_services = map(string)
    inspection = map(string)
  })
  default = {
    production = {
      "us-east-1" = "10.0.0.0/12"
      "us-west-2" = "10.16.0.0/12"
      "us-east-2" = "10.32.0.0/12"
    }
    non_production = {
      "us-east-1" = "172.16.0.0/14"
      "us-west-2" = "172.20.0.0/14"
      "us-east-2" = "172.24.0.0/14"
    }
    shared_services = {
      "us-east-1" = "192.168.0.0/18"
      "us-west-2" = "192.168.64.0/18"
      "us-east-2" = "192.168.128.0/18"
    }
    inspection = {
      "us-east-1" = "100.64.0.0/18"
      "us-west-2" = "100.64.64.0/18"
      "us-east-2" = "100.64.128.0/18"
    }
  }
}

# Resource sharing
variable "share_with_organization" {
  description = "Share IPAM pools with AWS Organization via RAM"
  type        = bool
  default     = true
}

variable "organization_arn" {
  description = "ARN of the AWS Organization to share IPAM pools with"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all IPAM resources"
  type        = map(string)
  default     = {}
}
