<!--
Copyright (c) 2025 Vitale Mazo
All rights reserved.

This architecture and documentation is proprietary and confidential.
Unauthorized copying, modification, distribution, or use of this
architecture, documentation, or associated code is strictly prohibited.

Design by: Vitale Mazo
Year: 2025
-->


# AWS Global WAN - Future Roadmap

## Overview

This document outlines future phases for advanced enterprise networking and security capabilities, building on the Control Tower and IPAM foundation.

---

## Phase 8: Microsegmentation and Zero Trust Architecture

### Objective
Implement application-level security with microsegmentation beyond just prod/non-prod segments.

### Current State
```
Cloud WAN Segments (Coarse-grained):
├── prod (all production apps together)
├── non-prod (all dev/test together)
└── shared (all shared services together)

Issue: All prod apps can talk to each other by default
```

### Future State - Microsegmentation
```
Cloud WAN Segments (Fine-grained):
├── prod-pci (PCI-compliant workloads, highly isolated)
├── prod-general (general production apps)
├── prod-api (API gateway tier)
├── prod-data (databases, data warehouses)
├── non-prod-dev
├── non-prod-test
├── non-prod-staging
├── shared-dns
├── shared-monitoring
└── shared-security-tools

+ Security Groups (Application-level):
  - Allow only specific ports between specific apps
  - Deny by default, explicit allow rules
```

### Implementation Strategy

#### 8.1: Cloud WAN Microsegments
```hcl
# modules/core-network/policy-microsegments.tf
segments = {
  # Production microsegments
  prod_pci = {
    description = "PCI-compliant workloads - highly isolated"
    isolate     = true
    require_attachment_acceptance = true
  }

  prod_general = {
    description = "General production applications"
    isolate     = true
  }

  prod_api = {
    description = "API gateway tier - limited egress"
    isolate     = false  # Can talk to prod_data
    allowed_segments = ["prod_data", "shared_dns"]
  }

  prod_data = {
    description = "Databases and data warehouses"
    isolate     = true  # No internet egress
    egress_only = false
  }

  # B2B partner segment
  b2b_partners = {
    description = "External partner access - DMZ"
    isolate     = true
    inspection_required = true
  }
}
```

#### 8.2: Security Group Automation
```hcl
# modules/landing-zone-vpc/security-groups.tf
# Automatically create security groups based on app tier

resource "aws_security_group" "app_tier_web" {
  name        = "${var.app_name}-web-tier"
  description = "Web tier - accepts HTTPS from ALB only"
  vpc_id      = aws_vpc.landing_zone.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier_api.id]
  }

  tags = {
    Name = "${var.app_name}-web-tier"
    Tier = "web"
  }
}

resource "aws_security_group" "app_tier_api" {
  name        = "${var.app_name}-api-tier"
  description = "API tier - accepts from web tier only"
  vpc_id      = aws_vpc.landing_zone.id

  ingress {
    from_port       = 8443
    to_port         = 8443
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier_web.id]
  }

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier_db.id]
  }
}

resource "aws_security_group" "app_tier_db" {
  name        = "${var.app_name}-db-tier"
  description = "Database tier - accepts from API tier only, no internet"
  vpc_id      = aws_vpc.landing_zone.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier_api.id]
  }

  # NO egress to internet - database isolation
}
```

#### 8.3: Network Firewall Rules (Application-aware)
```hcl
# modules/inspection-vpc/firewall-rules-microsegmentation.tf

# PCI segment rules - highly restrictive
resource "aws_networkfirewall_rule_group" "pci_egress" {
  name     = "pci-egress-rules"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      stateful_rule {
        action = "ALERT"  # Alert on any unexpected traffic
        header {
          destination      = "ANY"
          destination_port = "ANY"
          protocol         = "TCP"
          source           = var.pci_segment_cidr
          source_port      = "ANY"
        }
        rule_option {
          keyword = "sid"
          settings = ["1"]
        }
      }
    }
  }
}

# API segment rules - limited egress
resource "aws_networkfirewall_rule_group" "api_egress_allowlist" {
  name     = "api-egress-allowlist"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets = [
          ".auth0.com",           # Authentication provider
          ".stripe.com",          # Payment processor
          ".api.partner.com",     # Approved partner APIs
          ".amazonaws.com"        # AWS services only
        ]
      }
    }
  }
}
```

### Benefits
- **Blast Radius Reduction**: Compromised app can't pivot to other apps
- **Compliance**: PCI/HIPAA apps isolated from general apps
- **Least Privilege**: Apps only access what they need
- **Audit Trail**: All inter-segment traffic logged

---

## Phase 9: Ingress Filtering and WAF Integration

### Objective
Secure inbound traffic from internet with Web Application Firewall and DDoS protection.

### Architecture
```
Internet
    ↓
AWS CloudFront (Global CDN)
    ↓ (HTTPS only)
AWS WAF (Application-layer filtering)
    ↓
Application Load Balancer (ALB) per landing zone
    ↓
Target Group (ECS/EKS/EC2)
    ↓
Cloud WAN (internal routing)
```

### Implementation

#### 9.1: CloudFront + WAF Module
```hcl
# modules/cloudfront-waf/main.tf

# WAF Web ACL with OWASP Top 10 protection
resource "aws_wafv2_web_acl" "app" {
  name  = "${var.app_name}-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS Managed Rules - OWASP Top 10
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # SQL injection protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rate limiting - prevent DDoS
  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Geo-blocking (optional)
  rule {
    name     = "GeoBlockRule"
    priority = 4

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = var.blocked_countries  # ["CN", "RU", "KP", etc.]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoBlockRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app_name}-waf"
    sampled_requests_enabled   = true
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = "PriceClass_All"
  web_acl_id          = aws_wafv2_web_acl.app.arn

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-${var.app_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB-${var.app_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Host", "CloudFront-Forwarded-Proto"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Custom domain with ACM certificate
  aliases = [var.custom_domain]

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
```

#### 9.2: Application Load Balancer per Landing Zone
```hcl
# modules/landing-zone-vpc/alb.tf

resource "aws_lb" "app" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  enable_waf_fail_open       = false

  tags = {
    Name = "${var.app_name}-alb"
  }
}

# HTTPS listener with ACM certificate
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTP listener - redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

### Benefits
- **DDoS Protection**: CloudFront + WAF rate limiting
- **OWASP Top 10**: Automatic protection against common attacks
- **Geo-blocking**: Block traffic from high-risk countries
- **SSL/TLS Termination**: CloudFront handles certificate management
- **Global CDN**: Low latency worldwide

---

## Phase 10: B2B Partner Access with Cloudflare Tunnels

### Objective
Provide secure access for external vendors/partners without VPN or public IPs.

### Architecture
```
External Partner Network
    ↓
Cloudflare Tunnel (cloudflared)
    ↓ (Authenticated, encrypted tunnel)
Cloudflare Edge
    ↓
Private S3 bucket / API endpoint (no public access)
    ↓
Cloud WAN (b2b_partners segment)
    ↓
Partner-specific landing zone VPC
```

### Why Cloudflare Tunnels?

**Traditional VPN Problems**:
- Requires public IPs
- Complex firewall rules
- Client software installation
- High operational overhead
- No application-level access control

**Cloudflare Tunnel Benefits**:
- **Zero Trust**: No inbound firewall rules, no public IPs
- **Outbound Only**: Tunnel initiates connection from inside network
- **Application-Aware**: Can route specific apps, not entire network
- **Identity-Aware**: Integrates with Okta, Azure AD, Google Workspace
- **No Client Software**: Partners access via browser (Cloudflare Access)

### Implementation

#### 10.1: Cloudflare Tunnel in B2B Landing Zone VPC
```hcl
# modules/b2b-landing-zone/cloudflared-tunnel.tf

# EC2 instance running cloudflared
resource "aws_instance" "cloudflared" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.small"
  subnet_id     = aws_subnet.private[0].id

  vpc_security_group_ids = [aws_security_group.cloudflared.id]
  iam_instance_profile   = aws_iam_instance_profile.cloudflared.name

  user_data = <<-EOF
    #!/bin/bash
    # Install cloudflared
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.rpm
    yum install -y cloudflared-linux-amd64.rpm

    # Configure tunnel
    cat > /etc/cloudflared/config.yml <<-CONFIG
    tunnel: ${var.cloudflare_tunnel_id}
    credentials-file: /etc/cloudflared/credentials.json

    ingress:
      # Route to private S3 bucket
      - hostname: ${var.partner_name}-files.${var.domain}
        service: https://s3.${data.aws_region.current.name}.amazonaws.com/${aws_s3_bucket.partner_files.id}
        originRequest:
          noTLSVerify: false

      # Route to partner API
      - hostname: ${var.partner_name}-api.${var.domain}
        service: http://localhost:8080
        originRequest:
          connectTimeout: 30s

      # Route to partner database (read-only replica)
      - hostname: ${var.partner_name}-db.${var.domain}
        service: tcp://rds-endpoint.${data.aws_region.current.name}.rds.amazonaws.com:5432

      # Catch-all rule
      - service: http_status:404
    CONFIG

    # Store credentials from Secrets Manager
    aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.cloudflare_tunnel.id} \
      --query SecretString --output text > /etc/cloudflared/credentials.json

    # Start cloudflared service
    cloudflared service install
    systemctl enable cloudflared
    systemctl start cloudflared
  EOF

  tags = {
    Name    = "${var.partner_name}-cloudflared"
    Partner = var.partner_name
  }
}

# Security group - only outbound to Cloudflare
resource "aws_security_group" "cloudflared" {
  name        = "${var.partner_name}-cloudflared-sg"
  description = "Cloudflare Tunnel - outbound only"
  vpc_id      = aws_vpc.b2b_partner.id

  # No inbound rules - tunnel is outbound only!

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound to Cloudflare Edge"
  }

  egress {
    from_port   = 7844
    to_port     = 7844
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Cloudflare QUIC"
  }
}
```

#### 10.2: Private S3 Bucket for Partner File Exchange
```hcl
# modules/b2b-landing-zone/s3-partner-files.tf

# Private S3 bucket - NO public access
resource "aws_s3_bucket" "partner_files" {
  bucket = "${var.partner_name}-files-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "${var.partner_name}-files"
    Partner = var.partner_name
  }
}

# Block ALL public access
resource "aws_s3_bucket_public_access_block" "partner_files" {
  bucket = aws_s3_bucket.partner_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encryption at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "partner_files" {
  bucket = aws_s3_bucket.partner_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.partner_files.arn
    }
  }
}

# Versioning for audit trail
resource "aws_s3_bucket_versioning" "partner_files" {
  bucket = aws_s3_bucket.partner_files.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy - auto-delete old files
resource "aws_s3_bucket_lifecycle_configuration" "partner_files" {
  bucket = aws_s3_bucket.partner_files.id

  rule {
    id     = "delete-old-files"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# S3 bucket policy - only cloudflared instance can access
resource "aws_s3_bucket_policy" "partner_files" {
  bucket = aws_s3_bucket.partner_files.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudflaredInstanceOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.cloudflared.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.partner_files.arn,
          "${aws_s3_bucket.partner_files.arn}/*"
        ]
      }
    ]
  })
}
```

#### 10.3: Cloudflare Access (Identity-Aware Proxy)
```hcl
# Cloudflare Terraform provider
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Cloudflare Access Application
resource "cloudflare_access_application" "partner_s3" {
  zone_id = var.cloudflare_zone_id
  name    = "${var.partner_name} File Exchange"
  domain  = "${var.partner_name}-files.${var.domain}"

  type                  = "self_hosted"
  session_duration      = "12h"
  allowed_idps          = [cloudflare_access_identity_provider.okta.id]
  auto_redirect_to_identity = true
}

# Cloudflare Access Policy - Only specific partner users
resource "cloudflare_access_policy" "partner_users" {
  application_id = cloudflare_access_application.partner_s3.id
  zone_id        = var.cloudflare_zone_id
  name           = "Allow ${var.partner_name} users"
  precedence     = 1
  decision       = "allow"

  include {
    email_domain = [var.partner_email_domain]  # e.g., "partner.com"
  }

  require {
    email = var.partner_authorized_emails  # Specific users only
  }
}

# Cloudflare Access Identity Provider (Okta, Azure AD, Google)
resource "cloudflare_access_identity_provider" "okta" {
  zone_id = var.cloudflare_zone_id
  name    = "Okta SSO"
  type    = "okta"

  config {
    client_id     = var.okta_client_id
    client_secret = var.okta_client_secret
    okta_account  = var.okta_account_url
  }
}
```

### Partner Access Workflow

```
1. Partner employee opens browser: https://acme-files.yourcompany.com
   ↓
2. Cloudflare Access intercepts → SSO login (Okta/Azure AD)
   ↓
3. Cloudflare validates: Is user from acme.com? Is email authorized?
   ↓ (YES)
4. Cloudflare routes request through tunnel to private S3
   ↓
5. Partner uploads/downloads files (S3 browser interface)
   ↓
6. All actions logged (CloudTrail, S3 access logs, Cloudflare logs)
```

### Benefits
- **Zero Trust**: No VPN, no public IPs, identity-aware
- **No Firewall Rules**: Tunnel is outbound-only from AWS
- **SSO Integration**: Partners use existing corporate credentials
- **Audit Trail**: Complete logging of all access
- **Granular Access**: Can limit to specific files/folders per partner
- **Auto-Revoke**: Disable access instantly by removing from Cloudflare Access

---

## Phase 11: Per-Landing-Zone Custom DNS

### Objective
Each landing zone has its own custom Route 53 hosted zone and application-specific DNS records.

### Architecture
```
Landing Zone VPC: prod-app-1 (10.0.0.0/16)
    ↓
Route 53 Private Hosted Zone: app1.internal.company.com
    ↓ DNS Records:
        - app1.internal.company.com → ALB
        - api.app1.internal.company.com → API endpoint
        - db.app1.internal.company.com → RDS endpoint
        - cache.app1.internal.company.com → ElastiCache endpoint

Landing Zone VPC: prod-app-2 (10.1.0.0/16)
    ↓
Route 53 Private Hosted Zone: app2.internal.company.com
    ↓ DNS Records:
        - app2.internal.company.com → ALB
        - api.app2.internal.company.com → API endpoint
        [...]
```

### Implementation

#### 11.1: Per-Landing-Zone Route 53 Hosted Zone
```hcl
# modules/landing-zone-vpc/dns.tf

# Private hosted zone for this landing zone
resource "aws_route53_zone" "private" {
  name = "${var.app_name}.internal.${var.company_domain}"

  vpc {
    vpc_id = aws_vpc.landing_zone.id
  }

  tags = {
    Name        = "${var.app_name}-private-zone"
    Environment = var.environment
  }
}

# Application Load Balancer DNS record
resource "aws_route53_record" "alb" {
  zone_id = aws_route53_zone.private.zone_id
  name    = var.app_name
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}

# API endpoint
resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "api.${var.app_name}"
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}

# RDS database endpoint
resource "aws_route53_record" "database" {
  count = var.create_rds ? 1 : 0

  zone_id = aws_route53_zone.private.zone_id
  name    = "db.${var.app_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.main[0].endpoint]
}

# ElastiCache endpoint
resource "aws_route53_record" "cache" {
  count = var.create_elasticache ? 1 : 0

  zone_id = aws_route53_zone.private.zone_id
  name    = "cache.${var.app_name}"
  type    = "CNAME"
  ttl     = 300
  records = [aws_elasticache_cluster.main[0].cache_nodes[0].address]
}

# Wildcard for microservices
resource "aws_route53_record" "wildcard" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "*.${var.app_name}"
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
```

#### 11.2: Cross-VPC DNS Resolution (Route 53 Resolver)
```hcl
# modules/shared-services/route53-resolver.tf

# Inbound resolver endpoint (other VPCs query this)
resource "aws_route53_resolver_endpoint" "inbound" {
  name      = "shared-services-inbound"
  direction = "INBOUND"

  security_group_ids = [aws_security_group.resolver.id]

  # Deploy in shared services VPC
  dynamic "ip_address" {
    for_each = aws_subnet.private[*].id
    content {
      subnet_id = ip_address.value
    }
  }

  tags = {
    Name = "shared-services-resolver-inbound"
  }
}

# Outbound resolver endpoint (for forwarding to on-prem DNS)
resource "aws_route53_resolver_endpoint" "outbound" {
  name      = "shared-services-outbound"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.resolver.id]

  dynamic "ip_address" {
    for_each = aws_subnet.private[*].id
    content {
      subnet_id = ip_address.value
    }
  }

  tags = {
    Name = "shared-services-resolver-outbound"
  }
}

# Forwarding rule for on-premises DNS
resource "aws_route53_resolver_rule" "onprem" {
  domain_name          = "onprem.company.com"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound.id

  target_ip {
    ip   = "10.200.1.10"  # On-prem DNS server 1
    port = 53
  }

  target_ip {
    ip   = "10.200.1.11"  # On-prem DNS server 2
    port = 53
  }

  tags = {
    Name = "onprem-dns-forward"
  }
}

# Share resolver rules via RAM
resource "aws_ram_resource_share" "resolver_rules" {
  name                      = "resolver-rules-share"
  allow_external_principals = false

  tags = {
    Name = "resolver-rules-share"
  }
}

resource "aws_ram_resource_association" "resolver_rule" {
  resource_arn       = aws_route53_resolver_rule.onprem.arn
  resource_share_arn = aws_ram_resource_share.resolver_rules.arn
}

resource "aws_ram_principal_association" "organization" {
  principal          = var.organization_arn
  resource_share_arn = aws_ram_resource_share.resolver_rules.arn
}
```

#### 11.3: DNS Query Flow
```
App in prod-app-1 VPC queries: db.app1.internal.company.com
    ↓
VPC DNS resolver (.2 address) checks Route 53 private hosted zone
    ↓
Returns: RDS endpoint IP
    ↓
App connects to database

App in prod-app-1 VPC queries: service.onprem.company.com
    ↓
VPC DNS resolver forwards to Route 53 Resolver (shared services)
    ↓
Route 53 Resolver forwards to on-prem DNS (via forwarding rule)
    ↓
Returns: On-prem IP
    ↓
App connects via Cloud WAN → Direct Connect/VPN
```

### Benefits
- **Namespace Isolation**: Each app has its own DNS namespace
- **Simple DNS Names**: `db.app1.internal.company.com` instead of long RDS endpoints
- **Hybrid DNS**: Seamless resolution of on-prem resources
- **Service Discovery**: Microservices can discover each other via DNS
- **Automatic Updates**: DNS records update when resources change

---

## Summary Table

| Phase | Feature | Key Benefit | Complexity |
|-------|---------|-------------|------------|
| **Phase 8** | Microsegmentation | Reduce blast radius, compliance isolation | Medium |
| **Phase 9** | Ingress Filtering (WAF) | OWASP Top 10 protection, DDoS mitigation | Low |
| **Phase 10** | B2B Cloudflare Tunnels | Zero trust partner access, no VPN | Medium |
| **Phase 11** | Per-Landing-Zone DNS | Simple DNS names, service discovery | Low |

---

## Recommended Implementation Order

1. **Phase 11 (DNS)** - Foundation for all apps, low complexity
2. **Phase 9 (WAF)** - Immediate security benefit, low complexity
3. **Phase 8 (Microsegmentation)** - Requires DNS, improves security posture
4. **Phase 10 (B2B Tunnels)** - Requires DNS and microsegmentation

---

## Cost Estimates

### Phase 8: Microsegmentation
- Cloud WAN segments: $0 (included in Core Network)
- Network Firewall rules: $0 (included in existing firewall)
- **Total**: $0/month

### Phase 9: Ingress Filtering
- CloudFront: $0.085/GB + $0.01/10k requests = ~$50-200/month per app
- AWS WAF: $5/month + $1/rule = ~$20/month
- **Total**: ~$70-220/month per app

### Phase 10: B2B Cloudflare Tunnels
- Cloudflare Zero Trust: $7/user/month
- EC2 (t3.small): $15/month
- Cloudflare Access: $3/user/month
- **Total**: ~$25-50/month per partner

### Phase 11: Per-Landing-Zone DNS
- Route 53 hosted zone: $0.50/month
- Route 53 queries: $0.40/million queries = ~$1/month
- Route 53 Resolver endpoints: $0.125/hour × 2 = $180/month (shared)
- **Total**: ~$1.50/month per landing zone + $180/month (shared)

---

## Questions to Consider

1. **Microsegmentation**: How many segments do you need? (prod-pci, prod-general, etc.)
2. **WAF**: Do you need geo-blocking? Rate limiting threshold?
3. **B2B Partners**: How many partners? What data do they need?
4. **DNS**: Internal domain name? (e.g., internal.company.com)

Let me know which phase you'd like to tackle first, and I'll create the implementation modules!
