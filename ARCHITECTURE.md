<!--
Copyright (c) 2025 Vitale Mazo
All rights reserved.

This architecture and documentation is proprietary and confidential.
Unauthorized copying, modification, distribution, or use of this
architecture, documentation, or associated code is strictly prohibited.

Design by: Vitale Mazo
Year: 2025
-->


# AWS Global WAN Architecture Design

## Overview

Multi-region AWS Global WAN deployment with centralized inspection and segmented routing for production, non-production, and shared services across three US regions.

## Architecture Goals

1. **Cost Optimization**: Minimize AWS costs for lab/learning environment
2. **Security**: All traffic flows through centralized inspection VPCs
3. **Modularity**: Reusable, composable Terraform modules
4. **Segmentation**: Isolated network segments for prod/non-prod/shared
5. **Scalability**: Easy to add new regions and landing zones

## Regional Design

### Primary Regions
- **us-east-1** (N. Virginia) - Primary/Core region
- **us-west-2** (Oregon) - Secondary region
- **us-east-2** (Ohio) - Tertiary region

Each region contains:
- **Inspection VPC**: Centralized egress with AWS Network Firewall
- **Cloud WAN Attachment**: Connects inspection VPC to Core Network
- **Future Landing Zones**: Application VPCs that attach to Core Network

## Network Segmentation Strategy

### Core Network Segments

```
┌─────────────────────────────────────────────────────────────────┐
│                  AWS Cloud WAN Core Network                     │
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │  Prod Segment    │  │ Non-Prod Segment │  │Shared Segment│ │
│  │  Isolated        │  │  Isolated        │  │  Services    │ │
│  │  10.0.0.0/8      │  │  172.16.0.0/12   │  │192.168.0.0/16│ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
│           │                     │                    │         │
│           └─────────────────────┴────────────────────┘         │
│                              │                                 │
│                    Route to Inspection VPC                     │
└─────────────────────────────────────────────────────────────────┘
```

### Traffic Flow

```
Landing Zone VPC → Core Network Segment → Inspection VPC → Internet/On-Prem
                      (via policy)         (AWS NFW)
```

## Detailed Architecture

### Region: us-east-1 (Primary)

```
┌───────────────────────────────────────────────────────────────────┐
│ us-east-1 Region                                                  │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Inspection VPC (10.1.0.0/16)                                │ │
│  │                                                             │ │
│  │  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   │ │
│  │  │Public Subnet │   │  NFW Subnet  │   │  TGW Subnet  │   │ │
│  │  │  NAT GW      │←──│AWS Firewall  │←──│Cloud WAN Att.│   │ │
│  │  │10.1.0.0/24   │   │10.1.1.0/24   │   │10.1.2.0/24   │   │ │
│  │  └──────────────┘   └──────────────┘   └──────────────┘   │ │
│  │         │                   │                   ▲          │ │
│  │         │                   │                   │          │ │
│  │         ▼                   ▼                   │          │ │
│  │    Internet            Firewall Logs      From Core       │ │
│  │     Gateway              to S3           Network          │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                  ▲                                │
│                                  │                                │
│  ┌───────────────────────────────┴───────────────────────────┐   │
│  │ Cloud WAN Core Network Attachment                         │   │
│  │ - Prod Segment Association                                │   │
│  │ - Non-Prod Segment Association                            │   │
│  │ - Shared Segment Association                              │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Future Landing Zone VPCs                                    │ │
│  │ - Prod App VPC (10.10.0.0/16) → Prod Segment              │ │
│  │ - Dev App VPC (172.16.0.0/16) → Non-Prod Segment          │ │
│  │ - Shared Services VPC (192.168.0.0/16) → Shared Segment   │ │
│  └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

### Regions: us-west-2 & us-east-2 (Similar Pattern)

Each region follows the same pattern:
- Inspection VPC with NAT GW, Network Firewall, Cloud WAN attachment
- Future landing zone VPCs that attach to Core Network segments

## IP Address Allocation

### Inspection VPCs (Cost-Optimized)
- **us-east-1**: 10.1.0.0/16
  - Public: 10.1.0.0/24 (NAT GW)
  - NFW: 10.1.1.0/24 (Network Firewall endpoints)
  - Attachment: 10.1.2.0/24 (Cloud WAN)

- **us-west-2**: 10.2.0.0/16
  - Public: 10.2.0.0/24
  - NFW: 10.2.1.0/24
  - Attachment: 10.2.2.0/24

- **us-east-2**: 10.3.0.0/16
  - Public: 10.3.0.0/24
  - NFW: 10.3.1.0/24
  - Attachment: 10.3.2.0/24

### Landing Zone VPCs (Future)
- **Production**: 10.0.0.0/8 (10.10-99.x.x/16 per VPC)
- **Non-Production**: 172.16.0.0/12 (172.16-31.x.x/16 per VPC)
- **Shared Services**: 192.168.0.0/16 (192.168.x.0/24 per service)

## Cost Optimization Strategies

1. **Single NAT Gateway per Region** (instead of per AZ)
   - Cost: ~$32/month per region
   - Trade-off: No AZ redundancy (acceptable for lab)

2. **Minimal Network Firewall**
   - Single AZ deployment
   - Cost: ~$395/month per region for basic firewall
   - Trade-off: No AZ redundancy

3. **Cloud WAN Pricing**
   - Core Network: $0.35/hour = ~$255/month
   - Attachments: $0.05/hour per attachment = ~$36/month each
   - Data transfer: $0.02/GB

4. **Cost-Saving Measures**
   - Use smallest firewall endpoint size
   - Limit number of regions to 2 initially (us-east-1, us-west-2)
   - Deploy us-east-2 only when needed
   - Use VPC endpoint interfaces for AWS services to reduce NAT costs

**Estimated Monthly Cost (2 regions):**
- Cloud WAN Core: $255
- 2 Attachments per region: $144 (4 x $36)
- 2 NAT Gateways: $64
- 2 Network Firewalls: $790
- **Total: ~$1,253/month** (can reduce by starting with 1 region)

## Module Structure

```
modules/
├── core-network/           # Phase 1: Core Network
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── inspection-vpc/         # Phase 2: Inspection VPC
│   ├── main.tf            # VPC, Subnets, Route Tables
│   ├── nat-gateway.tf     # NAT Gateway resources
│   ├── network-firewall.tf # AWS Network Firewall
│   ├── cloudwan-attachment.tf # Core Network attachment
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── landing-zone-vpc/       # Phase 3: Landing Zone VPC
│   ├── main.tf            # VPC, Subnets
│   ├── cloudwan-attachment.tf # Attach to segment
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
└── network-policies/       # Phase 4: Network Policies
    ├── prod-policy.tf
    ├── nonprod-policy.tf
    ├── shared-policy.tf
    └── README.md
```

## Routing Logic

### Core Network Policy

```json
{
  "segments": [
    {
      "name": "prod",
      "require-attachment-acceptance": false,
      "isolate-attachments": true
    },
    {
      "name": "non-prod",
      "require-attachment-acceptance": false,
      "isolate-attachments": true
    },
    {
      "name": "shared",
      "require-attachment-acceptance": false,
      "isolate-attachments": false
    }
  ],
  "segment-actions": [
    {
      "action": "send-via",
      "segment": "prod",
      "mode": "attachment-route",
      "when-sent-to": {
        "segments": ["*"]
      },
      "via": {
        "network-function-groups": ["inspection"]
      }
    }
  ]
}
```

### Inspection VPC Routing

**Public Subnet Route Table:**
```
0.0.0.0/0 → Internet Gateway
10.0.0.0/8 → Network Firewall Endpoint
172.16.0.0/12 → Network Firewall Endpoint
192.168.0.0/16 → Network Firewall Endpoint
```

**Firewall Subnet Route Table:**
```
0.0.0.0/0 → NAT Gateway
10.0.0.0/8 → Cloud WAN Attachment
172.16.0.0/12 → Cloud WAN Attachment
192.168.0.0/16 → Cloud WAN Attachment
```

**Attachment Subnet Route Table:**
```
0.0.0.0/0 → Network Firewall Endpoint
```

## Deployment Phases

### Phase 1: Foundation (Week 1)
- **Goal**: Create Core Network with segment structure
- **Deliverables**:
  - Global Network
  - Core Network with 3 segments
  - Basic network policy
- **Cost**: $255/month
- **Risk**: Low

### Phase 2: First Inspection VPC (Week 2)
- **Goal**: Deploy inspection infrastructure in us-east-1
- **Deliverables**:
  - Inspection VPC
  - NAT Gateway
  - Network Firewall (basic rules)
  - Cloud WAN attachment
- **Cost**: +$430/month
- **Risk**: Medium (new NFW configuration)

### Phase 3: Second Region (Week 3)
- **Goal**: Replicate to us-west-2
- **Deliverables**:
  - us-west-2 inspection VPC
  - Cross-region connectivity
  - Routing validation
- **Cost**: +$430/month
- **Risk**: Low (proven pattern)

### Phase 4: First Landing Zone (Week 4)
- **Goal**: Create and attach sample application VPC
- **Deliverables**:
  - Landing zone VPC module
  - Attachment to prod segment
  - Validate traffic flows through inspection
- **Cost**: +$36/month
- **Risk**: Medium (traffic flow validation)

### Phase 5: Segment Policies (Week 5)
- **Goal**: Implement full routing policies
- **Deliverables**:
  - Prod/non-prod isolation
  - Shared services access
  - Inter-segment routing rules
- **Cost**: $0
- **Risk**: Medium (policy complexity)

### Phase 6: Third Region (Optional)
- **Goal**: Add us-east-2 for full 3-region setup
- **Deliverables**:
  - us-east-2 inspection VPC
  - 3-region routing
- **Cost**: +$430/month
- **Risk**: Low

## Traffic Flow Examples

### Scenario 1: Prod App in us-east-1 → Internet
```
Prod VPC (10.10.0.0/16)
  → Core Network (Prod Segment)
  → Inspection VPC (10.1.0.0/16)
  → Network Firewall (inspect)
  → NAT Gateway
  → Internet
```

### Scenario 2: Dev App in us-west-2 → Shared Service in us-east-1
```
Dev VPC us-west-2 (172.16.0.0/16)
  → Core Network (Non-Prod Segment)
  → Policy routes to Shared Segment
  → Inspection VPC us-west-2 (10.2.0.0/16)
  → Network Firewall (inspect)
  → Core Network (Shared Segment)
  → Shared Services VPC us-east-1 (192.168.0.0/16)
```

### Scenario 3: Cross-Region Prod Communication
```
Prod VPC us-east-1 (10.10.0.0/16)
  → Core Network (Prod Segment)
  → Inspection VPC us-east-1 (10.1.0.0/16)
  → Network Firewall (inspect)
  → Core Network (Prod Segment)
  → Inspection VPC us-west-2 (10.2.0.0/16)
  → Network Firewall (inspect)
  → Prod VPC us-west-2 (10.11.0.0/16)
```

## Security Considerations

1. **Network Firewall Rules**
   - Default deny all
   - Explicit allow rules for required traffic
   - Log all denied traffic

2. **Segment Isolation**
   - Prod cannot communicate with non-prod by default
   - Shared segment accessible from both with inspection

3. **Logging**
   - Flow logs for all VPCs
   - Firewall logs to S3
   - Cloud WAN route analyzer

4. **Future Enhancements**
   - AWS WAF integration
   - GuardDuty for threat detection
   - Security Hub integration

## Monitoring & Operations

### Key Metrics
- Network Firewall packet/byte counts
- Cloud WAN attachment utilization
- NAT Gateway costs
- Route propagation status

### Alarms
- Network Firewall endpoint health
- Attachment state changes
- High data transfer costs
- Route table misconfigurations

## Next Steps

1. Review and approve architecture
2. Begin Phase 1 implementation
3. Set up monitoring and alerting
4. Document runbooks for common operations
5. Plan Phase 2 deployment
