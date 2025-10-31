# AWS Global WAN - Development Environment
# Phase 1: Core Network Foundation

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
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
      Phase       = "2-InspectionVPC"
    }
  }
}

# Secondary AWS Provider for us-west-2 (Phase 3)
provider "aws" {
  alias  = "uswest2"
  region = "us-west-2"

  default_tags {
    tags = {
      Environment = "dev"
      ManagedBy   = "Terraform"
      Project     = "AWS-Global-WAN"
      Phase       = "2-InspectionVPC"
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

# Phase 2: Inspection VPC in us-east-1
module "inspection_vpc_useast1" {
  source = "../../modules/inspection-vpc"

  # Basic configuration
  vpc_name = "useast1-inspection"
  region   = "us-east-1"

  # Network configuration
  vpc_cidr               = "10.1.0.0/16"
  public_subnet_cidr     = "10.1.0.0/24"
  firewall_subnet_cidr   = "10.1.1.0/24"
  attachment_subnet_cidr = "10.1.2.0/24"

  # Cloud WAN integration
  core_network_id  = module.core_network.core_network_id
  core_network_arn = module.core_network.core_network_arn

  # Inspection routing configuration
  segment_name                   = "shared"
  network_function_group_name    = "inspection"

  # Cost optimization - no logging in dev
  enable_firewall_logging = false

  # Tags
  tags = merge(var.tags, {
    Region = "us-east-1"
    Name   = "useast1-inspection"
  })

  depends_on = [module.core_network]
}
