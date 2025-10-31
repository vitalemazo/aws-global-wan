# Network Firewall Rules for Microsegmentation
# Phase 8: Segment-specific firewall rules for fine-grained control

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ===========================
# PCI Segment Rules - Highly Restrictive
# ===========================

resource "aws_networkfirewall_rule_group" "pci_egress" {
  count = var.enable_pci_rules ? 1 : 0

  name     = "${var.firewall_name_prefix}-pci-egress"
  type     = "STATEFUL"
  capacity = 200

  rule_group {
    rules_source {
      stateful_rule {
        action = "ALERT"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          protocol         = "TCP"
          source           = var.pci_segment_cidr
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["100"]
        }
        rule_option {
          keyword  = "msg"
          settings = ["PCI segment unexpected traffic"]
        }
      }

      # Allow only specific whitelisted destinations
      stateful_rule {
        action = "PASS"
        header {
          destination      = var.pci_allowed_destinations[0]
          destination_port = "443"
          protocol         = "TCP"
          source           = var.pci_segment_cidr
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["101"]
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.firewall_name_prefix}-pci-egress"
    Segment = "pci"
  })
}

# ===========================
# API Segment Rules - Limited Egress
# ===========================

resource "aws_networkfirewall_rule_group" "api_egress_allowlist" {
  count = var.enable_api_rules ? 1 : 0

  name     = "${var.firewall_name_prefix}-api-egress-allowlist"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = var.api_allowed_domains
      }
    }

    rule_variables {
      ip_sets {
        key = "API_SEGMENT"
        ip_set {
          definition = [var.api_segment_cidr]
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.firewall_name_prefix}-api-egress-allowlist"
    Segment = "api"
  })
}

# ===========================
# Database Segment Rules - No Internet
# ===========================

resource "aws_networkfirewall_rule_group" "database_deny_all" {
  count = var.enable_database_rules ? 1 : 0

  name     = "${var.firewall_name_prefix}-database-deny-all"
  type     = "STATEFUL"
  capacity = 50

  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          protocol         = "TCP"
          source           = var.database_segment_cidr
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["200"]
        }
        rule_option {
          keyword  = "msg"
          settings = ["Database segment attempting egress - BLOCKED"]
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.firewall_name_prefix}-database-deny-all"
    Segment = "database"
  })
}

# ===========================
# Non-Production Segment Rules - Dev/Test/Staging
# ===========================

resource "aws_networkfirewall_rule_group" "nonprod_rules" {
  count = var.enable_nonprod_rules ? 1 : 0

  name     = "${var.firewall_name_prefix}-nonprod-general"
  type     = "STATEFUL"
  capacity = 150

  rule_group {
    rules_source {
      # Allow common development tools
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "443"
          protocol         = "TCP"
          source           = var.nonprod_segment_cidrs[0]
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["300"]
        }
      }

      # Block access to production segments
      stateful_rule {
        action = "DROP"
        header {
          destination      = var.production_segment_cidrs[0]
          destination_port = "ANY"
          protocol         = "TCP"
          source           = var.nonprod_segment_cidrs[0]
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["301"]
        }
        rule_option {
          keyword  = "msg"
          settings = ["Non-prod attempting access to prod - BLOCKED"]
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.firewall_name_prefix}-nonprod-general"
    Segment = "non-production"
  })
}

# ===========================
# B2B Partner Segment Rules - DMZ
# ===========================

resource "aws_networkfirewall_rule_group" "b2b_dmz_rules" {
  count = var.enable_b2b_rules ? 1 : 0

  name     = "${var.firewall_name_prefix}-b2b-dmz"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      # Allow only specific API endpoints for partners
      stateful_rule {
        action = "PASS"
        header {
          destination      = var.api_segment_cidr
          destination_port = "443"
          protocol         = "TCP"
          source           = var.b2b_segment_cidr
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["400"]
        }
      }

      # Block all other destinations
      stateful_rule {
        action = "DROP"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          protocol         = "TCP"
          source           = var.b2b_segment_cidr
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["401"]
        }
        rule_option {
          keyword  = "msg"
          settings = ["B2B partner blocked from unauthorized destination"]
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.firewall_name_prefix}-b2b-dmz"
    Segment = "b2b"
  })
}

# ===========================
# General Production Segment Rules
# ===========================

resource "aws_networkfirewall_rule_group" "prod_general_rules" {
  count = var.enable_prod_general_rules ? 1 : 0

  name     = "${var.firewall_name_prefix}-prod-general"
  type     = "STATEFUL"
  capacity = 200

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = var.prod_blocked_domains
      }
    }

    rule_variables {
      ip_sets {
        key = "PROD_GENERAL_SEGMENT"
        ip_set {
          definition = [var.prod_general_segment_cidr]
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.firewall_name_prefix}-prod-general"
    Segment = "prod-general"
  })
}

# ===========================
# Threat Intelligence Rules (All Segments)
# ===========================

resource "aws_networkfirewall_rule_group" "threat_intelligence" {
  count = var.enable_threat_intelligence ? 1 : 0

  name     = "${var.firewall_name_prefix}-threat-intel"
  type     = "STATEFUL"
  capacity = 300

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = var.threat_intelligence_blocklist
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.firewall_name_prefix}-threat-intel"
    Type = "global"
  })
}

# ===========================
# DDoS Protection Rules
# ===========================

resource "aws_networkfirewall_rule_group" "ddos_protection" {
  count = var.enable_ddos_protection ? 1 : 0

  name     = "${var.firewall_name_prefix}-ddos-protection"
  type     = "STATEFUL"
  capacity = 50

  rule_group {
    # Rate limiting per source IP
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }

    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["500"]
        }
        rule_option {
          keyword  = "threshold"
          settings = ["type both, track by_src, count 100, seconds 60"]
        }
        rule_option {
          keyword  = "msg"
          settings = ["DDoS: Too many connections from single source"]
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.firewall_name_prefix}-ddos-protection"
    Type = "global"
  })
}
