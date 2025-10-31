# AWS Cloud WAN Core Network with Microsegmentation
# Phase 8: Fine-grained segment isolation for application-level security

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

# Core Network - The heart of AWS Cloud WAN with Microsegmentation
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

# Core Network Policy - Defines microsegments and routing
resource "aws_networkmanager_core_network_policy_attachment" "main" {
  core_network_id = aws_networkmanager_core_network.main.id
  policy_document = jsonencode(local.policy_document)
}

# Policy Document with Microsegmentation
locals {
  # Build microsegments from configuration
  microsegments = merge(
    # Production microsegments
    {
      for name, config in var.production_microsegments : "prod-${name}" => merge(config, {
        environment = "production"
        tier        = name
      })
    },
    # Non-production microsegments
    {
      for name, config in var.nonproduction_microsegments : "nonprod-${name}" => merge(config, {
        environment = "non-production"
        tier        = name
      })
    },
    # Shared services microsegments
    {
      for name, config in var.shared_microsegments : "shared-${name}" => merge(config, {
        environment = "shared"
        tier        = name
      })
    },
    # B2B partner microsegments
    var.enable_b2b_segments ? {
      for name, config in var.b2b_microsegments : "b2b-${name}" => merge(config, {
        environment = "b2b"
        tier        = name
      })
    } : {}
  )

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

    # Microsegments - Fine-grained isolation
    segments = [
      for segment_name, segment_config in local.microsegments : {
        name        = segment_name
        description = segment_config.description

        # Attachment behavior
        require-attachment-acceptance = segment_config.require_approval
        isolate-attachments           = segment_config.isolate

        # Regions where this segment is available
        edge-locations = var.edge_locations
      }
    ]

    # Segment Actions - Microsegmentation routing rules
    segment-actions = concat(
      # Default: All traffic goes through inspection
      var.enable_inspection_routing ? [
        for segment_name in keys(local.microsegments) : {
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

      # Allow specific inter-segment communication
      flatten([
        for segment_name, segment_config in local.microsegments : [
          for allowed_segment in lookup(segment_config, "allowed_segments", []) : {
            action  = "share"
            segment = segment_name
            mode    = "attachment-route"

            share-with = {
              segments = [allowed_segment]
            }
          }
        ]
      ]),

      # Block specific segment communication (explicit deny)
      flatten([
        for segment_name, segment_config in local.microsegments : [
          for blocked_segment in lookup(segment_config, "blocked_segments", []) : {
            action  = "deny"
            segment = segment_name

            when-sent-to = {
              segments = [blocked_segment]
            }
          }
        ]
      ]),

      # PCI segment rules - highly restrictive
      var.enable_pci_segment ? [
        {
          action  = "send-via"
          segment = "prod-pci"
          mode    = "attachment-route"

          when-sent-to = {
            segments = ["*"]
          }

          via = {
            network-function-groups = ["inspection-pci"] # Dedicated PCI firewall
          }
        }
      ] : [],

      # Database segment rules - no direct internet egress
      [
        for segment_name in keys(local.microsegments) : {
          action  = "deny"
          segment = segment_name

          when-sent-to = {
            segments = ["inspection"] # Prevent database segments from reaching internet
          }
        } if lookup(local.microsegments[segment_name], "no_internet", false)
      ],

      # Additional custom segment actions
      var.custom_segment_actions
    )

    # Attachment Policies - Tag-based routing to microsegments
    attachment-policies = [
      {
        rule-number     = 100
        condition-logic = "or"

        conditions = [
          for segment_name, segment_config in local.microsegments : {
            type     = "tag-value"
            operator = "equals"
            key      = "Segment"
            value    = segment_name
          }
        ]

        action = {
          association-method = "tag"
          tag-value-of-key   = "Segment"
        }
      }
    ]

    # Network Function Groups (inspection, pci-inspection, etc.)
    network-function-groups = concat(
      [
        {
          name                     = var.inspection_function_group_name
          description              = "Network inspection for general workloads"
          require-attachment-acceptance = false
        }
      ],
      var.enable_pci_segment ? [
        {
          name                     = "inspection-pci"
          description              = "Dedicated network inspection for PCI workloads"
          require-attachment-acceptance = true
        }
      ] : [],
      var.custom_network_function_groups
    )
  }
}
