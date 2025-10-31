# Network Firewall Microsegments Module Variables

# ===========================
# Required Variables
# ===========================

variable "firewall_name_prefix" {
  description = "Prefix for firewall rule group names"
  type        = string
}

# ===========================
# Feature Toggles
# ===========================

variable "enable_pci_rules" {
  description = "Enable PCI segment firewall rules"
  type        = bool
  default     = true
}

variable "enable_api_rules" {
  description = "Enable API segment firewall rules"
  type        = bool
  default     = true
}

variable "enable_database_rules" {
  description = "Enable database segment firewall rules"
  type        = bool
  default     = true
}

variable "enable_nonprod_rules" {
  description = "Enable non-production segment firewall rules"
  type        = bool
  default     = true
}

variable "enable_b2b_rules" {
  description = "Enable B2B partner segment firewall rules"
  type        = bool
  default     = false
}

variable "enable_prod_general_rules" {
  description = "Enable general production segment firewall rules"
  type        = bool
  default     = true
}

variable "enable_threat_intelligence" {
  description = "Enable threat intelligence blocklist rules"
  type        = bool
  default     = true
}

variable "enable_ddos_protection" {
  description = "Enable DDoS protection rules (rate limiting)"
  type        = bool
  default     = true
}

# ===========================
# Segment CIDR Blocks
# ===========================

variable "pci_segment_cidr" {
  description = "CIDR block for PCI segment"
  type        = string
  default     = "10.100.0.0/16"
}

variable "api_segment_cidr" {
  description = "CIDR block for API segment"
  type        = string
  default     = "10.101.0.0/16"
}

variable "database_segment_cidr" {
  description = "CIDR block for database segment"
  type        = string
  default     = "10.102.0.0/16"
}

variable "b2b_segment_cidr" {
  description = "CIDR block for B2B partner segment"
  type        = string
  default     = "10.200.0.0/16"
}

variable "prod_general_segment_cidr" {
  description = "CIDR block for general production segment"
  type        = string
  default     = "10.103.0.0/16"
}

variable "nonprod_segment_cidrs" {
  description = "CIDR blocks for non-production segments (dev/test/staging)"
  type        = list(string)
  default     = ["10.10.0.0/16", "10.11.0.0/16", "10.12.0.0/16"]
}

variable "production_segment_cidrs" {
  description = "CIDR blocks for production segments (to block from non-prod)"
  type        = list(string)
  default     = ["10.100.0.0/16", "10.101.0.0/16", "10.102.0.0/16", "10.103.0.0/16"]
}

# ===========================
# PCI Segment Configuration
# ===========================

variable "pci_allowed_destinations" {
  description = "Whitelisted destinations for PCI segment egress (HTTPS only)"
  type        = list(string)
  default = [
    "10.255.1.0/24" # Shared services segment
  ]
}

# ===========================
# API Segment Configuration
# ===========================

variable "api_allowed_domains" {
  description = "Whitelisted domains for API segment egress"
  type        = list(string)
  default = [
    ".amazonaws.com",
    ".stripe.com",
    ".twilio.com",
    ".sendgrid.com"
  ]
}

# ===========================
# Production Segment Configuration
# ===========================

variable "prod_blocked_domains" {
  description = "Blocked domains for production segments (malware, phishing, etc.)"
  type        = list(string)
  default = [
    ".torproject.org",
    ".onion",
    ".tk",
    ".ml"
  ]
}

# ===========================
# Threat Intelligence
# ===========================

variable "threat_intelligence_blocklist" {
  description = "Threat intelligence blocklist (malicious domains/IPs)"
  type        = list(string)
  default = [
    # Example malicious domains - replace with actual threat intel feed
    "malware-example.com",
    "phishing-site.net",
    "c2-server.org"
  ]
}

# ===========================
# Tags
# ===========================

variable "tags" {
  description = "Tags to apply to all firewall rule groups"
  type        = map(string)
  default     = {}
}
