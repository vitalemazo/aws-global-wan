# AWS Cloud WAN Core Network Module
# Phase 1: Foundation for multi-region, multi-segment network

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Global Network - Required for Core Network
resource "aws_networkmanager_global_network" "main" {
  description = var.global_network_description

  tags = merge(
    var.tags,
    {
      Name = var.global_network_name
    }
  )
}

# Core Network - The heart of AWS Cloud WAN
resource "aws_networkmanager_core_network" "main" {
  global_network_id = aws_networkmanager_global_network.main.id
  description       = var.core_network_description

  create_base_policy = false # We'll manage the policy explicitly

  tags = merge(
    var.tags,
    {
      Name = var.core_network_name
    }
  )
}

# Core Network Policy - Defines segments and routing
resource "aws_networkmanager_core_network_policy_attachment" "main" {
  core_network_id = aws_networkmanager_core_network.main.id
  policy_document = jsonencode(local.policy_document)
}

# Policy Document
locals {
  policy_document = {
    version = "2021.12"

    # Core network configuration
    core-network-configuration = {
      vpn-ecmp-support = var.enable_vpn_ecmp
      asn-ranges       = var.asn_ranges

      # Edge locations where the Core Network operates
      edge-locations = [
        for region in var.edge_locations : {
          location = region
        }
      ]
    }

    # Network Segments (prod, non-prod, shared)
    segments = [
      for segment_name, segment_config in var.segments : {
        name        = segment_name
        description = segment_config.description

        # Attachment behavior
        require-attachment-acceptance = var.require_attachment_acceptance
        isolate-attachments           = segment_config.isolate

        # Regions where this segment is available
        edge-locations = var.edge_locations
      }
    ]

    # Segment Actions - Routing between segments
    segment-actions = concat(
      # If inspection routing is enabled, route all traffic through inspection VPCs
      var.enable_inspection_routing ? [
        for segment_name in keys(var.segments) : {
          action  = "send-via"
          segment = segment_name
          mode    = "attachment-route"

          when-sent-to = {
            segments = ["*"]
          }

          via = {
            network-function-groups = [var.inspection_function_group_name]
          }
        }
      ] : [],

      # Additional custom segment actions
      var.custom_segment_actions
    )

    # Attachment Policies - How VPCs attach to segments
    attachment-policies = [
      # Prod segment - attach based on tag
      {
        rule-number      = 100
        condition-logic  = "or"
        conditions = [
          {
            type  = "tag-value"
            key   = "segment"
            value = "prod"
          }
        ]
        action = {
          association-method = "tag"
          segment            = "prod"
        }
      },

      # Non-prod segment - attach based on tag
      {
        rule-number      = 200
        condition-logic  = "or"
        conditions = [
          {
            type  = "tag-value"
            key   = "segment"
            value = "non-prod"
          }
        ]
        action = {
          association-method = "tag"
          segment            = "non-prod"
        }
      },

      # Shared segment - attach based on tag
      {
        rule-number      = 300
        condition-logic  = "or"
        conditions = [
          {
            type  = "tag-value"
            key   = "segment"
            value = "shared"
          }
        ]
        action = {
          association-method = "tag"
          segment            = "shared"
        }
      }
    ]
  }
}
