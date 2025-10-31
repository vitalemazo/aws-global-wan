# Control Tower and RAM Architecture Guide

## Executive Summary

This document describes the Control Tower and Resource Access Manager (RAM) integration for the AWS Global WAN architecture. Control Tower provides multi-account governance, while RAM enables secure resource sharing across the organization.

## What Control Tower Does For Us

### 1. **Multi-Account Governance**

Control Tower provides enterprise-grade account management:

- **Automated Account Provisioning**: Create new AWS accounts via Service Catalog
- **Baseline Configuration**: Every account gets consistent security and networking setup
- **Centralized Logging**: All accounts send logs to central Log Archive account
- **Audit Trail**: Centralized audit via Audit account with read-only access

### 2. **Network Governance via SCPs**

Service Control Policies (SCPs) enforce network architecture standards:

#### Force IPAM Usage
```json
{
  "Sid": "DenyVPCCreationWithoutIPAM",
  "Effect": "Deny",
  "Action": "ec2:CreateVpc",
  "Resource": "*",
  "Condition": {
    "Null": {
      "ec2:Ipv4IpamPoolId": "true"
    }
  }
}
```
**Purpose**: Prevents anyone from creating VPCs without using IPAM pools. This ensures:
- No IP address conflicts
- Centralized IP management
- Visibility into all CIDR allocations

#### Prevent Transit Gateway
```json
{
  "Sid": "DenyTransitGatewayCreation",
  "Effect": "Deny",
  "Action": [
    "ec2:CreateTransitGateway",
    "ec2:CreateTransitGatewayVpcAttachment"
  ],
  "Resource": "*"
}
```
**Purpose**: Forces all accounts to use Cloud WAN instead of Transit Gateway for consistency.

#### Prevent VPC Peering
```json
{
  "Sid": "DenyVPCPeering",
  "Effect": "Deny",
  "Action": [
    "ec2:CreateVpcPeeringConnection",
    "ec2:AcceptVpcPeeringConnection"
  ],
  "Resource": "*"
}
```
**Purpose**: Prevents point-to-point VPC connections. Forces all connectivity through Cloud WAN for centralized control.

#### Centralize Internet Egress
```json
{
  "Sid": "DenyInternetGatewayInWorkloadAccounts",
  "Effect": "Deny",
  "Action": [
    "ec2:AttachInternetGateway",
    "ec2:CreateInternetGateway"
  ],
  "Resource": "*",
  "Condition": {
    "StringNotEquals": {
      "aws:PrincipalAccount": ["<network-account-id>"]
    }
  }
}
```
**Purpose**: Prevents workload accounts from creating Internet Gateways. All internet traffic must flow through centralized inspection VPCs with Network Firewall.

#### Region Restriction
```json
{
  "Sid": "DenyAllOutsideAllowedRegions",
  "Effect": "Deny",
  "NotAction": ["cloudfront:*", "iam:*", "route53:*", "support:*"],
  "Resource": "*",
  "Condition": {
    "StringNotEquals": {
      "aws:RequestedRegion": ["us-east-1", "us-west-2", "us-east-2"]
    }
  }
}
```
**Purpose**: Restricts operations to approved regions only, reducing compliance scope and attack surface.

### 3. **Account Factory Automation**

When a new account is provisioned through Control Tower:

```
1. User requests account via Service Catalog
   ↓
2. Control Tower creates account in designated OU
   ↓
3. SCPs automatically applied based on OU
   ↓
4. Our account factory module runs:
   - Allocates CIDR from IPAM pool (automatic, no conflicts)
   - Creates landing zone VPC
   - Attaches VPC to Cloud WAN (segment based on environment)
   - Enables VPC Flow Logs → CloudWatch
   - Enables GuardDuty threat detection
   - Enables Security Hub compliance scanning
   - Enables AWS Config for resource tracking
   ↓
5. Account ready for workload deployment (5-10 minutes)
```

**Result**: New accounts are production-ready with networking and security baselines in place automatically.

## What RAM (Resource Access Manager) Does For Us

### 1. **Cloud WAN Core Network Sharing**

RAM shares the Core Network across all accounts:

```
Network Account (owns Core Network)
         ↓ (RAM Share)
Organization/OUs/Accounts
         ↓
All accounts can attach VPCs to shared Core Network
```

**Benefits**:
- Single Core Network for entire organization
- Centralized routing policy management
- No per-account Core Network costs
- Consistent network segments across all accounts

### 2. **IPAM Pool Sharing**

RAM shares IPAM pools so all accounts can allocate CIDRs:

```
Network Account (owns IPAM)
         ↓ (RAM Share)
Production OU → Access to production IPAM pool (10.0.0.0/8)
Non-Prod OU → Access to non-prod IPAM pool (172.16.0.0/12)
Shared Services OU → Access to shared IPAM pool (192.168.0.0/16)
```

**Benefits**:
- Automatic CIDR allocation in member accounts
- No manual IP planning required
- Prevents IP conflicts organization-wide
- Centralized visibility into IP utilization

### 3. **Optional: Route 53 Resolver Rules**

RAM can share DNS resolver rules for centralized DNS:

```
Shared Services Account (owns Route 53 Resolver Rules)
         ↓ (RAM Share)
All Accounts
         ↓
Unified DNS resolution (on-prem Active Directory, private zones)
```

## Organizational Structure

```
Root (AWS Organization)
├── Security OU
│   ├── Log Archive Account (CloudWatch Logs, S3)
│   └── Audit Account (read-only access to all accounts)
│
├── Infrastructure OU
│   ├── Network Account
│   │   ├── Cloud WAN Core Network (shared via RAM)
│   │   ├── IPAM (shared via RAM)
│   │   ├── Inspection VPCs (us-east-1, us-west-2)
│   │   └── Network Firewall
│   └── Shared Services Account
│       ├── Active Directory
│       ├── Route 53 Private Zones
│       └── Centralized Monitoring
│
├── Workloads OU
│   ├── Production OU (SCPs: Force IPAM, Block IGW, Region restrict)
│   │   ├── Prod App 1 Account
│   │   │   └── Landing Zone VPC (IPAM: 10.0.0.0/16) → Cloud WAN prod segment
│   │   ├── Prod App 2 Account
│   │   │   └── Landing Zone VPC (IPAM: 10.1.0.0/16) → Cloud WAN prod segment
│   │   └── [...]
│   │
│   ├── Non-Production OU (SCPs: Force IPAM, Block IGW, Region restrict)
│   │   ├── Dev Account
│   │   │   └── Landing Zone VPC (IPAM: 172.16.0.0/16) → Cloud WAN non-prod segment
│   │   ├── Test Account
│   │   │   └── Landing Zone VPC (IPAM: 172.17.0.0/16) → Cloud WAN non-prod segment
│   │   └── [...]
│   │
│   └── Sandbox OU (Relaxed SCPs for experimentation)
│       └── Developer Sandbox Accounts
│
└── Suspended OU
    └── Decommissioned Accounts
```

## Network Flow Example

### Production Account Makes HTTP Request:

```
Production Account VPC (10.0.0.0/16)
    ↓ (Cloud WAN prod segment)

Inspection VPC (us-east-1)
    ↓ (Network Firewall inspection)
    ↓ (Approved: logging, DNS, deep packet inspection)

NAT Gateway
    ↓
Internet Gateway
    ↓
Internet (destination: example.com)
```

### Key Points:
1. **Automatic Routing**: Cloud WAN automatically routes to nearest inspection VPC
2. **Inspection**: ALL traffic inspected by Network Firewall (no bypass)
3. **Centralized Egress**: Single set of NAT IPs for entire organization
4. **Isolation**: Production and non-production segments cannot communicate

## Cost Breakdown

### Control Tower & Governance
- **Control Tower**: $0 (free service)
- **AWS Config**: ~$2-5/account/month (compliance monitoring)
- **GuardDuty**: ~$5-10/account/month (threat detection)
- **Security Hub**: ~$1-3/account/month (security posture)

### RAM Sharing
- **RAM Service**: $0 (free)
- **Shared Resources**: Pay once in network account
  - Cloud WAN Core Network: $255/month (shared across all accounts)
  - IPAM: $18/month (shared across all accounts)

### Total Impact Per Account
- **Security Baseline**: ~$8-18/account/month
- **Network Resources**: $0 (shared via RAM)
- **Landing Zone VPC**: $0 (no NAT/IGW charges in workload accounts)

**Example**: 50 accounts
- Security: 50 × $15 = $750/month
- Networking: $273/month (Cloud WAN + IPAM, shared)
- **Total**: ~$1,023/month for entire organization

## Implementation Modules

### 1. `modules/control-tower-scps/`
Creates and manages Service Control Policies:
- Network governance (Force IPAM, block Transit Gateway, block VPC Peering)
- Region restriction
- Security baseline (prevent disabling GuardDuty, Security Hub, Config)
- VPC Flow Logs enforcement

### 2. `modules/ram-sharing/`
Manages Resource Access Manager shares:
- Cloud WAN Core Network sharing
- IPAM pool sharing (with granular OU-level control)
- Optional: Transit Gateway, Route 53 Resolver rules

### 3. `modules/control-tower-account-factory/`
Automates landing zone provisioning for new accounts:
- Landing Zone VPC with IPAM allocation
- Cloud WAN attachment (automatic segment assignment)
- VPC Flow Logs
- GuardDuty
- Security Hub (CIS + AWS Foundational benchmarks)
- AWS Config

## Deployment Workflow

### One-Time Setup (Network Account)
```bash
# Deploy in network account
cd environments/network
terraform init
terraform apply
```

This creates:
- Cloud WAN Core Network
- IPAM with regional pools
- RAM shares for Core Network and IPAM
- SCPs attached to OUs
- Inspection VPCs

### Per-Account Provisioning (Automated)
```bash
# For each new account
module "new_account" {
  source = "../../modules/control-tower-account-factory"

  account_name                   = "prod-app-1"
  environment                    = "production"
  region                         = "us-east-1"

  # IPAM pools (from network account via RAM)
  ipam_production_pool_id        = "ipam-pool-12345"
  ipam_non_production_pool_id    = "ipam-pool-67890"
  ipam_shared_services_pool_id   = "ipam-pool-abcde"

  # Cloud WAN (from network account via RAM)
  core_network_id  = "core-network-12345"
  core_network_arn = "arn:aws:networkmanager::123456789012:core-network/core-network-12345"
}
```

Result: 5-10 minutes later, account has:
- ✅ Landing Zone VPC (CIDR auto-allocated by IPAM)
- ✅ Cloud WAN attachment (automatic segment assignment)
- ✅ VPC Flow Logs enabled
- ✅ GuardDuty enabled
- ✅ Security Hub enabled
- ✅ AWS Config enabled
- ✅ Internet connectivity via centralized inspection

## Benefits Summary

| Feature | Without Control Tower | With Control Tower |
|---------|----------------------|-------------------|
| **Account Creation** | Manual, 1-2 hours | Automated, 10 minutes |
| **IP Planning** | Manual spreadsheets, conflicts common | Automatic via IPAM, zero conflicts |
| **Network Setup** | Per-account VPN/TGW/routing | Automatic Cloud WAN attachment |
| **Security Baseline** | Manual per account | Automatic (GuardDuty, Security Hub, Config) |
| **Policy Enforcement** | Hope and pray | Enforced via SCPs (cannot be bypassed) |
| **Cost** | Duplicated resources per account | Shared resources via RAM |
| **Compliance** | Per-account audits | Centralized via Log Archive |
| **Onboarding Time** | Days-weeks | Minutes |

## Security Considerations

### SCPs Are Enforced at API Level
- Even account root user cannot bypass SCPs
- Prevents "shadow IT" networking (rogue VPCs, peering, etc.)
- Ensures all traffic flows through inspection VPCs

### Least Privilege via RAM
- Accounts only get access to IPAM pools for their environment
- Production accounts cannot allocate from non-prod pools
- Core Network is shared read-only (cannot modify routing)

### Centralized Visibility
- Log Archive account receives all VPC Flow Logs
- GuardDuty findings aggregated to security account
- Security Hub provides organization-wide security posture

## Next Steps

1. **Phase 7A**: Deploy Control Tower in management account
2. **Phase 7B**: Create organizational structure (OUs)
3. **Phase 7C**: Deploy SCPs to OUs
4. **Phase 7D**: Configure RAM sharing for Core Network and IPAM
5. **Phase 7E**: Provision first workload account using account factory
6. **Phase 7F**: Validate end-to-end connectivity and compliance

## Support and Troubleshooting

### Common Issues

**Q: New account can't attach to Cloud WAN**
A: Verify RAM share accepted in member account. Check RAM console → Resource shares → Shared with me

**Q: VPC creation fails with "IPAM pool not found"**
A: RAM share not propagated yet. Wait 1-2 minutes and retry.

**Q: SCP blocking legitimate operations**
A: Add account to exempted_account_ids in SCP variables (only for infrastructure accounts)

**Q: IP address conflict**
A: Should be impossible with IPAM. Check if someone created VPC without IPAM (should be blocked by SCP)

## Conclusion

Control Tower + RAM provides:
- **Automated Governance**: SCPs enforce architecture standards
- **Cost Efficiency**: Share expensive resources (Cloud WAN, IPAM)
- **Rapid Onboarding**: New accounts production-ready in minutes
- **Security Baseline**: GuardDuty, Security Hub, Config enabled automatically
- **Zero IP Conflicts**: IPAM allocates CIDRs automatically
- **Centralized Control**: Single pane of glass for network and security

This architecture scales from 10 to 1000+ accounts with consistent governance and minimal operational overhead.
