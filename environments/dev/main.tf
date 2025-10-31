# AWS Global WAN - Development Environment
# Phase 1: Core Network Foundation

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Configure remote backend
  # backend "s3" {
  #   bucket         = "my-terraform-state"
  #   key            = "aws-global-wan/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

# Primary AWS Provider (us-east-1)
provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "Terraform"
      Project     = "AWS-Global-WAN"
      Phase       = "1-CoreNetwork"
    }
  }
}

# Phase 1: Core Network Module
module "core_network" {
  source = "../../modules/core-network"

  # Global Network configuration
  global_network_name        = var.global_network_name
  global_network_description = "Dev environment for AWS Global WAN testing"

  # Core Network configuration
  core_network_name        = var.core_network_name
  core_network_description = "Multi-segment core network with inspection routing"

  # Regions where Core Network operates
  edge_locations = var.edge_locations

  # Network segments
  segments = {
    prod = {
      description = "Production segment - isolated"
      isolate     = true
    }
    non-prod = {
      description = "Non-production segment - isolated"
      isolate     = true
    }
    shared = {
      description = "Shared services - accessible from all"
      isolate     = false
    }
  }

  # Inspection routing (Phase 2 will use this)
  enable_inspection_routing     = true
  inspection_function_group_name = "inspection"

  # Attachment settings
  require_attachment_acceptance = false

  # Tags
  tags = var.tags
}
