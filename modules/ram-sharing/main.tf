# RAM (Resource Access Manager) Sharing Module
# Shares Cloud WAN Core Network and IPAM pools across AWS Organization

# ===========================
# Cloud WAN Core Network Sharing
# ===========================

# Share Core Network with organization
resource "aws_ram_resource_share" "core_network" {
  count = var.share_core_network ? 1 : 0

  name                      = "${var.resource_share_name_prefix}-core-network"
  allow_external_principals = false

  tags = merge(var.tags, {
    Name     = "${var.resource_share_name_prefix}-core-network"
    Resource = "CloudWAN-CoreNetwork"
  })
}

# Associate Core Network with RAM share
resource "aws_ram_resource_association" "core_network" {
  count = var.share_core_network && var.core_network_arn != "" ? 1 : 0

  resource_arn       = var.core_network_arn
  resource_share_arn = aws_ram_resource_share.core_network[0].arn
}

# Share Core Network with entire organization
resource "aws_ram_principal_association" "core_network_organization" {
  count = var.share_core_network && var.organization_arn != "" ? 1 : 0

  principal          = var.organization_arn
  resource_share_arn = aws_ram_resource_share.core_network[0].arn
}

# Share Core Network with specific OUs
resource "aws_ram_principal_association" "core_network_ous" {
  for_each = var.share_core_network && var.organization_arn == "" ? toset(var.target_ou_arns) : toset([])

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.core_network[0].arn
}

# Share Core Network with specific accounts
resource "aws_ram_principal_association" "core_network_accounts" {
  for_each = var.share_core_network ? toset(var.target_account_ids) : toset([])

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.core_network[0].arn
}

# ===========================
# IPAM Regional Pools Sharing (Additional)
# ===========================

# Share IPAM regional pools separately for granular control
resource "aws_ram_resource_share" "ipam_regional_pools" {
  count = var.share_ipam_regional_pools ? 1 : 0

  name                      = "${var.resource_share_name_prefix}-ipam-pools"
  allow_external_principals = false

  tags = merge(var.tags, {
    Name     = "${var.resource_share_name_prefix}-ipam-pools"
    Resource = "IPAM-RegionalPools"
  })
}

# Associate IPAM regional pools with RAM share
resource "aws_ram_resource_association" "ipam_regional_pools" {
  for_each = var.share_ipam_regional_pools ? toset(var.ipam_pool_arns) : toset([])

  resource_arn       = each.value
  resource_share_arn = aws_ram_resource_share.ipam_regional_pools[0].arn
}

# Share IPAM pools with entire organization
resource "aws_ram_principal_association" "ipam_pools_organization" {
  count = var.share_ipam_regional_pools && var.organization_arn != "" ? 1 : 0

  principal          = var.organization_arn
  resource_share_arn = aws_ram_resource_share.ipam_regional_pools[0].arn
}

# Share IPAM pools with specific OUs
resource "aws_ram_principal_association" "ipam_pools_ous" {
  for_each = var.share_ipam_regional_pools && var.organization_arn == "" ? toset(var.target_ou_arns) : toset([])

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.ipam_regional_pools[0].arn
}

# ===========================
# Transit Gateway Sharing (Optional)
# ===========================

# Share Transit Gateway (if using hybrid architecture)
resource "aws_ram_resource_share" "transit_gateway" {
  count = var.share_transit_gateway && var.transit_gateway_arn != "" ? 1 : 0

  name                      = "${var.resource_share_name_prefix}-transit-gateway"
  allow_external_principals = false

  tags = merge(var.tags, {
    Name     = "${var.resource_share_name_prefix}-transit-gateway"
    Resource = "TransitGateway"
  })
}

resource "aws_ram_resource_association" "transit_gateway" {
  count = var.share_transit_gateway && var.transit_gateway_arn != "" ? 1 : 0

  resource_arn       = var.transit_gateway_arn
  resource_share_arn = aws_ram_resource_share.transit_gateway[0].arn
}

resource "aws_ram_principal_association" "transit_gateway_organization" {
  count = var.share_transit_gateway && var.transit_gateway_arn != "" && var.organization_arn != "" ? 1 : 0

  principal          = var.organization_arn
  resource_share_arn = aws_ram_resource_share.transit_gateway[0].arn
}

# ===========================
# Route 53 Resolver Rules Sharing
# ===========================

# Share Route 53 Resolver rules for centralized DNS
resource "aws_ram_resource_share" "resolver_rules" {
  count = var.share_resolver_rules && length(var.resolver_rule_arns) > 0 ? 1 : 0

  name                      = "${var.resource_share_name_prefix}-resolver-rules"
  allow_external_principals = false

  tags = merge(var.tags, {
    Name     = "${var.resource_share_name_prefix}-resolver-rules"
    Resource = "Route53ResolverRules"
  })
}

resource "aws_ram_resource_association" "resolver_rules" {
  for_each = var.share_resolver_rules ? toset(var.resolver_rule_arns) : toset([])

  resource_arn       = each.value
  resource_share_arn = aws_ram_resource_share.resolver_rules[0].arn
}

resource "aws_ram_principal_association" "resolver_rules_organization" {
  count = var.share_resolver_rules && length(var.resolver_rule_arns) > 0 && var.organization_arn != "" ? 1 : 0

  principal          = var.organization_arn
  resource_share_arn = aws_ram_resource_share.resolver_rules[0].arn
}
