# AWS IPAM Module
# Centralized IP Address Management for Global WAN architecture
# Manages IP allocation across multiple accounts and regions

# IPAM Resource
resource "aws_vpc_ipam" "main" {
  description = var.ipam_description

  dynamic "operating_regions" {
    for_each = var.operating_regions
    content {
      region_name = operating_regions.value
    }
  }

  tags = merge(var.tags, {
    Name = var.ipam_name
  })
}

# Private Scope for RFC1918 addresses
resource "aws_vpc_ipam_scope" "private" {
  ipam_id     = aws_vpc_ipam.main.id
  description = "Private RFC1918 address space for internal resources"

  tags = merge(var.tags, {
    Name = "${var.ipam_name}-private-scope"
    Type = "private"
  })
}

# ===========================
# Top-Level Pools
# ===========================

# Production Pool (10.0.0.0/8)
resource "aws_vpc_ipam_pool" "production" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam_scope.private.id
  locale         = "None"  # Top-level pool, not region-specific

  description = "Production workload IP space"

  allocation_min_netmask_length     = var.production_pool.min_netmask
  allocation_max_netmask_length     = var.production_pool.max_netmask
  allocation_default_netmask_length = var.production_pool.default_netmask

  auto_import = true

  tags = merge(var.tags, {
    Name        = "${var.ipam_name}-production-pool"
    Environment = "production"
    CIDR        = "10.0.0.0/8"
  })
}

resource "aws_vpc_ipam_pool_cidr" "production" {
  ipam_pool_id = aws_vpc_ipam_pool.production.id
  cidr         = "10.0.0.0/8"
}

# Non-Production Pool (172.16.0.0/12)
resource "aws_vpc_ipam_pool" "non_production" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam_scope.private.id
  locale         = "None"

  description = "Non-production (dev/test/staging) IP space"

  allocation_min_netmask_length     = var.non_production_pool.min_netmask
  allocation_max_netmask_length     = var.non_production_pool.max_netmask
  allocation_default_netmask_length = var.non_production_pool.default_netmask

  auto_import = true

  tags = merge(var.tags, {
    Name        = "${var.ipam_name}-non-production-pool"
    Environment = "non-production"
    CIDR        = "172.16.0.0/12"
  })
}

resource "aws_vpc_ipam_pool_cidr" "non_production" {
  ipam_pool_id = aws_vpc_ipam_pool.non_production.id
  cidr         = "172.16.0.0/12"
}

# Shared Services Pool (192.168.0.0/16)
resource "aws_vpc_ipam_pool" "shared_services" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam_scope.private.id
  locale         = "None"

  description = "Shared services (DNS, AD, monitoring) IP space"

  allocation_min_netmask_length     = var.shared_services_pool.min_netmask
  allocation_max_netmask_length     = var.shared_services_pool.max_netmask
  allocation_default_netmask_length = var.shared_services_pool.default_netmask

  auto_import = true

  tags = merge(var.tags, {
    Name        = "${var.ipam_name}-shared-services-pool"
    Environment = "shared"
    CIDR        = "192.168.0.0/16"
  })
}

resource "aws_vpc_ipam_pool_cidr" "shared_services" {
  ipam_pool_id = aws_vpc_ipam_pool.shared_services.id
  cidr         = "192.168.0.0/16"
}

# Inspection Pool (100.64.0.0/16 - CGNAT range)
resource "aws_vpc_ipam_pool" "inspection" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam_scope.private.id
  locale         = "None"

  description = "Inspection VPC and NAT Gateway IP space (CGNAT range)"

  allocation_min_netmask_length     = var.inspection_pool.min_netmask
  allocation_max_netmask_length     = var.inspection_pool.max_netmask
  allocation_default_netmask_length = var.inspection_pool.default_netmask

  auto_import = true

  tags = merge(var.tags, {
    Name        = "${var.ipam_name}-inspection-pool"
    Environment = "inspection"
    CIDR        = "100.64.0.0/16"
  })
}

resource "aws_vpc_ipam_pool_cidr" "inspection" {
  ipam_pool_id = aws_vpc_ipam_pool.inspection.id
  cidr         = "100.64.0.0/16"
}

# ===========================
# Regional Pools - Production
# ===========================

resource "aws_vpc_ipam_pool" "production_regional" {
  for_each = var.regional_pool_cidrs.production

  address_family      = "ipv4"
  ipam_scope_id       = aws_vpc_ipam_scope.private.id
  locale              = each.key
  source_ipam_pool_id = aws_vpc_ipam_pool.production.id

  description = "Production pool for ${each.key}"

  allocation_min_netmask_length     = var.production_pool.min_netmask
  allocation_max_netmask_length     = var.production_pool.max_netmask
  allocation_default_netmask_length = var.production_pool.default_netmask

  tags = merge(var.tags, {
    Name        = "${var.ipam_name}-production-${each.key}"
    Environment = "production"
    Region      = each.key
    CIDR        = each.value
  })
}

resource "aws_vpc_ipam_pool_cidr" "production_regional" {
  for_each = var.regional_pool_cidrs.production

  ipam_pool_id = aws_vpc_ipam_pool.production_regional[each.key].id
  cidr         = each.value
}

# ===========================
# Regional Pools - Non-Production
# ===========================

resource "aws_vpc_ipam_pool" "non_production_regional" {
  for_each = var.regional_pool_cidrs.non_production

  address_family      = "ipv4"
  ipam_scope_id       = aws_vpc_ipam_scope.private.id
  locale              = each.key
  source_ipam_pool_id = aws_vpc_ipam_pool.non_production.id

  description = "Non-production pool for ${each.key}"

  allocation_min_netmask_length     = var.non_production_pool.min_netmask
  allocation_max_netmask_length     = var.non_production_pool.max_netmask
  allocation_default_netmask_length = var.non_production_pool.default_netmask

  tags = merge(var.tags, {
    Name        = "${var.ipam_name}-non-production-${each.key}"
    Environment = "non-production"
    Region      = each.key
    CIDR        = each.value
  })
}

resource "aws_vpc_ipam_pool_cidr" "non_production_regional" {
  for_each = var.regional_pool_cidrs.non_production

  ipam_pool_id = aws_vpc_ipam_pool.non_production_regional[each.key].id
  cidr         = each.value
}

# ===========================
# Regional Pools - Shared Services
# ===========================

resource "aws_vpc_ipam_pool" "shared_services_regional" {
  for_each = var.regional_pool_cidrs.shared_services

  address_family      = "ipv4"
  ipam_scope_id       = aws_vpc_ipam_scope.private.id
  locale              = each.key
  source_ipam_pool_id = aws_vpc_ipam_pool.shared_services.id

  description = "Shared services pool for ${each.key}"

  allocation_min_netmask_length     = var.shared_services_pool.min_netmask
  allocation_max_netmask_length     = var.shared_services_pool.max_netmask
  allocation_default_netmask_length = var.shared_services_pool.default_netmask

  tags = merge(var.tags, {
    Name        = "${var.ipam_name}-shared-services-${each.key}"
    Environment = "shared"
    Region      = each.key
    CIDR        = each.value
  })
}

resource "aws_vpc_ipam_pool_cidr" "shared_services_regional" {
  for_each = var.regional_pool_cidrs.shared_services

  ipam_pool_id = aws_vpc_ipam_pool.shared_services_regional[each.key].id
  cidr         = each.value
}

# ===========================
# Regional Pools - Inspection
# ===========================

resource "aws_vpc_ipam_pool" "inspection_regional" {
  for_each = var.regional_pool_cidrs.inspection

  address_family      = "ipv4"
  ipam_scope_id       = aws_vpc_ipam_scope.private.id
  locale              = each.key
  source_ipam_pool_id = aws_vpc_ipam_pool.inspection.id

  description = "Inspection VPC pool for ${each.key}"

  allocation_min_netmask_length     = var.inspection_pool.min_netmask
  allocation_max_netmask_length     = var.inspection_pool.max_netmask
  allocation_default_netmask_length = var.inspection_pool.default_netmask

  tags = merge(var.tags, {
    Name        = "${var.ipam_name}-inspection-${each.key}"
    Environment = "inspection"
    Region      = each.key
    CIDR        = each.value
  })
}

resource "aws_vpc_ipam_pool_cidr" "inspection_regional" {
  for_each = var.regional_pool_cidrs.inspection

  ipam_pool_id = aws_vpc_ipam_pool.inspection_regional[each.key].id
  cidr         = each.value
}

# ===========================
# Resource Shares (RAM) for Cross-Account Access
# ===========================

# Share IPAM pools with organization
resource "aws_ram_resource_share" "ipam" {
  count = var.share_with_organization ? 1 : 0

  name                      = "${var.ipam_name}-share"
  allow_external_principals = false

  tags = merge(var.tags, {
    Name = "${var.ipam_name}-ram-share"
  })
}

# Associate IPAM with RAM share
resource "aws_ram_resource_association" "ipam_pools" {
  for_each = var.share_with_organization ? toset([
    aws_vpc_ipam_pool.production.arn,
    aws_vpc_ipam_pool.non_production.arn,
    aws_vpc_ipam_pool.shared_services.arn,
    aws_vpc_ipam_pool.inspection.arn
  ]) : toset([])

  resource_arn       = each.value
  resource_share_arn = aws_ram_resource_share.ipam[0].arn
}

# Share with organization
resource "aws_ram_principal_association" "organization" {
  count = var.share_with_organization ? 1 : 0

  principal          = var.organization_arn
  resource_share_arn = aws_ram_resource_share.ipam[0].arn
}
