<!--
Copyright (c) 2025 Vitale Mazo
All rights reserved.

This architecture and documentation is proprietary and confidential.
Unauthorized copying, modification, distribution, or use of this
architecture, documentation, or associated code is strictly prohibited.

Design by: Vitale Mazo
Year: 2025
-->


# General Production Landing Zone with Microsegmentation

This example demonstrates a **standard production application** using the microsegmentation architecture with moderate isolation.

## Architecture

```
Internet
   ↓
ALB (Public Subnets)
   ↓
Web Tier (Private Subnets) ← Can access AWS services (S3, DynamoDB)
   ↓
API Tier (Private Subnets) ← Can access external APIs (Stripe, Twilio)
   ↓
Database Tier (Isolated Subnets - NO INTERNET)
```

## Key Differences from PCI Example

| Feature | PCI Landing Zone | General Landing Zone |
|---------|------------------|----------------------|
| **Segment** | `prod-pci` | `prod-general` |
| **ALB Access** | CloudFront only | Public internet |
| **Web Tier Internet** | ❌ Blocked | ✅ Can access AWS services |
| **API Tier Internet** | ❌ Blocked | ✅ Can access external APIs |
| **Database Isolation** | ✅ Complete | ✅ Complete |
| **Network Firewall** | Whitelist-only | Blocklist (malware/phishing) |
| **Flow Log Retention** | 90 days | 30 days |
| **GuardDuty** | ✅ Required | ⚠️ Optional (recommended) |

## What Gets Created

### VPC & Networking
- **1 VPC** with IPAM-allocated CIDR from prod-general pool
- **6 Subnets** across 2 AZs:
  - 2 Public subnets (ALB)
  - 2 Private subnets (Web + API tiers)
  - 2 Database subnets (isolated)
- **1 Internet Gateway** for ALB
- **3 Route Tables**:
  - Public RT: Routes to IGW for internet access
  - Private RT: Routes to Cloud WAN for cross-segment communication
  - Database RT: Local VPC routes only (NO internet, NO Cloud WAN)
- **1 Cloud WAN Attachment** to `prod-general` segment

### Security
- **5-6 Security Groups**:
  - ALB security group (HTTPS from internet)
  - Web tier security group (accepts from ALB, talks to API)
  - API tier security group (accepts from Web, talks to Database)
  - Database security group (accepts from API, **NO EGRESS**)
  - Cache security group (optional, if enabled)

### Monitoring
- **VPC Flow Logs** (30-day retention)
- **CloudWatch Log Groups**

## Traffic Flow

### Inbound (User Request)
```
Internet User
  → ALB (TLS termination)
    → Web Tier (port 3000) - React/Node.js frontend
      → API Tier (port 8080) - REST API
        → Database (port 5432) - PostgreSQL
```

### Outbound (Web Tier)
```
Web Tier → AWS Services (S3, DynamoDB) → Via VPC Endpoints or NAT
Web Tier → Other Segments → Via Cloud WAN
```

### Outbound (API Tier)
```
API Tier → External APIs (Stripe, Twilio, etc.) → Via NAT Gateway or Inspection VPC
API Tier → Shared Services (DNS, monitoring) → Via Cloud WAN
```

### Outbound (Database - BLOCKED)
```
Database → ✗ BLOCKED (no egress rules, no internet route)
```

## Deployment

### Prerequisites

1. **Central Networking** already deployed:
   - AWS Cloud WAN Core Network with microsegmentation policy
   - IPAM pool for prod-general segment
   - Inspection VPC with Network Firewall (optional)
   - RAM sharing enabled

2. **Terraform** >= 1.5.0

3. **AWS Credentials**

### Steps

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Set variables**:
   ```bash
   export TF_VAR_global_network_id="core-network-xxxxxxxxx"
   export TF_VAR_app_name="web-app"
   export TF_VAR_enable_cache="true"  # Optional: enable Redis
   ```

3. **Deploy**:
   ```bash
   terraform apply
   ```

## Security Group Rules Summary

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Internet | ALB | 443 | TCP | HTTPS traffic |
| Internet | ALB | 80 | TCP | HTTP redirect |
| ALB | Web Tier | 3000 | TCP | Forward to frontend |
| Web Tier | API Tier | 8080 | TCP | API calls |
| API Tier | Database | 5432 | TCP | Database queries |
| Web Tier | VPC CIDR | 53 | UDP | DNS resolution |
| API Tier | VPC CIDR | 53 | UDP | DNS resolution |
| Web Tier | Internet | 443 | TCP | AWS services (S3, DynamoDB) |
| API Tier | Internet | 443 | TCP | External APIs (Stripe, Twilio) |

## Network Firewall Rules Applied

The following Network Firewall rule groups are applied to traffic from the prod-general segment:

1. **Database Deny All** (priority: highest)
   - DROP all egress from database subnet

2. **Threat Intelligence** (priority: high)
   - DENY known malicious domains/IPs

3. **Production Blocklist** (priority: medium)
   - DENY suspicious TLDs (.tk, .ml, .onion)
   - DENY torrent sites, malware domains

4. **DDoS Protection** (priority: low)
   - DROP connections exceeding rate limits

## Cost Estimate

| Service | Monthly Cost |
|---------|--------------|
| VPC (no charge) | $0 |
| Internet Gateway | $0 |
| NAT Gateway (if needed) | $32/month |
| Cloud WAN Attachment | $255 |
| VPC Flow Logs | ~$5 |
| Network Firewall (shared) | $0 (allocated to inspection VPC) |
| **Total** | **~$292/month** (without NAT) or **~$324/month** (with NAT) |

## Use Cases

This landing zone pattern is ideal for:

- ✅ **E-commerce applications** (need Stripe, PayPal integrations)
- ✅ **SaaS applications** (need SendGrid, Twilio, auth providers)
- ✅ **Content management systems** (need S3, CloudFront)
- ✅ **Web applications with microservices** (need service-to-service communication)

## NOT Suitable For

- ❌ **PCI-compliant workloads** (use [microsegmented-landing-zone-pci](../microsegmented-landing-zone-pci/) instead)
- ❌ **HIPAA-compliant workloads** (requires additional controls)
- ❌ **Air-gapped environments** (use dedicated segment with no internet)

## Troubleshooting

### Web tier cannot reach S3
**Symptom**: Web application cannot upload to S3.
**Cause**: No NAT Gateway configured, or VPC endpoints missing.
**Solution**: Add NAT Gateway or S3 VPC endpoint.

### API tier cannot reach external APIs
**Symptom**: Stripe/Twilio calls timeout.
**Cause**: No NAT Gateway, or Network Firewall blocking domain.
**Solution**: Add NAT Gateway and check Network Firewall logs for blocks.

### Database cannot reach internet (by design)
**Symptom**: Database cannot download patches.
**Cause**: Complete isolation for security.
**Solution**: Use AWS Systems Manager Session Manager or download patches via API tier proxy.

## Production Checklist

Before deploying to production:

- [ ] Configure NAT Gateway for internet access (or use Inspection VPC)
- [ ] Set up VPC endpoints for frequently-used AWS services (S3, DynamoDB, SQS)
- [ ] Enable GuardDuty for threat detection
- [ ] Configure CloudWatch alarms for ALB errors, API latency
- [ ] Set up Auto Scaling for Web and API tiers
- [ ] Configure RDS Multi-AZ for database high availability
- [ ] Enable RDS automated backups (30-day retention)
- [ ] Configure AWS WAF on ALB (rate limiting, SQL injection protection)
- [ ] Enable TLS 1.2+ only on ALB
- [ ] Set up Route 53 custom domain with health checks

## Related Documentation

- [CONTROL_TOWER_RAM_ARCHITECTURE.md](../../CONTROL_TOWER_RAM_ARCHITECTURE.md) - Control Tower integration
- [FUTURE_ROADMAP.md](../../FUTURE_ROADMAP.md) - Phase 8 microsegmentation details
- [modules/security-groups-3tier/](../../modules/security-groups-3tier/) - Security group module
- [examples/microsegmented-landing-zone-pci/](../microsegmented-landing-zone-pci/) - PCI-compliant version
