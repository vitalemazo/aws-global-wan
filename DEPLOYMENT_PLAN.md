# AWS Global WAN Deployment Plan

## Project Breakdown

This project is broken into 6 phases to manage complexity and cost. Each phase is independently deployable and testable.

## Phase 1: Core Network Foundation (START HERE)

### Objective
Create the AWS Cloud WAN Global Network and Core Network with segment structure.

### Deliverables
- Global Network resource
- Core Network with 3 segments (prod, non-prod, shared)
- Basic network policy allowing attachments
- No inspection yet (comes in Phase 2)

### Cost Impact
- **~$255/month** (Core Network only)

### Files to Create
```
modules/core-network/
├── main.tf              # Global Network, Core Network
├── policy.tf            # Network policy with segments
├── variables.tf         # Region list, segment configs
├── outputs.tf           # Core Network ID, ARN
└── README.md            # Module documentation

environments/dev/
├── main.tf              # Root module calling core-network
├── variables.tf         # Dev-specific variables
├── terraform.tfvars     # Actual values
└── backend.tf           # S3 backend (optional)
```

### Success Criteria
- [ ] Core Network created and active
- [ ] 3 segments visible in console
- [ ] Policy document validates
- [ ] No attachments yet (expected)

### Testing
```bash
cd environments/dev
terraform init
terraform plan
terraform apply

# Verify in console
aws networkmanager list-core-networks
```

---

## Phase 2: First Inspection VPC (us-east-1)

### Objective
Deploy inspection infrastructure in primary region with all traffic routing components.

### Deliverables
- Inspection VPC (10.1.0.0/16)
- 3 subnets: Public, Firewall, Attachment
- NAT Gateway for internet egress
- AWS Network Firewall with basic allow-all policy
- Cloud WAN attachment to all 3 segments
- Complete routing between all components

### Cost Impact
- **+$430/month** (NAT GW + Network Firewall + Attachment)
- **Total: $685/month**

### Files to Create
```
modules/inspection-vpc/
├── main.tf                    # VPC, subnets, IGW
├── nat-gateway.tf             # NAT Gateway + EIP
├── network-firewall.tf        # NFW firewall + endpoints
├── firewall-policy.tf         # Basic firewall rules
├── route-tables.tf            # All 3 subnet route tables
├── cloudwan-attachment.tf     # Core Network attachment
├── variables.tf
├── outputs.tf
└── README.md

environments/dev/
├── inspection-use1.tf         # Call inspection-vpc module
└── terraform.tfvars           # Add us-east-1 config
```

### Network Firewall Policy (Basic)
```
Rule 1: Allow all outbound HTTPS (443)
Rule 2: Allow all outbound HTTP (80)
Rule 3: Allow all outbound DNS (53)
Rule 4: Deny all other traffic
Action: Alert and log
```

### Routing Configuration

**Public Subnet (10.1.0.0/24):**
```hcl
0.0.0.0/0 → Internet Gateway
10.0.0.0/8 → Firewall Endpoint
172.16.0.0/12 → Firewall Endpoint
192.168.0.0/16 → Firewall Endpoint
```

**Firewall Subnet (10.1.1.0/24):**
```hcl
0.0.0.0/0 → NAT Gateway
10.0.0.0/8 → Cloud WAN Attachment
172.16.0.0/12 → Cloud WAN Attachment
192.168.0.0/16 → Cloud WAN Attachment
```

**Attachment Subnet (10.1.2.0/24):**
```hcl
0.0.0.0/0 → Firewall Endpoint
```

### Success Criteria
- [ ] VPC and all subnets created
- [ ] NAT Gateway operational
- [ ] Network Firewall healthy
- [ ] Cloud WAN attachment in AVAILABLE state
- [ ] All route tables configured correctly
- [ ] Can ping 8.8.8.8 from test EC2 in attachment subnet

### Testing
```bash
# Deploy
terraform apply

# Verify attachment
aws networkmanager get-vpc-attachment --attachment-id <id>

# Test connectivity (deploy test EC2 in attachment subnet)
# SSH to instance and test:
curl -I https://www.google.com  # Should work through NAT

# Check firewall logs
aws logs tail /aws/network-firewall/flow-logs --follow
```

---

## Phase 3: Second Inspection VPC (us-west-2)

### Objective
Replicate inspection infrastructure to second region.

### Deliverables
- Inspection VPC in us-west-2 (10.2.0.0/16)
- Same components as Phase 2
- Cross-region connectivity validation

### Cost Impact
- **+$430/month**
- **Total: $1,115/month**

### Files to Create
```
environments/dev/
└── inspection-usw2.tf         # Second region inspection VPC
```

### Success Criteria
- [ ] us-west-2 inspection VPC operational
- [ ] Both regions attached to Core Network
- [ ] Can route between regions through Core Network

### Testing
```bash
# Deploy us-west-2
terraform apply

# Test cross-region connectivity
# Deploy test EC2 in both regions
# Ping from us-east-1 to us-west-2 through Core Network
```

---

## Phase 4: First Landing Zone VPC

### Objective
Create reusable landing zone module and deploy first application VPC.

### Deliverables
- Landing zone VPC module (generic)
- First prod VPC in us-east-1 (10.10.0.0/16)
- Attachment to prod segment
- Traffic validation through inspection

### Cost Impact
- **+$36/month** (1 attachment)
- **Total: $1,151/month**

### Files to Create
```
modules/landing-zone-vpc/
├── main.tf                    # VPC, subnets
├── cloudwan-attachment.tf     # Attach to segment
├── route-tables.tf            # Default route to Core Network
├── variables.tf
├── outputs.tf
└── README.md

environments/dev/
└── landing-zone-prod-use1.tf  # First landing zone
```

### Landing Zone Configuration
```hcl
vpc_cidr = "10.10.0.0/16"
segment = "prod"
region = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]
```

### Success Criteria
- [ ] Landing zone VPC created
- [ ] Attached to prod segment
- [ ] Default route points to Core Network
- [ ] Traffic flows through us-east-1 inspection VPC
- [ ] Can reach internet from EC2 in landing zone

### Testing
```bash
# Deploy landing zone
terraform apply

# Deploy test EC2 in landing zone VPC
# Verify traffic path:
# Landing Zone → Core Network (Prod) → Inspection VPC → NFW → NAT → Internet

# Check flow logs to confirm path
```

---

## Phase 5: Advanced Segment Policies

### Objective
Implement full inter-segment routing with security policies.

### Deliverables
- Enhanced Core Network policy
- Prod/non-prod isolation
- Shared services routing
- Network function groups for inspection

### Cost Impact
- **$0** (policy changes only)
- **Total: $1,151/month**

### Files to Create
```
modules/network-policies/
├── prod-segment.tf           # Prod segment policy
├── nonprod-segment.tf        # Non-prod segment policy
├── shared-segment.tf         # Shared segment policy
├── inspection-routing.tf     # Send-via actions
├── variables.tf
└── README.md

environments/dev/
└── Update core-network module with new policy
```

### Policy Rules
1. **Prod Segment**
   - Isolated from non-prod
   - Can access shared services
   - All traffic via inspection

2. **Non-Prod Segment**
   - Isolated from prod
   - Can access shared services
   - All traffic via inspection

3. **Shared Segment**
   - Accessible from prod and non-prod
   - No direct inter-segment routing

### Success Criteria
- [ ] Prod VPC cannot reach non-prod VPC
- [ ] Both can reach shared services
- [ ] All traffic inspected by NFW
- [ ] Policy validation passes

### Testing
```bash
# Deploy 3 landing zones (prod, non-prod, shared)
# Test connectivity matrix:
# Prod → Shared ✅
# Prod → Non-Prod ❌
# Non-Prod → Shared ✅
# Non-Prod → Prod ❌
```

---

## Phase 6: Third Region (Optional)

### Objective
Complete the 3-region design with us-east-2.

### Deliverables
- Inspection VPC in us-east-2 (10.3.0.0/16)
- 3-region routing validation

### Cost Impact
- **+$430/month**
- **Total: $1,581/month**

### Files to Create
```
environments/dev/
└── inspection-use2.tf         # Third region
```

### Success Criteria
- [ ] All 3 regions operational
- [ ] Cross-region traffic flows correctly
- [ ] Latency-based routing (future enhancement)

---

## Cost Summary by Phase

| Phase | Description | Monthly Cost | Cumulative |
|-------|-------------|--------------|------------|
| 1 | Core Network | $255 | $255 |
| 2 | us-east-1 Inspection | +$430 | $685 |
| 3 | us-west-2 Inspection | +$430 | $1,115 |
| 4 | First Landing Zone | +$36 | $1,151 |
| 5 | Segment Policies | $0 | $1,151 |
| 6 | us-east-2 Inspection | +$430 | $1,581 |

## Cost Reduction Strategies

### Option A: Start with 1 Region
- Deploy only Phase 1 + Phase 2 (us-east-1)
- **Cost: $685/month**
- Add regions later when needed

### Option B: Use Smaller Regions
- Replace us-west-2 with us-east-2 (same price tier)
- **No cost savings** but faster latency to East Coast

### Option C: Reduce Firewall Scope
- Start with stateless firewall rules (cheaper)
- Upgrade to stateful when needed
- **Savings: ~$100/month per region**

## Recommended Deployment Order

**Week 1: Foundation**
- Phase 1: Core Network
- Test segment creation
- Document in Confluence/Wiki

**Week 2: First Region**
- Phase 2: us-east-1 Inspection
- Validate all routing
- Run connectivity tests

**Week 3: Prove the Pattern**
- Phase 4: First Landing Zone (skip Phase 3)
- Validate end-to-end traffic flow
- Document traffic paths

**Week 4: Expand**
- Phase 3: us-west-2 Inspection
- Phase 5: Segment Policies
- Test isolation

**Week 5: Complete (Optional)**
- Phase 6: us-east-2
- Performance testing
- Documentation complete

## Rollback Procedures

### Phase 1 Rollback
```bash
terraform destroy
# No cost impact, just policy cleanup
```

### Phase 2+ Rollback
```bash
# Detach from Core Network first
terraform destroy -target=module.inspection_vpc.aws_networkmanager_vpc_attachment

# Then destroy VPC resources
terraform destroy -target=module.inspection_vpc
```

## Success Metrics

- [ ] All phases deployed without errors
- [ ] Traffic flows through inspection in all paths
- [ ] Segment isolation working correctly
- [ ] Monthly costs within $200 of estimates
- [ ] All documentation complete
- [ ] Runbooks for common operations created

## Next Actions

1. **Review ARCHITECTURE.md** - Understand the design
2. **Start Phase 1** - Deploy core network
3. **Set up monitoring** - CloudWatch dashboards
4. **Create runbooks** - Common operations
5. **Schedule reviews** - Weekly checkpoint meetings
