# Core Network Microsegmentation Module Variables

# ===========================
# Global Network Configuration
# ===========================

variable "global_network_name" {
  description = "Name of the Global Network"
  type        = string
}

variable "global_network_description" {
  description = "Description of the Global Network"
  type        = string
  default     = "AWS Global WAN with microsegmentation for zero-trust architecture"
}

variable "core_network_name" {
  description = "Name of the Core Network"
  type        = string
}

variable "core_network_description" {
  description = "Description of the Core Network"
  type        = string
  default     = "Core Network with fine-grained microsegmentation"
}

variable "edge_locations" {
  description = "List of AWS regions where the Core Network operates"
  type        = list(string)
  default     = ["us-east-1", "us-west-2", "us-east-2"]

  validation {
    condition     = length(var.edge_locations) > 0
    error_message = "At least one edge location is required."
  }
}

# ===========================
# Production Microsegments
# ===========================

variable "production_microsegments" {
  description = "Production microsegments with fine-grained isolation"
  type = map(object({
    description       = string
    isolate           = bool
    require_approval  = bool
    allowed_segments  = optional(list(string), [])
    blocked_segments  = optional(list(string), [])
    no_internet       = optional(bool, false)
  }))

  default = {
    pci = {
      description      = "PCI-compliant workloads - highly isolated"
      isolate          = true
      require_approval = true
      allowed_segments = ["shared-dns", "shared-monitoring"]
      blocked_segments = []
      no_internet      = false
    }

    general = {
      description      = "General production applications"
      isolate          = true
      require_approval = false
      allowed_segments = ["prod-api", "prod-data", "shared-dns"]
      blocked_segments = ["nonprod-dev", "nonprod-test"]
      no_internet      = false
    }

    api = {
      description      = "API gateway tier - controlled egress"
      isolate          = false
      require_approval = false
      allowed_segments = ["prod-data", "shared-dns", "shared-monitoring"]
      blocked_segments = []
      no_internet      = false
    }

    data = {
      description      = "Databases and data warehouses - no internet"
      isolate          = true
      require_approval = true
      allowed_segments = ["shared-dns"]
      blocked_segments = []
      no_internet      = true
    }
  }
}

# ===========================
# Non-Production Microsegments
# ===========================

variable "nonproduction_microsegments" {
  description = "Non-production microsegments"
  type = map(object({
    description       = string
    isolate           = bool
    require_approval  = bool
    allowed_segments  = optional(list(string), [])
    blocked_segments  = optional(list(string), [])
    no_internet       = optional(bool, false)
  }))

  default = {
    dev = {
      description      = "Development environment"
      isolate          = true
      require_approval = false
      allowed_segments = ["nonprod-test", "shared-dns"]
      blocked_segments = ["prod-general", "prod-api", "prod-data", "prod-pci"]
      no_internet      = false
    }

    test = {
      description      = "Testing environment"
      isolate          = true
      require_approval = false
      allowed_segments = ["nonprod-staging", "shared-dns"]
      blocked_segments = ["prod-general", "prod-api", "prod-data", "prod-pci"]
      no_internet      = false
    }

    staging = {
      description      = "Staging environment - production-like"
      isolate          = true
      require_approval = false
      allowed_segments = ["shared-dns", "shared-monitoring"]
      blocked_segments = ["prod-general", "prod-api", "prod-data", "prod-pci"]
      no_internet      = false
    }
  }
}

# ===========================
# Shared Services Microsegments
# ===========================

variable "shared_microsegments" {
  description = "Shared services microsegments"
  type = map(object({
    description       = string
    isolate           = bool
    require_approval  = bool
    allowed_segments  = optional(list(string), [])
    blocked_segments  = optional(list(string), [])
    no_internet       = optional(bool, false)
  }))

  default = {
    dns = {
      description      = "DNS resolution services (Route 53 Resolver)"
      isolate          = false
      require_approval = false
      allowed_segments = ["*"] # DNS accessible from all segments
      blocked_segments = []
      no_internet      = false
    }

    monitoring = {
      description      = "Centralized monitoring (CloudWatch, Prometheus)"
      isolate          = false
      require_approval = false
      allowed_segments = ["*"] # Monitoring accessible from all segments
      blocked_segments = []
      no_internet      = true
    }

    security-tools = {
      description      = "Security tools (GuardDuty, Security Hub aggregation)"
      isolate          = true
      require_approval = true
      allowed_segments = []
      blocked_segments = []
      no_internet      = false
    }

    cicd = {
      description      = "CI/CD pipeline infrastructure"
      isolate          = true
      require_approval = false
      allowed_segments = ["nonprod-dev", "nonprod-test", "nonprod-staging"]
      blocked_segments = ["prod-pci"]
      no_internet      = false
    }
  }
}

# ===========================
# B2B Partner Microsegments
# ===========================

variable "enable_b2b_segments" {
  description = "Enable B2B partner microsegments"
  type        = bool
  default     = false
}

variable "b2b_microsegments" {
  description = "B2B partner microsegments (DMZ for external partners)"
  type = map(object({
    description       = string
    isolate           = bool
    require_approval  = bool
    allowed_segments  = optional(list(string), [])
    blocked_segments  = optional(list(string), [])
    no_internet       = optional(bool, false)
  }))

  default = {
    partners = {
      description      = "External partner access - DMZ"
      isolate          = true
      require_approval = true
      allowed_segments = ["prod-api"]  # Only API access for partners
      blocked_segments = ["prod-data", "prod-pci", "nonprod-dev"]
      no_internet      = false
    }

    vendors = {
      description      = "Vendor access - limited scope"
      isolate          = true
      require_approval = true
      allowed_segments = ["shared-monitoring"]
      blocked_segments = ["prod-general", "prod-api", "prod-data", "prod-pci"]
      no_internet      = false
    }
  }
}

# ===========================
# PCI Segment
# ===========================

variable "enable_pci_segment" {
  description = "Enable dedicated PCI segment with separate inspection"
  type        = bool
  default     = false
}

# ===========================
# Inspection Configuration
# ===========================

variable "enable_inspection_routing" {
  description = "Route all inter-segment traffic through inspection VPCs"
  type        = bool
  default     = true
}

variable "inspection_function_group_name" {
  description = "Name of the network function group for general inspection VPCs"
  type        = string
  default     = "inspection"
}

# ===========================
# Network Configuration
# ===========================

variable "enable_vpn_ecmp" {
  description = "Enable ECMP for VPN connections"
  type        = bool
  default     = false
}

variable "asn_ranges" {
  description = "ASN ranges for the core network"
  type        = list(string)
  default     = ["64512-65534"]
}

# ===========================
# Custom Configurations
# ===========================

variable "custom_segment_actions" {
  description = "Additional custom segment actions"
  type        = list(any)
  default     = []
}

variable "custom_network_function_groups" {
  description = "Additional custom network function groups"
  type        = list(any)
  default     = []
}

# ===========================
# Tags
# ===========================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
