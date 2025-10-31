<!--
Copyright (c) 2025 Vitale Mazo
All rights reserved.

This architecture and documentation is proprietary and confidential.
Unauthorized copying, modification, distribution, or use of this
architecture, documentation, or associated code is strictly prohibited.

Design by: Vitale Mazo
Year: 2025
-->


# AWS Global WAN - Quick Start Guide

## Project Overview

This repository contains a modular, phased approach to deploying AWS Global WAN with centralized network inspection across multiple US regions.

## What's Been Built (Phases 1-3)

✅ **Core Network Module** - Foundation for all connectivity
✅ **3 Network Segments** - Production, Non-Production, Shared Services
✅ **2 Edge Locations** - us-east-1, us-west-2
✅ **Inspection VPCs** - us-east-1 and us-west-2 with Network Firewall
✅ **NAT Gateways** - Centralized internet egress in both regions
✅ **Complete Documentation** - Architecture + Deployment guides

**Current Cost**: ~$1,115/month

## Quick Deploy (Phases 1-3)

```bash
# Clone the repo (if not already)
git clone https://github.com/vitalemazo/aws-global-wan.git
cd aws-global-wan

# Navigate to dev environment
cd environments/dev

# Initialize Terraform
terraform init

# Review the plan (both regions)
terraform plan

# Deploy all phases (1-3)
terraform apply

# Verify deployment
terraform output
```

## What's Currently Deployed

### Phase 1: Core Network
1. **Global Network** - Container for all Cloud WAN resources
2. **Core Network** - Policy-based routing engine
3. **Network Policy** - Defines segments and routing rules
4. **3 Segments**:
   - `prod` - Production workloads (isolated)
   - `non-prod` - Dev/test/staging (isolated)
   - `shared` - Shared services (accessible from all)

### Phase 2-3: Inspection VPCs
5. **us-east-1 Inspection VPC** (10.1.0.0/16)
   - AWS Network Firewall
   - NAT Gateway for internet egress
   - Cloud WAN attachment with inspection function

6. **us-west-2 Inspection VPC** (10.2.0.0/16)
   - AWS Network Firewall
   - NAT Gateway for internet egress
   - Cloud WAN attachment with inspection function

## Verification

### AWS Console
1. Navigate to **VPC** → **Cloud WAN** → **Core Networks**
2. Select your core network
3. View **Policy** tab - should show 3 segments
4. Check **Status** - should be "AVAILABLE"

### AWS CLI
```bash
# List Global Networks
aws networkmanager describe-global-networks

# Get Core Network details
aws networkmanager get-core-network \
  --core-network-id <from-terraform-output>

# View current policy
aws networkmanager get-core-network-policy \
  --core-network-id <from-terraform-output>
```

## Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────┐
│ AWS Cloud WAN Core Network                                  │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐ │
│  │ Production   │  │ Non-Prod     │  │  Shared Services │ │
│  │ Segment      │  │ Segment      │  │                  │ │
│  │ (Isolated)   │  │ (Isolated)   │  │  (Accessible)    │ │
│  └──────────────┘  └──────────────┘  └──────────────────┘ │
│         │                  │                    │          │
│         └──────────────────┴────────────────────┘          │
│                            │                                │
│                    All Traffic Flows                        │
│                   Through Inspection                        │
│                            │                                │
│         ┌──────────────────┴────────────────────┐          │
│         │                                        │          │
│    ┌────▼────────┐                      ┌───────▼──────┐   │
│    │ us-east-1   │                      │ us-west-2    │   │
│    │ Inspection  │                      │ Inspection   │   │
│    │ VPC         │                      │ VPC          │   │
│    │             │                      │              │   │
│    │ • Firewall  │                      │ • Firewall   │   │
│    │ • NAT GW    │                      │ • NAT GW     │   │
│    └─────┬───────┘                      └──────┬───────┘   │
│          │                                     │            │
│      Internet                              Internet         │
└──────────────────────────────────────────────────────────────┘

Next Phase:
  → Landing Zone VPCs (Phase 4)
```

## Project Structure

```
aws-global-wan/
├── ARCHITECTURE.md          # Complete architecture design
├── DEPLOYMENT_PLAN.md       # 6-phase deployment strategy
├── QUICK_START.md          # This file
│
├── modules/
│   ├── core-network/       # ✅ Phase 1 (COMPLETE)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   └── inspection-vpc/     # ✅ Phase 2-3 (COMPLETE)
│       ├── main.tf
│       ├── nat-gateway.tf
│       ├── network-firewall.tf
│       ├── cloudwan-attachment.tf
│       ├── route-tables.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
│
├── environments/
│   └── dev/                # ✅ Dev environment (Phases 1-3 deployed)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── Future modules (Phases 4-6):
    ├── landing-zone-vpc/    # Phase 4: Application VPCs
    └── network-policies/    # Phase 5: Advanced routing
```

## Next Steps

### ✅ Phases 1-3 Complete

You now have a complete multi-region inspection architecture:
- Core Network with 3 segments
- Inspection VPCs in us-east-1 and us-west-2
- All inter-segment traffic flows through Network Firewall
- Centralized internet egress via NAT Gateways

### Phase 4: First Landing Zone VPC (NEXT)

Deploy your first application VPC and attach to production segment.

Phase 4 will add:
- Landing Zone VPC module (reusable)
- First VPC in production segment (us-east-1)
- Subnets for application workloads
- Cloud WAN attachment
- Test connectivity through inspection

**Cost Impact**: +$36/month
**Total**: ~$1,151/month

**When Ready**:
```bash
# Phase 4 module will be created in:
# modules/landing-zone-vpc/

# See DEPLOYMENT_PLAN.md for details
```

### Phase 5: Advanced Policies

Fine-tune routing policies and add custom segment actions.

**Cost Impact**: $0
**Total**: ~$1,151/month

### Phase 6: Third Region (us-east-2)

Add inspection VPC to us-east-2 for additional coverage.

**Cost Impact**: +$430/month
**Total**: ~$1,581/month

## Cost Breakdown

| Phase | What's Deployed | Monthly Cost | Cumulative |
|-------|----------------|--------------|------------|
| **1** ✅ | **Core Network** | **$255** | **$255** |
| **2** ✅ | **us-east-1 Inspection** | **+$430** | **$685** |
| **3** ✅ | **us-west-2 Inspection** | **+$430** | **$1,115** |
| 4 | First Landing Zone | +$36 | $1,151 |
| 5 | Advanced Policies | $0 | $1,151 |
| 6 | us-east-2 Inspection | +$430 | $1,581 |

## Key Features

### Segment Isolation
- Production and non-production workloads cannot communicate
- Prevents accidental cross-environment traffic
- Shared services accessible from both

### Centralized Inspection
- All inter-segment traffic routed through inspection VPCs
- AWS Network Firewall for stateful inspection
- Logging and monitoring for all traffic flows

### Multi-Region
- Active in us-east-1 and us-west-2
- Easy to add us-east-2 (Phase 6)
- Cross-region connectivity built-in

### Cost Optimized
- Single NAT Gateway per region (not per AZ)
- Minimal Network Firewall configuration
- No redundancy in lab environment

## Common Commands

### View Resources
```bash
# List all Cloud WAN resources
aws networkmanager describe-global-networks

# Get Core Network state
aws networkmanager get-core-network \
  --core-network-id $(terraform output -raw core_network_id)

# View policy document
aws networkmanager get-core-network-policy \
  --core-network-id $(terraform output -raw core_network_id) \
  | jq '.CoreNetworkPolicy.PolicyDocument | fromjson'
```

### Modify Configuration
```bash
# Change edge locations
vi environments/dev/main.tf
# Update edge_locations variable

# Change segment settings
vi modules/core-network/variables.tf
# Modify segments default

# Apply changes
terraform plan
terraform apply
```

### Destroy Resources
```bash
# ⚠️ Warning: This will delete the Core Network
terraform destroy

# Estimated savings: $255/month
```

## Troubleshooting

### Policy Won't Apply
**Error**: "Policy validation failed"

**Solution**:
1. Check JSON syntax in policy document
2. Verify segment names are unique
3. Ensure edge locations are valid AWS regions
4. Review CloudWatch Logs for detailed errors

### Segments Not Showing
**Problem**: Segments created but not visible in console

**Solution**:
1. Wait 2-3 minutes for propagation
2. Refresh AWS Console
3. Check policy is in "LIVE" state
4. Run: `aws networkmanager list-core-network-policy-versions`

### High Costs
**Problem**: Costs higher than expected

**Solution**:
1. Verify only Phase 1 is deployed
2. Check for unexpected attachments
3. Review Cloud WAN pricing page
4. Contact AWS support if costs don't match

## Documentation

- **ARCHITECTURE.md** - Deep dive into design decisions
- **DEPLOYMENT_PLAN.md** - Step-by-step deployment guide
- **modules/*/README.md** - Module-specific documentation

## Support

### AWS Resources
- [Cloud WAN Documentation](https://docs.aws.amazon.com/vpc/latest/cloudwan/)
- [Cloud WAN Pricing](https://aws.amazon.com/cloud-wan/pricing/)
- [Network Manager API](https://docs.aws.amazon.com/networkmanager/latest/APIReference/)

### Terraform Resources
- [AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Network Manager Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_core_network)

## Contributing

This is a lab/learning project. Feel free to:
1. Experiment with configurations
2. Add new phases/modules
3. Document lessons learned
4. Optimize for cost or performance

## What's Next?

1. ✅ **Phases 1-3 Complete** - Multi-region inspection deployed!
2. 📋 Review DEPLOYMENT_PLAN.md for Phase 4 details
3. 🔨 Ready to deploy landing zone VPCs?
4. 📊 Monitor costs in AWS Cost Explorer
5. 🧪 Test connectivity between segments

---

**Estimated Time to Deploy Phases 1-3**: 20-30 minutes
**Current Monthly Cost**: ~$1,115

🎉 **Congratulations!** You've deployed a complete multi-region inspection architecture!
