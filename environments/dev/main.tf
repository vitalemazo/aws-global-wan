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
      Phase       = "5-MultiAZ-HA"
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
      Phase       = "5-MultiAZ-HA"
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
# Phase 5: Upgraded to Multi-AZ for high availability
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
  segment_name                = "shared"
  network_function_group_name = "inspection"

  # High Availability - Multi-AZ deployment
  multi_az = true

  # Cost optimization - no logging in dev
  enable_firewall_logging = false

  # Tags
  tags = merge(var.tags, {
    Region = "us-east-1"
    Name   = "useast1-inspection"
    HA     = "multi-az"
  })

  depends_on = [module.core_network]
}

# Phase 3: Inspection VPC in us-west-2
# Phase 5: Upgraded to Multi-AZ for high availability
module "inspection_vpc_uswest2" {
  source = "../../modules/inspection-vpc"

  providers = {
    aws = aws.uswest2
  }

  # Basic configuration
  vpc_name = "uswest2-inspection"
  region   = "us-west-2"

  # Network configuration
  vpc_cidr               = "10.2.0.0/16"
  public_subnet_cidr     = "10.2.0.0/24"
  firewall_subnet_cidr   = "10.2.1.0/24"
  attachment_subnet_cidr = "10.2.2.0/24"

  # Cloud WAN integration (uses same Core Network)
  core_network_id  = module.core_network.core_network_id
  core_network_arn = module.core_network.core_network_arn

  # Inspection routing configuration
  segment_name                = "shared"
  network_function_group_name = "inspection"

  # High Availability - Multi-AZ deployment
  multi_az = true

  # Cost optimization - no logging in dev
  enable_firewall_logging = false

  # Tags
  tags = merge(var.tags, {
    Region = "us-west-2"
    Name   = "uswest2-inspection"
    HA     = "multi-az"
  })

  depends_on = [module.core_network]
}

# Phase 4: Production Landing Zone VPC in us-east-1
module "landing_zone_prod_useast1" {
  source = "../../modules/landing-zone-vpc"

  # Basic configuration
  vpc_name     = "prod-useast1-app"
  region       = "us-east-1"
  vpc_cidr     = "10.10.0.0/16"
  segment_name = "prod"

  # Cloud WAN integration
  core_network_id  = module.core_network.core_network_id
  core_network_arn = module.core_network.core_network_arn

  # Single-AZ deployment for cost optimization
  multi_az = false

  # Create test instance
  create_test_instance   = true
  enable_ssh             = false
  enable_cloudwatch_logs = false

  # Tags
  tags = merge(var.tags, {
    Region      = "us-east-1"
    Segment     = "prod"
    Environment = "production"
    Name        = "prod-useast1-app"
  })

  depends_on = [
    module.core_network,
    module.inspection_vpc_useast1
  ]
}

# Phase 4: Non-Production Landing Zone VPC in us-west-2
module "landing_zone_nonprod_uswest2" {
  source = "../../modules/landing-zone-vpc"

  providers = {
    aws = aws.uswest2
  }

  # Basic configuration
  vpc_name     = "nonprod-uswest2-app"
  region       = "us-west-2"
  vpc_cidr     = "172.16.0.0/16"
  segment_name = "non-prod"

  # Cloud WAN integration
  core_network_id  = module.core_network.core_network_id
  core_network_arn = module.core_network.core_network_arn

  # Single-AZ deployment for cost optimization
  multi_az = false

  # Create test instance
  create_test_instance   = true
  enable_ssh             = false
  enable_cloudwatch_logs = false

  # Tags
  tags = merge(var.tags, {
    Region      = "us-west-2"
    Segment     = "non-prod"
    Environment = "non-production"
    Name        = "nonprod-uswest2-app"
  })

  depends_on = [
    module.core_network,
    module.inspection_vpc_uswest2
  ]
}
