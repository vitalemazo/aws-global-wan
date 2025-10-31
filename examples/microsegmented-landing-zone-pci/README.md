<!--
Copyright (c) 2025 Vitale Mazo
All rights reserved.

This architecture and documentation is proprietary and confidential.
Unauthorized copying, modification, distribution, or use of this
architecture, documentation, or associated code is strictly prohibited.

Design by: Vitale Mazo
Year: 2025
-->


# PCI-Compliant Landing Zone with Microsegmentation

This example demonstrates how to deploy a **PCI-DSS compliant** application using the microsegmentation architecture.

## Architecture

```
Internet
   ↓
CloudFront (CDN)
   ↓
ALB (Public Subnets)
   ↓
Web Tier (Private Subnets)
   ↓
API Tier (Private Subnets)
   ↓
Database Tier (Isolated Subnets - NO EGRESS)
```

## PCI Compliance Features

### Network Isolation
- ✅ **Microsegmentation**: Dedicated `prod-pci` segment in Cloud WAN
- ✅ **Security Groups**: 3-tier architecture with strict ingress/egress rules
- ✅ **Database Isolation**: Database has ZERO egress rules (cannot initiate outbound connections)
- ✅ **Network Firewall**: PCI-specific firewall rules with alert on unexpected traffic

### Monitoring & Logging
- ✅ **VPC Flow Logs**: All traffic logged to CloudWatch (90-day retention)
- ✅ **GuardDuty**: Threat detection with malware protection enabled
- ✅ **CloudWatch Logs**: Centralized logging for all components

### Access Control
- ✅ **Bastion Host**: SSH access only from corporate VPN
- ✅ **CloudFront Only**: ALB not directly accessible from internet
- ✅ **No Internet Access**: Web and API tiers have NO internet egress

### Inspection & Filtering
- ✅ **Centralized Inspection**: Traffic routed through dedicated PCI inspection VPC
- ✅ **Whitelist-Only Egress**: PCI segment can only reach pre-approved destinations
- ✅ **Threat Intelligence**: Global blocklist applied to all traffic

## Deployment

### Prerequisites

1. **Central Networking** already deployed:
   - AWS Cloud WAN Core Network with microsegmentation policy
   - IPAM pool for PCI segment (10.100.0.0/16)
   - Inspection VPC with Network Firewall
   - RAM sharing enabled

2. **Terraform** >= 1.5.0

3. **AWS Credentials** with permissions to create:
   - VPCs, subnets, security groups
   - Cloud WAN attachments
   - GuardDuty detectors
   - CloudWatch log groups

### Steps

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Set variables**:
   ```bash
   export TF_VAR_global_network_id="core-network-xxxxxxxxx"
   export TF_VAR_app_name="payment-processor"
   export TF_VAR_corporate_vpn_cidr="203.0.113.0/24"
   ```

3. **Plan deployment**:
   ```bash
   terraform plan
   ```

4. **Deploy**:
   ```bash
   terraform apply
   ```

## What Gets Created

### VPC & Networking
- **1 VPC** with IPAM-allocated CIDR from PCI pool (10.100.x.0/24)
- **8 Subnets** across 2 AZs:
  - 2 ALB subnets (public)
  - 2 Web tier subnets (private)
  - 2 API tier subnets (private)
  - 2 Database subnets (isolated)
- **1 Cloud WAN Attachment** to `prod-pci` segment

### Security
- **6 Security Groups**:
  - ALB security group (HTTPS from CloudFront)
  - Web tier security group (accepts from ALB, talks to API only)
  - API tier security group (accepts from Web, talks to Database only)
  - Database security group (accepts from API, **NO EGRESS**)
  - Cache security group (optional)
  - Bastion security group (SSH from corporate VPN)

### Compliance
- **VPC Flow Logs** (90-day retention)
- **GuardDuty** with malware protection
- **CloudWatch Log Groups**

## Traffic Flow

### Inbound (User Request)
```
Internet User
  → CloudFront (CDN)
    → ALB (TLS termination)
      → Web Tier (port 8080)
        → API Tier (port 8443)
          → Database (port 5432)
```

### Outbound (BLOCKED for PCI Compliance)
```
Database → ✗ BLOCKED (no egress rules)
API Tier → ✗ BLOCKED (no internet access)
Web Tier → ✗ BLOCKED (no internet access)
```

### Allowed Outbound (Shared Services Only)
```
Web/API Tier → DNS (port 53 UDP) → VPC CIDR only
Web/API Tier → Shared Monitoring (port 443) → Via Cloud WAN
```

## Security Group Rules Summary

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| CloudFront | ALB | 443 | TCP | HTTPS traffic |
| CloudFront | ALB | 80 | TCP | HTTP redirect |
| ALB | Web Tier | 8080 | TCP | Forward to web servers |
| Web Tier | API Tier | 8443 | TCP | API calls |
| API Tier | Database | 5432 | TCP | Database queries |
| Corporate VPN | Bastion | 22 | TCP | Emergency SSH access |
| Bastion | Database | 22 | TCP | Troubleshooting only |

## Network Firewall Rules Applied

The following Network Firewall rule groups are applied to traffic entering/leaving the PCI segment:

1. **PCI Egress Whitelist** (priority: highest)
   - ALERT on any unexpected egress traffic
   - PASS only to whitelisted destinations (shared services)

2. **Database Deny All** (priority: high)
   - DROP all egress from database subnet (10.100.x.192/26)

3. **Threat Intelligence** (priority: medium)
   - DENY known malicious domains/IPs

4. **DDoS Protection** (priority: low)
   - DROP connections exceeding rate limits (100/minute per source)

## Cost Estimate

| Service | Monthly Cost |
|---------|--------------|
| VPC (no charge) | $0 |
| Cloud WAN Attachment | $255 |
| GuardDuty | ~$5 |
| VPC Flow Logs (CloudWatch) | ~$10 |
| Network Firewall (shared) | $0 (allocated to inspection VPC) |
| **Total** | **~$270/month** |

## Troubleshooting

### Database cannot connect to internet (by design)
**Symptom**: Database instances cannot reach external services.
**Cause**: PCI compliance requires database isolation.
**Solution**: Use VPC endpoints for AWS services, or proxy through API tier.

### ALB health checks failing
**Symptom**: ALB reports unhealthy targets.
**Cause**: Security group blocking ALB → Web tier traffic.
**Solution**: Verify security group allows ALB SG → Web tier port 8080.

### Cannot SSH to database
**Symptom**: SSH connection times out.
**Cause**: Database in isolated subnet with no ingress.
**Solution**: Use bastion host (already configured with SSH access).

## Production Checklist

Before deploying to production:

- [ ] Replace CloudFront CIDR `0.0.0.0/0` with CloudFront managed prefix list
- [ ] Configure GuardDuty findings to go to Security Hub
- [ ] Set up CloudWatch alarms for flow log anomalies
- [ ] Enable AWS Config for compliance tracking
- [ ] Test bastion access from corporate VPN
- [ ] Verify database has no egress (run `curl` test from DB instance)
- [ ] Review Network Firewall logs for ALERT rules
- [ ] Configure backup retention for RDS (PCI requires 90 days)
- [ ] Enable encryption at rest for all storage (EBS, RDS, S3)
- [ ] Configure TLS 1.2+ only on ALB

## Related Documentation

- [CONTROL_TOWER_RAM_ARCHITECTURE.md](../../CONTROL_TOWER_RAM_ARCHITECTURE.md) - Control Tower integration
- [FUTURE_ROADMAP.md](../../FUTURE_ROADMAP.md) - Phase 8 microsegmentation details
- [modules/security-groups-3tier/](../../modules/security-groups-3tier/) - Security group module
- [modules/network-firewall-microsegments/](../../modules/network-firewall-microsegments/) - Firewall rules module
