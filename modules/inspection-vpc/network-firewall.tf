# AWS Network Firewall Configuration
# Provides stateful inspection for all inter-segment traffic
# Configured with basic allow rules for lab environment

# S3 bucket for firewall logs (optional, cost optimization)
resource "aws_s3_bucket" "firewall_logs" {
  count  = var.enable_firewall_logging ? 1 : 0
  bucket = "${var.vpc_name}-firewall-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-firewall-logs"
  })
}

# S3 bucket lifecycle policy - delete logs after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "firewall_logs" {
  count  = var.enable_firewall_logging ? 1 : 0
  bucket = aws_s3_bucket.firewall_logs[0].id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# Firewall Rule Group - Basic Allow Rules
resource "aws_networkfirewall_rule_group" "allow_rules" {
  capacity = 100
  name     = "${var.vpc_name}-allow-rules"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "ANY"
          direction        = "FORWARD"
          protocol         = "IP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword = "sid:1"
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-allow-rules"
  })
}

# Firewall Policy
resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${var.vpc_name}-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allow_rules.arn
    }

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-policy"
  })
}

# Network Firewall
# Automatically spans multiple AZs when multiple firewall subnets provided
resource "aws_networkfirewall_firewall" "main" {
  name                = "${var.vpc_name}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = aws_vpc.inspection.id

  # Dynamic subnet mapping for single-AZ or multi-AZ
  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall
    content {
      subnet_id = subnet_mapping.value.id
    }
  }

  tags = merge(var.tags, {
    Name    = "${var.vpc_name}-firewall"
    MultiAZ = var.multi_az ? "true" : "false"
  })
}

# Firewall Logging Configuration
resource "aws_networkfirewall_logging_configuration" "main" {
  count        = var.enable_firewall_logging ? 1 : 0
  firewall_arn = aws_networkfirewall_firewall.main.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        bucketName = aws_s3_bucket.firewall_logs[0].id
        prefix     = "firewall-flow"
      }
      log_destination_type = "S3"
      log_type             = "FLOW"
    }

    log_destination_config {
      log_destination = {
        bucketName = aws_s3_bucket.firewall_logs[0].id
        prefix     = "firewall-alert"
      }
      log_destination_type = "S3"
      log_type             = "ALERT"
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Local values for firewall endpoints
locals {
  # Extract firewall endpoint IDs from all AZs
  # In multi-AZ, Network Firewall creates one endpoint per subnet
  firewall_endpoints = { for idx, az in local.azs :
    az => try(
      [for sync_state in aws_networkfirewall_firewall.main.firewall_status[0].sync_states :
        sync_state.attachment[0].endpoint_id
        if sync_state.availability_zone == az
      ][0],
      ""
    )
  }

  # Backward compatibility: single endpoint ID for single-AZ
  firewall_endpoint_id = try(
    aws_networkfirewall_firewall.main.firewall_status[0].sync_states[0].attachment[0].endpoint_id,
    ""
  )
}
