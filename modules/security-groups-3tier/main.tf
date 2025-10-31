# Security Groups for 3-Tier Architecture
# Phase 8: Automated security group creation for web/api/database tiers

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
# Application Load Balancer Security Group
# ===========================

resource "aws_security_group" "alb" {
  count = var.create_alb_sg ? 1 : 0

  name        = "${var.app_name}-alb-sg"
  description = "Security group for Application Load Balancer - ${var.app_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.app_name}-alb-sg"
    Tier = "load-balancer"
    App  = var.app_name
  })
}

# ALB Ingress: HTTPS from CloudFront or internet
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count = var.create_alb_sg ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTPS from ${var.alb_ingress_cidr_description}"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = var.alb_ingress_cidr
}

# ALB Ingress: HTTP (redirect to HTTPS)
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count = var.create_alb_sg && var.allow_http_on_alb ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTP redirect to HTTPS"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = var.alb_ingress_cidr
}

# ALB Egress: To web tier only
resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  count = var.create_alb_sg ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "To web tier"

  from_port                    = var.web_tier_port
  to_port                      = var.web_tier_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web[0].id
}

# ===========================
# Web Tier Security Group
# ===========================

resource "aws_security_group" "web" {
  count = var.create_web_tier ? 1 : 0

  name        = "${var.app_name}-web-tier-sg"
  description = "Web tier security group - ${var.app_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.app_name}-web-tier-sg"
    Tier = "web"
    App  = var.app_name
  })
}

# Web Ingress: From ALB only
resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  count = var.create_web_tier && var.create_alb_sg ? 1 : 0

  security_group_id = aws_security_group.web[0].id
  description       = "From Application Load Balancer"

  from_port                    = var.web_tier_port
  to_port                      = var.web_tier_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb[0].id
}

# Web Egress: To API tier only
resource "aws_vpc_security_group_egress_rule" "web_to_api" {
  count = var.create_web_tier && var.create_api_tier ? 1 : 0

  security_group_id = aws_security_group.web[0].id
  description       = "To API tier"

  from_port                    = var.api_tier_port
  to_port                      = var.api_tier_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.api[0].id
}

# Web Egress: To shared services (DNS)
resource "aws_vpc_security_group_egress_rule" "web_to_dns" {
  count = var.create_web_tier ? 1 : 0

  security_group_id = aws_security_group.web[0].id
  description       = "DNS resolution"

  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
  cidr_ipv4   = var.vpc_cidr
}

# Web Egress: HTTPS to AWS services (via VPC endpoints or NAT)
resource "aws_vpc_security_group_egress_rule" "web_to_aws" {
  count = var.create_web_tier && var.web_tier_needs_aws_access ? 1 : 0

  security_group_id = aws_security_group.web[0].id
  description       = "HTTPS to AWS services"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

# ===========================
# API Tier Security Group
# ===========================

resource "aws_security_group" "api" {
  count = var.create_api_tier ? 1 : 0

  name        = "${var.app_name}-api-tier-sg"
  description = "API tier security group - ${var.app_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.app_name}-api-tier-sg"
    Tier = "api"
    App  = var.app_name
  })
}

# API Ingress: From web tier only
resource "aws_vpc_security_group_ingress_rule" "api_from_web" {
  count = var.create_api_tier && var.create_web_tier ? 1 : 0

  security_group_id = aws_security_group.api[0].id
  description       = "From web tier"

  from_port                    = var.api_tier_port
  to_port                      = var.api_tier_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.web[0].id
}

# API Ingress: From other microservices (if enabled)
resource "aws_vpc_security_group_ingress_rule" "api_from_microservices" {
  count = var.create_api_tier && var.allow_api_from_vpc ? 1 : 0

  security_group_id = aws_security_group.api[0].id
  description       = "From other microservices in VPC"

  from_port   = var.api_tier_port
  to_port     = var.api_tier_port
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr
}

# API Egress: To database tier
resource "aws_vpc_security_group_egress_rule" "api_to_db" {
  count = var.create_api_tier && var.create_db_tier ? 1 : 0

  security_group_id = aws_security_group.api[0].id
  description       = "To database tier"

  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.database[0].id
}

# API Egress: To cache tier (Redis/Memcached)
resource "aws_vpc_security_group_egress_rule" "api_to_cache" {
  count = var.create_api_tier && var.create_cache_tier ? 1 : 0

  security_group_id = aws_security_group.api[0].id
  description       = "To cache tier"

  from_port                    = var.cache_port
  to_port                      = var.cache_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.cache[0].id
}

# API Egress: DNS
resource "aws_vpc_security_group_egress_rule" "api_to_dns" {
  count = var.create_api_tier ? 1 : 0

  security_group_id = aws_security_group.api[0].id
  description       = "DNS resolution"

  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"
  cidr_ipv4   = var.vpc_cidr
}

# API Egress: HTTPS to external APIs
resource "aws_vpc_security_group_egress_rule" "api_to_external" {
  count = var.create_api_tier && var.api_tier_needs_internet ? 1 : 0

  security_group_id = aws_security_group.api[0].id
  description       = "HTTPS to external APIs"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

# ===========================
# Database Tier Security Group
# ===========================

resource "aws_security_group" "database" {
  count = var.create_db_tier ? 1 : 0

  name        = "${var.app_name}-db-tier-sg"
  description = "Database tier security group - ${var.app_name} - NO INTERNET"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.app_name}-db-tier-sg"
    Tier = "database"
    App  = var.app_name
  })
}

# DB Ingress: From API tier only
resource "aws_vpc_security_group_ingress_rule" "db_from_api" {
  count = var.create_db_tier && var.create_api_tier ? 1 : 0

  security_group_id = aws_security_group.database[0].id
  description       = "From API tier"

  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.api[0].id
}

# DB Egress: NONE (database should not initiate outbound connections)
# No egress rules = complete isolation

# ===========================
# Cache Tier Security Group (Optional)
# ===========================

resource "aws_security_group" "cache" {
  count = var.create_cache_tier ? 1 : 0

  name        = "${var.app_name}-cache-tier-sg"
  description = "Cache tier security group (Redis/Memcached) - ${var.app_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.app_name}-cache-tier-sg"
    Tier = "cache"
    App  = var.app_name
  })
}

# Cache Ingress: From API tier only
resource "aws_vpc_security_group_ingress_rule" "cache_from_api" {
  count = var.create_cache_tier && var.create_api_tier ? 1 : 0

  security_group_id = aws_security_group.cache[0].id
  description       = "From API tier"

  from_port                    = var.cache_port
  to_port                      = var.cache_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.api[0].id
}

# Cache Egress: NONE
# No egress rules = cache is passive

# ===========================
# Bastion/Jump Host Security Group (Optional)
# ===========================

resource "aws_security_group" "bastion" {
  count = var.create_bastion_sg ? 1 : 0

  name        = "${var.app_name}-bastion-sg"
  description = "Bastion host security group - ${var.app_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.app_name}-bastion-sg"
    Tier = "bastion"
    App  = var.app_name
  })
}

# Bastion Ingress: SSH from corporate VPN/IP
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  count = var.create_bastion_sg ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  description       = "SSH from ${var.bastion_ingress_description}"

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.bastion_ingress_cidr
}

# Bastion Egress: SSH to database tier (for troubleshooting)
resource "aws_vpc_security_group_egress_rule" "bastion_to_db" {
  count = var.create_bastion_sg && var.create_db_tier ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  description       = "SSH to database tier"

  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.database[0].id
}

# Allow bastion SSH to database security group
resource "aws_vpc_security_group_ingress_rule" "db_from_bastion" {
  count = var.create_bastion_sg && var.create_db_tier ? 1 : 0

  security_group_id = aws_security_group.database[0].id
  description       = "SSH from bastion for troubleshooting"

  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion[0].id
}
