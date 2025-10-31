<!--
Copyright (c) 2025 Vitale Mazo
All rights reserved.

This architecture and documentation is proprietary and confidential.
Unauthorized copying, modification, distribution, or use of this
architecture, documentation, or associated code is strictly prohibited.

Design by: Vitale Mazo
Year: 2025
-->


# Regional Failover & High Availability Design

## Current Architecture Limitations

### Single-Region Landing Zones
- **Issue**: Each landing zone VPC exists in only ONE region
- **Impact**: If region fails, application is unavailable
- **No Automatic Failover**: Cloud WAN doesn't move VPCs between regions

### Single-AZ Inspection
- **Issue**: Network Firewall and NAT Gateway in single AZ per region
- **Impact**: AZ failure takes down inspection for that region
- **No Redundancy**: Single point of failure per region

## Proposed High Availability Architecture

### Option 1: Active-Active Multi-Region (Recommended)

```
┌────────────────────────────────────────────────────────────┐
│ Route 53 / Global Accelerator                              │
│ (Health Checks + DNS/Anycast Failover)                     │
└────────────┬───────────────────────────┬───────────────────┘
             │                           │
    ┌────────▼────────┐         ┌────────▼────────┐
    │  us-east-1      │         │  us-west-2      │
    │  Region         │         │  Region         │
    │                 │         │                 │
    │  ┌───────────┐  │         │  ┌───────────┐  │
    │  │Prod VPC   │  │         │  │Prod VPC   │  │
    │  │10.10.0.0/ │  │         │  │10.20.0.0/ │  │
    │  │16 (App)   │  │         │  │16 (App)   │  │
    │  └─────┬─────┘  │         │  └─────┬─────┘  │
    │        │        │         │        │        │
    │  ┌─────▼─────┐  │         │  ┌─────▼─────┐  │
    │  │Cloud WAN  │  │         │  │Cloud WAN  │  │
    │  │Attachment │  │         │  │Attachment │  │
    │  └─────┬─────┘  │         │  └─────┬─────┘  │
    │        │        │         │        │        │
    │  ┌─────▼─────┐  │         │  ┌─────▼─────┐  │
    │  │Inspection │  │         │  │Inspection │  │
    │  │VPC (HA)   │  │         │  │VPC (HA)   │  │
    │  │• 2x AZs   │  │         │  │• 2x AZs   │  │
    │  │• 2x NAT   │  │         │  │• 2x NAT   │  │
    │  │• 2x NFW   │  │         │  │• 2x NFW   │  │
    │  └───────────┘  │         │  └───────────┘  │
    └─────────────────┘         └─────────────────┘
```

**Key Changes**:
1. Deploy application VPCs in BOTH us-east-1 and us-west-2
2. Use Route 53 health checks to detect region failures
3. DNS-based failover switches traffic between regions
4. Each region is fully self-sufficient

**Traffic Flow - Normal Operation**:
- Route 53 routes 50% traffic to us-east-1, 50% to us-west-2
- Each region handles its own inspection and egress

**Traffic Flow - us-east-1 Failure**:
- Route 53 detects health check failure
- Routes 100% traffic to us-west-2
- us-west-2 handles all traffic

### Option 2: Active-Passive with Cross-Region Failover

```
Primary Region (Active)          Secondary Region (Standby)
┌──────────────────┐            ┌──────────────────┐
│ us-east-1        │            │ us-west-2        │
│ • Prod VPC       │            │ • Prod VPC       │
│ • Handles 100%   │   Region   │ • Standby        │
│   of traffic     │   Fails    │ • Route53        │
│ • Inspection VPC │ ─────────> │   switches       │
│                  │            │ • Takes over     │
└──────────────────┘            └──────────────────┘
```

**Cost Considerations**:
- **Option 1 (Active-Active)**: 2x infrastructure cost, always running
- **Option 2 (Active-Passive)**: Lower cost, but slower failover

## Multi-AZ Inspection VPC Design

### Current Single-AZ Architecture

```
┌─────────────────────────────────────────┐
│ Inspection VPC (us-east-1)              │
│                                         │
│  AZ: us-east-1a                         │
│  ┌──────────────────────────────┐      │
│  │ Public Subnet (NAT Gateway)  │      │
│  └──────────────────────────────┘      │
│  ┌──────────────────────────────┐      │
│  │ Firewall Subnet (NFW)        │      │
│  └──────────────────────────────┘      │
│  ┌──────────────────────────────┐      │
│  │ Attachment Subnet (CloudWAN) │      │
│  └──────────────────────────────┘      │
│                                         │
│  Single Point of Failure ⚠️             │
└─────────────────────────────────────────┘
```

### Proposed Multi-AZ Architecture

```
┌──────────────────────────────────────────────────────────┐
│ Inspection VPC (us-east-1) - Multi-AZ                    │
│                                                          │
│  ┌──────────────────────┐  ┌──────────────────────┐    │
│  │ AZ: us-east-1a       │  │ AZ: us-east-1b       │    │
│  │                      │  │                      │    │
│  │ ┌──────────────────┐ │  │ ┌──────────────────┐ │    │
│  │ │Public (NAT GW 1) │ │  │ │Public (NAT GW 2) │ │    │
│  │ └──────────────────┘ │  │ └──────────────────┘ │    │
│  │ ┌──────────────────┐ │  │ ┌──────────────────┐ │    │
│  │ │Firewall (NFW 1)  │ │  │ │Firewall (NFW 2)  │ │    │
│  │ └──────────────────┘ │  │ └──────────────────┘ │    │
│  │ ┌──────────────────┐ │  │ ┌──────────────────┐ │    │
│  │ │Attachment (CW 1) │ │  │ │Attachment (CW 2) │ │    │
│  │ └──────────────────┘ │  │ └──────────────────┘ │    │
│  └──────────────────────┘  └──────────────────────┘    │
│                                                          │
│  High Availability ✅                                     │
└──────────────────────────────────────────────────────────┘
```

**Traffic Flow with Multi-AZ**:
- Cloud WAN automatically load balances across both AZ attachments
- If AZ-1a fails, all traffic flows through AZ-1b
- Network Firewall automatically handles cross-AZ traffic
- Each AZ has its own NAT Gateway for redundancy

## Gateway Load Balancer Alternative

### Why We're NOT Using GWLB

**Current Design (Network Firewall)**:
- ✅ Fully managed service
- ✅ No instance management
- ✅ Auto-scaling built-in
- ✅ Simpler architecture
- ✅ Lower operational overhead

**GWLB Would Be Needed For**:
- Third-party firewalls (Palo Alto, Fortinet, Check Point)
- Custom firewall appliances
- Specific compliance requirements
- Advanced features not in Network Firewall

### GWLB Architecture (If Needed)

```
┌────────────────────────────────────────────────────┐
│ Inspection VPC with GWLB                           │
│                                                    │
│  ┌──────────────────┐                             │
│  │ Cloud WAN        │                             │
│  │ Attachment       │                             │
│  └────────┬─────────┘                             │
│           │                                        │
│  ┌────────▼─────────┐                             │
│  │ Gateway Load     │                             │
│  │ Balancer         │                             │
│  └────┬──────┬──────┘                             │
│       │      │                                     │
│  ┌────▼──┐ ┌▼───────┐                             │
│  │FW VM  │ │FW VM   │  Auto-scaling group        │
│  │(AZ-a) │ │(AZ-b)  │  of firewall instances     │
│  └───────┘ └────────┘                             │
│                                                    │
│  • More complex                                    │
│  • More expensive                                  │
│  • More flexibility                                │
└────────────────────────────────────────────────────┘
```

## Implementation Plan for HA

### Phase 5A: Multi-AZ Inspection VPCs

**Changes Needed**:
1. Update `inspection-vpc` module:
   - Set `multi_az = true` by default
   - Deploy subnets in 2 AZs
   - Create 2 NAT Gateways (one per AZ)
   - Network Firewall automatically spans AZs

2. Cost Impact:
   - Additional NAT Gateway: +$32/month per region
   - Network Firewall data processing scales with traffic
   - Total additional: ~$64/month for both regions

**Module Update**:
```hcl
module "inspection_vpc_useast1" {
  source = "../../modules/inspection-vpc"

  # Enable Multi-AZ for HA
  multi_az = true  # ← Change from false

  # Rest of configuration...
}
```

### Phase 5B: Active-Active Multi-Region

**Changes Needed**:
1. Deploy prod VPC in BOTH regions:
   ```hcl
   # us-east-1 prod VPC (already exists)
   module "landing_zone_prod_useast1" { ... }

   # us-west-2 prod VPC (NEW)
   module "landing_zone_prod_uswest2" {
     vpc_cidr = "10.20.0.0/16"  # Different CIDR
     segment_name = "prod"
     region = "us-west-2"
   }
   ```

2. Set up Route 53 health checks:
   ```hcl
   resource "aws_route53_health_check" "useast1" {
     ip_address = module.landing_zone_prod_useast1.nat_gateway_ip
     port = 443
     type = "HTTPS"
     resource_path = "/health"
     failure_threshold = 3
     request_interval = 30
   }
   ```

3. Configure DNS failover:
   ```hcl
   resource "aws_route53_record" "app" {
     zone_id = var.route53_zone_id
     name    = "app.example.com"
     type    = "A"

     set_identifier = "us-east-1"
     health_check_id = aws_route53_health_check.useast1.id

     alias {
       name = module.alb_useast1.dns_name
       zone_id = module.alb_useast1.zone_id
       evaluate_target_health = true
     }
   }
   ```

## Cloud WAN Cross-Region Routing

**Good News**: Cloud WAN already handles cross-region routing!

```
Scenario: us-east-1 region failure

Before Failure:
  App (us-east-1) → Cloud WAN → Inspection (us-east-1) → Internet

After Failure (automatic Cloud WAN rerouting):
  App (us-west-2) → Cloud WAN → Inspection (us-west-2) → Internet
```

**Cloud WAN Capabilities**:
- Automatically detects attachment failures
- Reroutes traffic to available paths
- No configuration changes needed
- Converges in seconds

## Monitoring & Alerting for Failover

### CloudWatch Alarms Needed

```hcl
# NAT Gateway availability
resource "aws_cloudwatch_metric_alarm" "nat_gateway_down" {
  alarm_name = "nat-gateway-${var.region}-unavailable"
  metric_name = "PacketsDropCount"
  namespace = "AWS/NATGateway"
  statistic = "Sum"
  period = 60
  evaluation_periods = 2
  threshold = 100
  comparison_operator = "GreaterThanThreshold"

  alarm_actions = [var.sns_topic_arn]
}

# Network Firewall availability
resource "aws_cloudwatch_metric_alarm" "firewall_down" {
  alarm_name = "network-firewall-${var.region}-unavailable"
  metric_name = "Packets"
  namespace = "AWS/NetworkFirewall"
  statistic = "Sum"
  period = 300
  evaluation_periods = 2
  threshold = 0
  comparison_operator = "LessThanOrEqualToThreshold"

  alarm_actions = [var.sns_topic_arn]
}

# Cloud WAN attachment state
resource "aws_cloudwatch_metric_alarm" "attachment_down" {
  alarm_name = "cloudwan-attachment-${var.region}-unavailable"
  metric_name = "AttachmentState"
  namespace = "AWS/NetworkManager"
  statistic = "Minimum"
  period = 60
  evaluation_periods = 2
  threshold = 1
  comparison_operator = "LessThanThreshold"

  alarm_actions = [var.sns_topic_arn]
}
```

## Cost Comparison

### Current Architecture (Single-AZ, Single-Region)
| Component | Cost |
|-----------|------|
| Core Network | $255 |
| 2x Inspection VPCs (single-AZ) | $860 |
| 2x Landing Zones | $36 |
| **Total** | **$1,151/month** |

### HA Architecture (Multi-AZ, Active-Active)
| Component | Cost |
|-----------|------|
| Core Network | $255 |
| 2x Inspection VPCs (multi-AZ) | $924 (+$64) |
| 4x Landing Zones (2 per region) | $72 (+$36) |
| Route 53 health checks | $1 |
| **Total** | **$1,252/month** (+$101) |

**HA Premium**: ~9% cost increase for full regional redundancy

## Recommendations

### For Development/Testing
**Keep current architecture**:
- Single-AZ inspection VPCs
- Single landing zone per segment
- Cost-optimized
- Acceptable downtime risk

### For Production
**Implement HA architecture**:
1. **Immediate**: Multi-AZ inspection VPCs (+$64/month)
   - Protects against AZ failures
   - Quick win for availability

2. **Phase 2**: Active-active multi-region (+$37/month more)
   - Full regional redundancy
   - Route 53 failover
   - Near-zero RPO/RTO

3. **Optional**: Consider GWLB only if:
   - Need third-party firewalls
   - Compliance requirements
   - Advanced firewall features

### AWS Best Practices Alignment

✅ **Well-Architected Framework**:
- Reliability: Multi-AZ and multi-region
- Performance: Regional optimization
- Cost Optimization: Right-sized for workload
- Security: Centralized inspection maintained

## Next Steps

Would you like me to:
1. Implement multi-AZ inspection VPCs?
2. Add active-active multi-region landing zones?
3. Create Route 53 failover configuration?
4. Design GWLB alternative architecture?
5. Add CloudWatch alarms and monitoring?
