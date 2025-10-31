<!--
Copyright (c) 2025 Vitale Mazo
All rights reserved.

This architecture and documentation is proprietary and confidential.
Unauthorized copying, modification, distribution, or use of this
architecture, documentation, or associated code is strictly prohibited.

Design by: Vitale Mazo
Year: 2025
-->


# Phase 8: Microsegmentation Architecture

## Overview

Phase 8 implements **fine-grained microsegmentation** beyond the basic prod/non-prod/shared model. Instead of having 3 broad segments, we now have **12+ specialized segments** with explicit allow/deny rules between them.

## Why Microsegmentation?

### Traditional Segmentation Problems

**Old Model (Phases 1-7)**:
```
production    ← All production workloads (PCI + API + databases + general apps)
non-prod      ← Dev/test/staging all together
shared        ← DNS, monitoring, security tools
```

**Problems**:
- 🔴 PCI workloads can talk to general production apps (compliance violation)
- 🔴 Dev environments can accidentally reach test/staging data
- 🔴 API tier can reach database tier even when not needed
- 🔴 No separation between data plane and control plane

### Microsegmentation Benefits

**New Model (Phase 8)**:
```
prod-pci           ← PCI-compliant payment processing (isolated)
prod-general       ← Standard production apps
prod-api           ← API gateway layer
prod-data          ← Database tier (no internet)

nonprod-dev        ← Development
nonprod-test       ← Testing
nonprod-staging    ← Staging

shared-dns         ← Route 53 Resolver
shared-monitoring  ← CloudWatch, Prometheus
shared-security    ← GuardDuty, Security Hub
shared-cicd        ← Jenkins, GitLab

b2b-partners       ← External partner integrations
b2b-vendors        ← Vendor access (limited)
```

**Benefits**:
- ✅ PCI workloads completely isolated (can only talk to shared-dns + shared-monitoring)
- ✅ Databases in prod-data segment have ZERO egress (even within VPC)
- ✅ Dev/test/staging cannot accidentally reach production
- ✅ B2B partners can only reach specific API endpoints
- ✅ Explicit allow rules (deny by default)

## Architecture Layers

Microsegmentation is enforced at **3 layers**:

### Layer 1: Cloud WAN Segments (Routing Layer)

**Technology**: AWS Cloud WAN Core Network Policy

**How it works**:
- Each segment has its own routing domain
- Segment actions define which segments can communicate
- Isolation enforced at network layer (cannot route between segments unless explicitly allowed)

**Example**:
```json
{
  "segments": [
    {
      "name": "prod-pci",
      "isolate-attachments": true,
      "require-attachment-acceptance": true
    },
    {
      "name": "prod-data",
      "isolate-attachments": true
    }
  ],
  "segment-actions": [
    {
      "action": "send-to",
      "segment": "prod-pci",
      "via": {
        "network-function-groups": ["inspection-pci"]
      },
      "destination-cidr-blocks": ["10.255.1.0/24"]
    }
  ]
}
```

**What this does**:
- `prod-pci` segment can ONLY send traffic to `10.255.1.0/24` (shared-dns)
- All traffic from `prod-pci` goes through dedicated inspection firewall
- Any attempt to route to other segments = dropped at routing layer

### Layer 2: Security Groups (Instance Layer)

**Technology**: AWS VPC Security Groups

**How it works**:
- 3-tier architecture: ALB → Web → API → Database
- Each tier has strict ingress/egress rules
- Security groups reference each other (not IP ranges)

**Example**:
```hcl
# Database tier accepts ONLY from API tier
resource "aws_vpc_security_group_ingress_rule" "db_from_api" {
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.api[0].id
}

# Database tier has NO egress rules
# (no egress rules defined = no outbound connections allowed)
```

**What this does**:
- Even if routing layer allowed it, database instances cannot initiate connections
- API tier can only talk to database on port 5432 (no SSH, no other ports)
- Zero trust at instance level

### Layer 3: Network Firewall (Application Layer)

**Technology**: AWS Network Firewall

**How it works**:
- Stateful inspection at Layer 7 (HTTP/TLS)
- Segment-specific rule groups
- Domain allowlists/blocklists
- Threat intelligence feeds

**Example**:
```hcl
# PCI segment: ALERT on ANY unexpected egress
resource "aws_networkfirewall_rule_group" "pci_egress" {
  rule_group {
    rules_source {
      stateful_rule {
        action = "ALERT"
        header {
          source      = "10.100.0.0/16"  # PCI segment
          destination = "ANY"
        }
        rule_option {
          keyword  = "msg"
          settings = ["PCI segment unexpected traffic"]
        }
      }
    }
  }
}

# Database segment: DROP all egress attempts
resource "aws_networkfirewall_rule_group" "database_deny_all" {
  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          source      = "10.102.0.0/16"  # Database segment
          destination = "ANY"
        }
      }
    }
  }
}
```

**What this does**:
- PCI traffic is logged and alerted (compliance requirement)
- Database traffic is actively dropped (defense in depth)
- Can inspect TLS SNI, HTTP Host headers (e.g., block `.onion` domains)

## Segment Definitions

### Production Segments

#### prod-pci (10.100.0.0/16)
- **Purpose**: PCI-DSS compliant payment processing
- **Isolation**: Complete isolation with whitelist-only egress
- **Allowed segments**: `shared-dns`, `shared-monitoring`
- **Internet access**: Via dedicated PCI inspection firewall only
- **Firewall rules**: ALERT on unexpected traffic, whitelist-only destinations
- **Compliance**: PCI-DSS Level 1

#### prod-general (10.103.0.0/16)
- **Purpose**: Standard production applications
- **Isolation**: Moderate (can reach shared services)
- **Allowed segments**: `shared-dns`, `shared-monitoring`, `shared-security`, `prod-api`
- **Internet access**: Via inspection VPC or NAT Gateway
- **Firewall rules**: Blocklist (malware domains, suspicious TLDs)

#### prod-api (10.101.0.0/16)
- **Purpose**: API gateway layer, microservices
- **Isolation**: Can communicate with prod-general, b2b-partners
- **Allowed segments**: `shared-dns`, `shared-monitoring`, `prod-data`
- **Internet access**: Domain allowlist (Stripe, Twilio, SendGrid, etc.)
- **Firewall rules**: Domain allowlist for external APIs

#### prod-data (10.102.0.0/16)
- **Purpose**: Database tier (RDS, DocumentDB, ElastiCache)
- **Isolation**: NO internet, NO Cloud WAN (local VPC only)
- **Allowed segments**: None (accepts from prod-api only)
- **Internet access**: ❌ BLOCKED
- **Firewall rules**: DROP all egress attempts

### Non-Production Segments

#### nonprod-dev (10.10.0.0/16)
- **Purpose**: Development environment
- **Isolation**: Can reach shared services, cannot reach production
- **Allowed segments**: `shared-dns`, `shared-monitoring`, `shared-cicd`
- **Internet access**: Via NAT Gateway (permissive)
- **Firewall rules**: Block access to production CIDRs

#### nonprod-test (10.11.0.0/16)
- **Purpose**: Testing/QA environment
- **Isolation**: Can reach shared services, cannot reach production
- **Allowed segments**: `shared-dns`, `shared-monitoring`, `shared-cicd`
- **Internet access**: Via NAT Gateway
- **Firewall rules**: Block access to production CIDRs

#### nonprod-staging (10.12.0.0/16)
- **Purpose**: Pre-production staging
- **Isolation**: Can reach shared services, cannot reach production
- **Allowed segments**: `shared-dns`, `shared-monitoring`
- **Internet access**: Via NAT Gateway
- **Firewall rules**: Block access to production CIDRs

### Shared Services Segments

#### shared-dns (10.255.1.0/24)
- **Purpose**: Route 53 Resolver endpoints
- **Isolation**: Can be reached by ALL segments
- **Internet access**: No (DNS resolution only)

#### shared-monitoring (10.255.2.0/24)
- **Purpose**: CloudWatch, Prometheus, Grafana
- **Isolation**: Can be reached by ALL segments
- **Internet access**: Yes (for exporting metrics)

#### shared-security (10.255.3.0/24)
- **Purpose**: GuardDuty, Security Hub, Inspector
- **Isolation**: Can reach ALL segments (for scanning)
- **Internet access**: Yes (for threat intelligence updates)

#### shared-cicd (10.255.4.0/24)
- **Purpose**: Jenkins, GitLab, CodePipeline
- **Isolation**: Can reach dev/test/staging, cannot reach production
- **Internet access**: Yes (for pulling dependencies)

### B2B Partner Segments

#### b2b-partners (10.200.0.0/16)
- **Purpose**: External partner integrations (sFTP, API access)
- **Isolation**: Can ONLY reach prod-api on port 443
- **Allowed segments**: `prod-api`
- **Internet access**: No (partners connect via Direct Connect or VPN)
- **Firewall rules**: Allow HTTPS to prod-api only, DROP all else

#### b2b-vendors (10.201.0.0/16)
- **Purpose**: Vendor access for support/troubleshooting
- **Isolation**: Can reach specific resources with time-limited access
- **Allowed segments**: Configured per vendor
- **Internet access**: No
- **Firewall rules**: Time-based rules, logged and audited

## Segment Communication Matrix

| From ↓ / To → | prod-pci | prod-general | prod-api | prod-data | nonprod-* | shared-* | b2b-* |
|---------------|----------|--------------|----------|-----------|-----------|----------|-------|
| **prod-pci**      | ✓ | ❌ | ❌ | ❌ | ❌ | dns, mon | ❌ |
| **prod-general**  | ❌ | ✓ | ✓ | ❌ | ❌ | dns, mon, sec | ❌ |
| **prod-api**      | ❌ | ✓ | ✓ | ✓ | ❌ | dns, mon | ✓ |
| **prod-data**     | ❌ | ❌ | ❌ | ✓ | ❌ | ❌ | ❌ |
| **nonprod-***     | ❌ | ❌ | ❌ | ❌ | ✓ | dns, mon, cicd | ❌ |
| **shared-***      | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **b2b-***         | ❌ | ❌ | ✓ | ❌ | ❌ | ❌ | ✓ |

Legend:
- ✓ = Allowed
- ❌ = Blocked
- dns, mon, sec, cicd = Specific shared services allowed

## Implementation

### Module Structure

```
modules/
├── core-network-microsegments/     ← Cloud WAN policy with microsegments
│   ├── main.tf                     ← Segment definitions, actions
│   ├── variables.tf                ← Segment configurations
│   └── outputs.tf                  ← Segment IDs, summary
│
├── security-groups-3tier/          ← Security group automation
│   ├── main.tf                     ← ALB → Web → API → DB SGs
│   ├── variables.tf                ← Port config, CIDR blocks
│   └── outputs.tf                  ← Security group IDs
│
└── network-firewall-microsegments/ ← Segment-specific firewall rules
    ├── main.tf                     ← Rule groups per segment
    ├── variables.tf                ← Domain lists, CIDRs
    └── outputs.tf                  ← Rule group IDs

examples/
├── microsegmented-landing-zone-pci/      ← PCI-compliant example
│   ├── main.tf                           ← Full 3-tier PCI app
│   ├── variables.tf
│   └── README.md                         ← PCI compliance checklist
│
└── microsegmented-landing-zone-general/  ← General production example
    ├── main.tf                           ← Standard web app
    ├── variables.tf
    └── README.md                         ← Deployment guide
```

### Usage Example: PCI Application

```hcl
# Use the core-network-microsegments module (central networking team)
module "core_network_microsegments" {
  source = "./modules/core-network-microsegments"

  global_network_name = "global-wan"
  edge_locations      = ["us-east-1", "us-west-2", "eu-west-1"]

  enable_pci_segment = true
  enable_b2b_segments = true
  enable_inspection_routing = true

  # PCI segment can only reach shared-dns and shared-monitoring
  production_microsegments = {
    pci = {
      description      = "PCI-compliant workloads"
      isolate          = true
      require_approval = true
      allowed_segments = ["shared-dns", "shared-monitoring"]
      no_internet      = false  # Via dedicated inspection firewall
    }
  }
}

# Deploy PCI application (application team)
module "pci_app" {
  source = "./examples/microsegmented-landing-zone-pci"

  app_name          = "payment-processor"
  global_network_id = module.core_network_microsegments.global_network_id

  # Security configuration
  cloudfront_cidr     = "0.0.0.0/0"  # Use CloudFront prefix list in prod
  corporate_vpn_cidr  = "203.0.113.0/24"
}
```

### Usage Example: General Production Application

```hcl
# Deploy general production app (application team)
module "web_app" {
  source = "./examples/microsegmented-landing-zone-general"

  app_name          = "web-app"
  global_network_id = module.core_network_microsegments.global_network_id
  enable_cache      = true  # Enable Redis
}
```

## Security Benefits

### 1. Defense in Depth

If one layer fails, others still protect:

**Scenario**: Attacker compromises web server in prod-general segment

- ❌ **Try to reach database**: Blocked by security group (web SG cannot reach DB SG)
- ❌ **Try to reach PCI segment**: Blocked by Cloud WAN routing (no route exists)
- ❌ **Try to exfiltrate to internet**: Blocked by Network Firewall (blocklist)
- ❌ **Try to lateral movement**: Blocked by security group (web SG cannot SSH to other instances)

### 2. Compliance Automation

**PCI-DSS Requirements**:
- ✅ Requirement 1.2.1: "Restrict inbound and outbound traffic to that which is necessary"
  - Implemented: Whitelist-only egress for PCI segment
- ✅ Requirement 1.3.1: "Implement a DMZ to limit inbound traffic"
  - Implemented: ALB in public subnet, application in private subnet
- ✅ Requirement 10.2: "Implement automated audit trails"
  - Implemented: VPC Flow Logs (90-day retention), Network Firewall logs

### 3. Blast Radius Reduction

If non-prod environment is compromised:
- ❌ Cannot reach production segments (Cloud WAN routing blocks it)
- ❌ Cannot reach PCI data (no route exists)
- ✅ Can only reach other non-prod environments and shared services

### 4. Simplified Compliance Audits

**Auditor question**: "Show me that PCI databases cannot access the internet"

**Answer with microsegmentation**:
1. **Cloud WAN Policy**: `prod-data` segment has no internet route
2. **Security Group**: Database SG has zero egress rules
3. **Network Firewall**: Database CIDR (10.102.0.0/16) has DROP all egress rule
4. **Route Table**: Database subnet route table has no IGW or NAT route

**4 layers of proof** = easy audit compliance.

## Migration Path

### From Phase 7 to Phase 8

**Phase 7 (Current)**:
```
production    ← All production
non-prod      ← All non-prod
shared        ← Shared services
```

**Phase 8 (Microsegmentation)**:
```
production    ← Kept for backward compatibility
  → prod-pci, prod-general, prod-api, prod-data  ← New segments

non-prod      ← Kept for backward compatibility
  → nonprod-dev, nonprod-test, nonprod-staging   ← New segments

shared        ← Kept for backward compatibility
  → shared-dns, shared-monitoring, etc.          ← New segments
```

**Migration Strategy**:

1. **Deploy Phase 8 modules** alongside existing infrastructure
2. **Create new microsegments** in Cloud WAN policy
3. **Deploy new applications** to microsegments (examples provided)
4. **Gradually migrate** existing applications from broad segments to microsegments
5. **Deprecate broad segments** once all workloads migrated

**Backward Compatibility**:
- Old `production` segment still exists
- Existing VPCs continue to work
- New VPCs can use new microsegments
- No disruption to existing workloads

## Cost Impact

### Additional Costs

| Component | Cost | Notes |
|-----------|------|-------|
| **Core Network** | $0 | Same Core Network, just different policy |
| **VPC Attachments** | $255/month each | Same as Phase 7 |
| **Network Firewall** | $0 | Shared across segments |
| **Security Groups** | $0 | No charge |
| **VPC Flow Logs** | ~$5-10/VPC/month | Increased due to more granular logging |

**Total additional cost**: ~$5-10/VPC/month for enhanced flow logging.

### Cost Savings

**Scenario**: 50 production VPCs

**Without microsegmentation**:
- Each VPC needs its own Network Firewall: 50 × $395 = **$19,750/month**

**With microsegmentation**:
- Centralized Network Firewall in inspection VPC: **$395/month**
- Cloud WAN segments route through shared firewall: **$0 additional**

**Savings**: $19,750 - $395 = **$19,355/month** (98% reduction)

## Monitoring & Troubleshooting

### CloudWatch Metrics

**Per-Segment Metrics**:
- `CoreNetwork.BytesSent` (dimension: Segment=prod-pci)
- `CoreNetwork.PacketsSent` (dimension: Segment=prod-pci)
- `NetworkFirewall.DroppedPackets` (dimension: RuleGroup=pci-egress)

**Example Alert**:
```hcl
resource "aws_cloudwatch_metric_alarm" "pci_unexpected_traffic" {
  alarm_name          = "pci-unexpected-traffic"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DroppedPackets"
  namespace           = "AWS/NetworkFirewall"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "PCI segment has unexpected traffic (should be whitelist-only)"

  dimensions = {
    RuleGroup = "pci-egress"
  }
}
```

### Flow Log Analysis

**Query**: Find database egress attempts (should be ZERO)

```sql
SELECT srcaddr, dstaddr, dstport, action
FROM vpc_flow_logs
WHERE srcaddr LIKE '10.102.%'  -- Database segment
  AND dstaddr NOT LIKE '10.102.%'  -- Egress attempts
  AND action = 'REJECT'
ORDER BY start DESC
LIMIT 100
```

**Expected result**: Empty (database has no egress rules, so no REJECT logs)

**If non-empty**: Security group misconfiguration or compromised instance.

### Network Firewall Logs

**Query**: Find PCI segment alerts

```sql
SELECT event_timestamp, src_ip, dest_ip, dest_port, alert.signature
FROM network_firewall_logs
WHERE alert.signature = 'PCI segment unexpected traffic'
ORDER BY event_timestamp DESC
LIMIT 100
```

**Expected result**: Empty (PCI traffic should match whitelist)

**If non-empty**: Application attempting to reach non-whitelisted destination.

## Best Practices

### 1. Start with Broad Segments, Refine Over Time

Don't try to implement all 12+ segments at once. Start with:

**Phase 8.1** (Week 1):
- `prod-general`
- `nonprod-general`
- `shared-dns`

**Phase 8.2** (Week 2):
- Split `prod-general` → `prod-api` + `prod-data`

**Phase 8.3** (Week 3):
- Add `prod-pci` for compliant workloads

**Phase 8.4** (Week 4):
- Add `b2b-partners` for external integrations

### 2. Use Tags for Segment Mapping

Tag VPCs with their intended segment:

```hcl
tags = {
  Name    = "payment-processor-vpc"
  Segment = "prod-pci"
  Tier    = "database"
}
```

Then use Cloud WAN attachment tag-based matching:

```json
{
  "attachment-policies": [
    {
      "rule-number": 100,
      "conditions": [
        {
          "type": "tag-value",
          "key": "Segment",
          "value": "prod-pci"
        }
      ],
      "action": {
        "association-method": "tag",
        "segment": "prod-pci"
      }
    }
  ]
}
```

### 3. Deny by Default, Explicit Allow

Never use `allow all` rules. Always specify exact:
- Source/destination CIDRs
- Ports
- Protocols

**Bad**:
```hcl
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

**Good**:
```hcl
egress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["10.255.1.0/24"]  # shared-dns only
  description = "HTTPS to shared DNS for resolver queries"
}
```

### 4. Test in Non-Prod First

Before deploying microsegmentation to production:

1. Deploy to `nonprod-dev` first
2. Verify connectivity to shared services (DNS, monitoring)
3. Verify isolation (cannot reach production)
4. Test application functionality end-to-end
5. Review flow logs for unexpected REJECT entries
6. Only then deploy to production

### 5. Monitor for 30 Days Before Enforcement

When adding new firewall rules:

1. Start with `ALERT` action (not `DROP`)
2. Monitor for 30 days
3. Review alerts for false positives
4. Adjust whitelist/blocklist as needed
5. Change to `DROP` action after validation

**Example**:
```hcl
# Week 1-4: Alert only
action = "ALERT"

# Week 5+: Enforce
action = "DROP"
```

## Related Documentation

- [CONTROL_TOWER_RAM_ARCHITECTURE.md](./CONTROL_TOWER_RAM_ARCHITECTURE.md) - Phase 7 integration
- [FUTURE_ROADMAP.md](./FUTURE_ROADMAP.md) - Phases 9-11 (WAF, B2B, DNS)
- [examples/microsegmented-landing-zone-pci/](./examples/microsegmented-landing-zone-pci/) - PCI example
- [examples/microsegmented-landing-zone-general/](./examples/microsegmented-landing-zone-general/) - General example
- [modules/core-network-microsegments/](./modules/core-network-microsegments/) - Core Network module
- [modules/security-groups-3tier/](./modules/security-groups-3tier/) - Security groups module
- [modules/network-firewall-microsegments/](./modules/network-firewall-microsegments/) - Firewall rules module
