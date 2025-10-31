<!--
Copyright (c) 2025 Vitale Mazo
All rights reserved.

This architecture and documentation is proprietary and confidential.
Unauthorized copying, modification, distribution, or use of this
architecture, documentation, or associated code is strictly prohibited.

Design by: Vitale Mazo
Year: 2025
-->


# B2B Integration Architecture

## Overview

B2B (Business-to-Business) integrations involve securely connecting external partners, vendors, and SaaS providers to your AWS infrastructure. This document outlines patterns for:

1. **Inbound B2B**: External partners/vendors accessing YOUR resources (S3, databases, APIs)
2. **Outbound B2B**: YOUR applications accessing external SaaS providers
3. **Hybrid B2B**: Bidirectional integration (e.g., Salesforce, Snowflake)

## Architecture Patterns

### Pattern 1: Partner API Access (Current Implementation)

**Use Case**: External partners need to call your APIs

```
Partner Network
  ↓ (Direct Connect or VPN)
b2b-partners segment
  ↓ (Cloud WAN)
prod-api segment (port 443 only)
```

**Security**:
- ✅ Partners can ONLY reach API tier
- ✅ Cannot reach databases, S3, or other production resources
- ✅ Firewall enforces HTTPS-only
- ✅ All traffic logged and audited

**Implementation**: Already implemented in Phase 8

---

### Pattern 2: Vendor S3 Access (Data Exchange)

**Use Case**: Vendors need to upload/download files to S3 buckets

```
Vendor Network
  ↓ (Direct Connect or VPN)
b2b-vendors segment
  ↓ (VPC Endpoint for S3)
S3 Bucket with bucket policy
  ├── Allowed: b2b-vendors VPC Endpoint only
  └── IAM: Vendor-specific IAM role with STS AssumeRole
```

**Security**:
- ✅ Vendor cannot access internet (only S3 via VPC endpoint)
- ✅ S3 bucket policy restricts to specific VPC endpoint
- ✅ IAM role with least privilege (e.g., only upload to `/vendor-uploads/`)
- ✅ Server-side encryption enforced (SSE-S3 or SSE-KMS)
- ✅ Versioning enabled for audit trail
- ✅ CloudTrail logs all S3 API calls

**Example**:

```hcl
# S3 bucket for vendor file exchange
resource "aws_s3_bucket" "vendor_exchange" {
  bucket = "vendor-exchange-${var.company_name}"
}

resource "aws_s3_bucket_policy" "vendor_exchange" {
  bucket = aws_s3_bucket.vendor_exchange.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowVendorVPCEndpointOnly"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/vendor-upload-role"
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.vendor_exchange.arn}",
          "${aws_s3_bucket.vendor_exchange.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = aws_vpc_endpoint.s3_vendor.id
          }
        }
      },
      {
        Sid    = "DenyUnencryptedUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.vendor_exchange.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}

# IAM role for vendor with STS AssumeRole
resource "aws_iam_role" "vendor_upload" {
  name = "vendor-upload-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.vendor_aws_account_id}:root"
      }
      Condition = {
        StringEquals = {
          "sts:ExternalId" = var.vendor_external_id
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "vendor_upload" {
  name = "vendor-s3-access"
  role = aws_iam_role.vendor_upload.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "${aws_s3_bucket.vendor_exchange.arn}/vendor-uploads/*",
        "${aws_s3_bucket.vendor_exchange.arn}"
      ]
    }]
  })
}
```

**Vendor Access Flow**:
1. Vendor assumes IAM role: `aws sts assume-role --role-arn arn:aws:iam::YOUR_ACCOUNT:role/vendor-upload-role --external-id SHARED_SECRET`
2. Vendor uploads file: `aws s3 cp file.csv s3://vendor-exchange-company/vendor-uploads/file.csv --sse AES256`
3. CloudTrail logs the action
4. S3 event triggers Lambda for processing

---

### Pattern 3: Vendor Database Access (Support/Troubleshooting)

**Use Case**: Vendor needs temporary read-only database access for support

```
Vendor Network
  ↓ (Direct Connect or VPN)
b2b-vendors segment
  ↓ (Security Group + Network Firewall)
RDS Proxy (with IAM authentication)
  ↓
RDS Database (read replica for vendors)
```

**Security**:
- ✅ Vendor connects to RDS Proxy (not direct database)
- ✅ IAM-based authentication (no passwords)
- ✅ Time-limited access via STS temporary credentials
- ✅ Read replica (vendors CANNOT modify production data)
- ✅ Query logging enabled for audit
- ✅ Security group allows ONLY vendor segment
- ✅ Network Firewall logs all database connections

**Implementation**:

```hcl
# RDS Proxy for vendor access
resource "aws_db_proxy" "vendor_access" {
  name                   = "vendor-db-proxy"
  engine_family          = "POSTGRESQL"
  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "REQUIRED"
    secret_arn  = aws_secretsmanager_secret.vendor_db_credentials.arn
  }
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = aws_subnet.b2b_vendors[*].id
  require_tls            = true

  tags = {
    Name    = "vendor-db-proxy"
    Purpose = "Vendor support access"
  }
}

# IAM role for vendor database access (read-only)
resource "aws_iam_role" "vendor_db_access" {
  name = "vendor-db-readonly-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.vendor_aws_account_id}:root"
      }
      Condition = {
        StringEquals = {
          "sts:ExternalId" = var.vendor_external_id
        }
        DateGreaterThan = {
          "aws:CurrentTime" = var.vendor_access_start_time
        }
        DateLessThan = {
          "aws:CurrentTime" = var.vendor_access_end_time
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "vendor_db_access" {
  name = "vendor-rds-proxy-connect"
  role = aws_iam_role.vendor_db_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "rds-db:connect"
      ]
      Resource = "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_proxy.vendor_access.id}/vendor_readonly"
    }]
  })
}

# Database user for vendor (read-only)
# Execute via Lambda or Terraform null_resource:
# CREATE USER vendor_readonly WITH LOGIN;
# GRANT CONNECT ON DATABASE production TO vendor_readonly;
# GRANT SELECT ON ALL TABLES IN SCHEMA public TO vendor_readonly;
# ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO vendor_readonly;
```

**Vendor Access Flow**:
1. Vendor assumes IAM role: `aws sts assume-role --role-arn arn:aws:iam::YOUR_ACCOUNT:role/vendor-db-readonly-role --external-id SHARED_SECRET`
2. Vendor generates database token: `aws rds generate-db-auth-token --hostname vendor-db-proxy.proxy-xxxxx.us-east-1.rds.amazonaws.com --port 5432 --username vendor_readonly`
3. Vendor connects: `psql -h vendor-db-proxy.proxy-xxxxx.us-east-1.rds.amazonaws.com -U vendor_readonly -d production`
4. All queries logged to CloudWatch

**Time-Limited Access**:
- Access expires after 4 hours (STS session duration)
- IAM role condition enforces specific time window
- After window expires, vendor must request new access

---

### Pattern 4: Outbound SaaS Integration (Your Apps → External)

**Use Case**: Your applications need to access external SaaS providers (Salesforce, Snowflake, Stripe, Twilio)

#### Option A: Via NAT Gateway (Simple)

```
Your Application (prod-api segment)
  ↓
NAT Gateway
  ↓
Internet
  ↓
SaaS Provider (e.g., Salesforce, Stripe)
```

**Security**:
- ✅ Network Firewall domain allowlist (only approved SaaS providers)
- ✅ HTTPS-only (TLS 1.2+)
- ✅ API keys stored in Secrets Manager
- ✅ VPC Flow Logs for audit

**Implementation**: Already supported in Phase 8 via `api_tier_needs_internet = true`

#### Option B: Via AWS PrivateLink (Preferred for Large SaaS Providers)

```
Your Application (prod-api segment)
  ↓
VPC Endpoint (PrivateLink)
  ↓
AWS PrivateLink
  ↓
SaaS Provider VPC Endpoint Service
```

**Supported SaaS Providers with PrivateLink**:
- Salesforce
- Snowflake
- MongoDB Atlas
- DataDog
- Confluent Cloud
- Many others

**Benefits**:
- ✅ No internet egress (traffic stays on AWS backbone)
- ✅ No NAT Gateway costs
- ✅ Lower latency
- ✅ More secure (no public IP exposure)

**Example: Salesforce PrivateLink**:

```hcl
# VPC Endpoint for Salesforce
resource "aws_vpc_endpoint" "salesforce" {
  vpc_id              = aws_vpc.app.id
  service_name        = "com.amazonaws.vpce.us-east-1.vpce-svc-xxxxx" # Salesforce provides this
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.salesforce_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name    = "salesforce-privatelink"
    Purpose = "Salesforce API access"
  }
}

# Security group for Salesforce endpoint
resource "aws_security_group" "salesforce_endpoint" {
  name        = "salesforce-privatelink-sg"
  description = "Allow HTTPS to Salesforce PrivateLink"
  vpc_id      = aws_vpc.app.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.app.cidr_block]
    description = "HTTPS from VPC"
  }
}
```

**Application Configuration**:
```python
# Instead of public Salesforce endpoint:
# SALESFORCE_URL = "https://login.salesforce.com"

# Use PrivateLink endpoint:
SALESFORCE_URL = "https://vpce-xxxxx-yyyyy.execute-api.us-east-1.vpce.amazonaws.com"
```

#### Option C: Via Cloudflare Tunnels (Zero Trust, No Inbound Firewall Rules)

**Use Case**: Access SaaS providers or on-premises systems without opening inbound firewall rules

```
Your Application (prod-api segment)
  ↓
Cloudflare Tunnel (cloudflared daemon in VPC)
  ↓
Cloudflare Network
  ↓
SaaS Provider or On-Premises System
```

**Benefits**:
- ✅ No inbound firewall rules needed
- ✅ Zero Trust authentication (Cloudflare Access)
- ✅ Works with on-premises systems without VPN
- ✅ Built-in DDoS protection
- ✅ Audit logs in Cloudflare dashboard

**Implementation** (detailed in Phase 10 roadmap):

```hcl
# Cloudflare Tunnel for outbound SaaS access
resource "cloudflare_tunnel" "saas_connector" {
  account_id = var.cloudflare_account_id
  name       = "aws-saas-connector"
  secret     = random_password.tunnel_secret.result
}

# ECS task running cloudflared
resource "aws_ecs_task_definition" "cloudflared" {
  family                   = "cloudflared"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "cloudflared"
    image = "cloudflare/cloudflared:latest"
    command = [
      "tunnel",
      "--no-autoupdate",
      "run",
      "--token", var.cloudflare_tunnel_token
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/cloudflared"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "cloudflared"
      }
    }
  }])
}

# Route traffic to SaaS provider via Cloudflare
resource "cloudflare_tunnel_config" "saas_routes" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_tunnel.saas_connector.id

  config {
    ingress_rule {
      hostname = "salesforce.internal.company.com"
      service  = "https://login.salesforce.com"
    }
    ingress_rule {
      hostname = "snowflake.internal.company.com"
      service  = "https://myaccount.snowflakecomputing.com"
    }
    # Catch-all rule (required)
    ingress_rule {
      service = "http_status:404"
    }
  }
}
```

**Application Access**:
```python
# Application uses internal DNS name (Cloudflare Tunnel handles routing)
SALESFORCE_URL = "https://salesforce.internal.company.com"
SNOWFLAKE_URL = "https://snowflake.internal.company.com"
```

---

### Pattern 5: Hybrid B2B (Bidirectional with SaaS)

**Use Case**: Salesforce needs to call YOUR webhook, and YOU need to query Salesforce

```
┌─────────────────────────────────────────────┐
│ Salesforce                                  │
│   ↓ (webhook callback)                      │
│ API Gateway (public endpoint)               │
│   ↓                                          │
│ Lambda (validates Salesforce signature)     │
│   ↓                                          │
│ SQS Queue                                    │
│   ↓                                          │
│ prod-api segment (processes webhook)        │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ prod-api segment                            │
│   ↓ (API calls)                             │
│ VPC Endpoint (Salesforce PrivateLink)       │
│   ↓                                          │
│ Salesforce                                  │
└─────────────────────────────────────────────┘
```

**Security**:
- ✅ Inbound: API Gateway validates Salesforce signature, drops invalid requests
- ✅ Inbound: Lambda decouples webhook from application (SQS buffer)
- ✅ Outbound: PrivateLink (no internet egress)
- ✅ Secrets: Salesforce credentials in Secrets Manager with rotation

---

## Implementation Roadmap

### Phase 8.5: B2B S3 Access (NEW - Implement This First)

**Goal**: Allow vendors to securely upload/download files to S3

**Modules to Create**:
1. `modules/b2b-s3-exchange/` - S3 bucket with vendor access controls
2. `modules/b2b-iam-roles/` - IAM roles for vendor STS AssumeRole
3. `examples/b2b-vendor-s3-access/` - Complete example

**Timeline**: 1-2 days

### Phase 8.6: B2B Database Access (NEW - Implement Second)

**Goal**: Allow vendors read-only database access via RDS Proxy

**Modules to Create**:
1. `modules/b2b-rds-proxy/` - RDS Proxy with IAM authentication
2. `modules/b2b-database-user/` - Lambda to create read-only database user
3. `examples/b2b-vendor-db-access/` - Complete example with time-limited access

**Timeline**: 2-3 days

### Phase 10: Cloudflare Tunnels for SaaS (Already Planned)

**Goal**: Zero Trust access to SaaS providers without inbound firewall rules

**See**: [FUTURE_ROADMAP.md](./FUTURE_ROADMAP.md#phase-10-b2b-partner-access)

---

## Security Best Practices

### 1. Always Use STS AssumeRole with ExternalId

**Bad** (vendor uses long-term IAM user):
```
Vendor AWS Account
  → IAM User (long-term access key)
    → Your S3 Bucket
```

**Good** (vendor uses STS temporary credentials):
```
Vendor AWS Account
  → STS AssumeRole (with ExternalId)
    → Temporary credentials (4 hour expiration)
      → Your S3 Bucket
```

### 2. Time-Limit Vendor Access

```hcl
# IAM role condition enforces time window
Condition = {
  DateGreaterThan = {
    "aws:CurrentTime" = "2025-01-15T09:00:00Z"
  }
  DateLessThan = {
    "aws:CurrentTime" = "2025-01-15T17:00:00Z"
  }
}
```

### 3. Use Read Replicas for Vendor Database Access

**Never give vendors access to production database**. Always use a read replica:

```hcl
resource "aws_db_instance" "vendor_replica" {
  replicate_source_db = aws_db_instance.production.identifier
  instance_class      = "db.t3.small"  # Smaller instance for vendors
  publicly_accessible = false

  tags = {
    Name    = "vendor-read-replica"
    Purpose = "Vendor support access only"
  }
}
```

### 4. Encrypt Everything

- S3: Server-side encryption (SSE-S3 or SSE-KMS)
- Database: TLS required for all connections
- Secrets: AWS Secrets Manager with automatic rotation
- Network: All traffic over VPN or Direct Connect (no public internet)

### 5. Audit Everything

Enable logging at every layer:

| Layer | Logging Service | What It Captures |
|-------|----------------|------------------|
| Network | VPC Flow Logs | All IP traffic in b2b segments |
| Firewall | Network Firewall | Allowed/denied connections |
| API | CloudTrail | All AWS API calls (AssumeRole, S3, RDS) |
| S3 | S3 Server Access Logs | All bucket operations |
| Database | RDS Query Logs | All SQL queries from vendors |
| Application | CloudWatch Logs | Application-level access logs |

### 6. Regular Access Reviews

**Monthly**:
- Review all active vendor IAM roles
- Disable unused roles
- Rotate ExternalId values

**Quarterly**:
- Audit S3 bucket policies
- Review database user permissions
- Test RDS Proxy failover

**Annually**:
- Penetration testing of B2B integrations
- Compliance audit (SOC 2, ISO 27001)

---

## Cost Breakdown

### Pattern 2: Vendor S3 Access
| Component | Monthly Cost |
|-----------|--------------|
| S3 Storage (100 GB) | $2.30 |
| S3 Requests (1M PUT) | $5.00 |
| VPC Endpoint for S3 | $7.00 |
| CloudTrail logging | $2.00 |
| **Total** | **~$16/month** |

### Pattern 3: Vendor Database Access
| Component | Monthly Cost |
|-----------|--------------|
| RDS Proxy | $15.00 |
| Read Replica (db.t3.small) | $25.00 |
| Secrets Manager | $0.40 |
| **Total** | **~$40/month** |

### Pattern 4B: SaaS via PrivateLink
| Component | Monthly Cost |
|-----------|--------------|
| VPC Endpoint (Interface) | $7.00 |
| Data Transfer (100 GB) | $0.90 |
| **Total** | **~$8/month** |

Compare to NAT Gateway: $32 + $0.45/GB = **$77/month** for same 100 GB

### Pattern 4C: Cloudflare Tunnels
| Component | Monthly Cost |
|-----------|--------------|
| Cloudflare Zero Trust (5 users) | $7.00/user = $35 |
| ECS Fargate (cloudflared) | $5.00 |
| **Total** | **~$40/month** |

---

## Next Steps

Would you like me to implement:

1. **Phase 8.5: B2B S3 Exchange Module** - For vendor file uploads/downloads
2. **Phase 8.6: B2B Database Access Module** - For vendor read-only database access
3. **Update existing examples** - Add S3 and database access to PCI/general landing zones
4. **Cloudflare Tunnel PoC** - Proof of concept for SaaS integration

Let me know which pattern(s) you'd like me to build out!
