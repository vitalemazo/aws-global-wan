# AWS IPAM and Control Tower Integration Design

## Executive Summary

This design integrates AWS IPAM (IP Address Management) for centralized CIDR allocation and AWS Control Tower for enterprise-grade account governance and landing zone deployment.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ AWS Organization (Control Tower)                             │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Management Account                                    │   │
│  │ • Control Tower Setup                                 │   │
│  │ • IPAM Delegated Administrator                        │   │
│  │ • Service Control Policies (SCPs)                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Network Account (Shared Services)                     │   │
│  │ ┌──────────────────────────────────────────────────┐ │   │
│  │ │ AWS IPAM                                         │ │   │
│  │ │ ┌────────────────────────────────────────────┐   │ │   │
│  │ │ │ IPAM Scope: Private                        │   │ │   │
│  │ │ │                                            │   │ │   │
│  │ │ │ ┌─────────────────┐  ┌──────────────────┐ │   │ │   │
│  │ │ │ │ Production Pool │  │ Non-Prod Pool    │ │   │ │   │
│  │ │ │ │ 10.0.0.0/8      │  │ 172.16.0.0/12    │ │   │ │   │
│  │ │ │ └─────────────────┘  └──────────────────┘ │   │ │   │
│  │ │ │ ┌─────────────────┐  ┌──────────────────┐ │   │ │   │
│  │ │ │ │ Shared Services │  │ Inspection       │ │   │ │   │
│  │ │ │ │ 192.168.0.0/16  │  │ 100.64.0.0/16    │ │   │ │   │
│  │ │ │ └─────────────────┘  └──────────────────┘ │   │ │   │
│  │ │ └────────────────────────────────────────────┘   │ │   │
│  │ └──────────────────────────────────────────────────┘ │   │
│  │                                                        │   │
│  │ • Cloud WAN Core Network                              │   │
│  │ • Transit Gateway (optional)                          │   │
│  │ • Route 53 Resolver                                   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Workload Accounts (Control Tower Managed)             │   │
│  │                                                        │   │
│  │ ┌────────────────┐  ┌────────────────┐               │   │
│  │ │ Prod Account 1 │  │ Prod Account 2 │               │   │
│  │ │ IPAM: 10.x.x.x │  │ IPAM: 10.y.y.y │               │   │
│  │ │ OU: Production │  │ OU: Production │               │   │
│  │ └────────────────┘  └────────────────┘               │   │
│  │                                                        │   │
│  │ ┌────────────────┐  ┌────────────────┐               │   │
│  │ │NonProd Acct 1  │  │NonProd Acct 2  │               │   │
│  │ │ IPAM: 172.x.x.x│  │ IPAM: 172.y.y.y│               │   │
│  │ │ OU: NonProd    │  │ OU: NonProd    │               │   │
│  │ └────────────────┘  └────────────────┘               │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

## AWS IPAM Design

### IPAM Hierarchy

```
IPAM
├── Operating Region: us-east-1 (primary)
├── Operating Region: us-west-2 (secondary)
│
├── Scope: Private (RFC1918)
│   ├── Top-Level Pool: 10.0.0.0/8 (Production)
│   │   ├── Regional Pool: 10.0.0.0/12 (us-east-1 prod)
│   │   ├── Regional Pool: 10.16.0.0/12 (us-west-2 prod)
│   │   └── Regional Pool: 10.32.0.0/12 (us-east-2 prod)
│   │
│   ├── Top-Level Pool: 172.16.0.0/12 (Non-Production)
│   │   ├── Regional Pool: 172.16.0.0/14 (us-east-1 non-prod)
│   │   ├── Regional Pool: 172.20.0.0/14 (us-west-2 non-prod)
│   │   └── Regional Pool: 172.24.0.0/14 (us-east-2 non-prod)
│   │
│   ├── Top-Level Pool: 192.168.0.0/16 (Shared Services)
│   │   ├── Regional Pool: 192.168.0.0/18 (us-east-1 shared)
│   │   ├── Regional Pool: 192.168.64.0/18 (us-west-2 shared)
│   │   └── Regional Pool: 192.168.128.0/18 (us-east-2 shared)
│   │
│   └── Top-Level Pool: 100.64.0.0/16 (Inspection/CGNAT)
│       ├── Regional Pool: 100.64.0.0/18 (us-east-1 inspection)
│       ├── Regional Pool: 100.64.64.0/18 (us-west-2 inspection)
│       └── Regional Pool: 100.64.128.0/18 (us-east-2 inspection)
│
└── Scope: Public (future, for internet-facing resources)
```

### IPAM Pool Allocation Strategy

| Pool Type | CIDR Range | Purpose | Min Size | Max Size |
|-----------|------------|---------|----------|----------|
| Production | 10.0.0.0/8 | Prod workloads | /24 | /16 |
| Non-Production | 172.16.0.0/12 | Dev/Test/Staging | /24 | /16 |
| Shared Services | 192.168.0.0/16 | DNS, AD, monitoring | /24 | /20 |
| Inspection | 100.64.0.0/16 | Network Firewall, NAT | /20 | /16 |

### IPAM Resource Allocation Rules

```hcl
# Automatic allocation constraints
allocation_rules = {
  production = {
    min_netmask_length = 24  # Minimum VPC size: /24
    max_netmask_length = 16  # Maximum VPC size: /16
    default_netmask_length = 20  # Default: /20 (4096 IPs)
  }

  non_production = {
    min_netmask_length = 24
    max_netmask_length = 18
    default_netmask_length = 22  # Default: /22 (1024 IPs)
  }

  shared_services = {
    min_netmask_length = 24
    max_netmask_length = 20
    default_netmask_length = 24  # Default: /24 (256 IPs)
  }

  inspection = {
    min_netmask_length = 20
    max_netmask_length = 16
    default_netmask_length = 20  # Default: /20 (4096 IPs)
  }
}
```

### IPAM Tagging Strategy

```hcl
required_tags = {
  "Environment"     = ["production", "non-production", "shared", "inspection"]
  "CostCenter"      = [".*"]  # Any value required
  "Owner"           = [".*"]  # Any value required
  "CloudWAN:Segment" = ["prod", "non-prod", "shared", "inspection"]
}
```

## AWS Control Tower Integration

### Organizational Units (OUs)

```
Root
├── Security
│   ├── Log Archive Account
│   └── Audit Account
│
├── Infrastructure
│   ├── Network Account (Shared Services)
│   │   ├── Cloud WAN Core Network
│   │   ├── IPAM (Delegated Admin)
│   │   ├── Route 53 Resolver
│   │   └── Inspection VPCs
│   └── Shared Services Account
│       ├── Active Directory
│       ├── Monitoring/Observability
│       └── Backup Services
│
├── Workloads
│   ├── Production OU
│   │   ├── Prod App 1 Account
│   │   ├── Prod App 2 Account
│   │   └── [...]
│   │
│   ├── Non-Production OU
│   │   ├── Dev Account
│   │   ├── Test Account
│   │   ├── Staging Account
│   │   └── [...]
│   │
│   └── Sandbox OU
│       └── Developer Sandbox Accounts
│
└── Suspended
    └── Decommissioned Accounts
```

### Control Tower Account Factory Integration

#### Account Provisioning Workflow

```
1. Request New Account (Service Catalog)
   ↓
2. Control Tower Creates Account
   ↓
3. Account placed in designated OU
   ↓
4. SCPs automatically applied
   ↓
5. IPAM allocates CIDR from appropriate pool
   ↓
6. Landing Zone VPC created with IPAM CIDR
   ↓
7. VPC attached to Cloud WAN (segment-based)
   ↓
8. Baseline resources deployed:
   - VPC Flow Logs → CloudWatch
   - GuardDuty enabled
   - Security Hub enabled
   - Config Rules applied
   ↓
9. Account ready for workload deployment
```

### Service Control Policies (SCPs)

#### 1. Network Governance SCP

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyVPCCreationWithoutIPAM",
      "Effect": "Deny",
      "Action": "ec2:CreateVpc",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "ec2:Ipv4IpamPoolId": "${var.ipam_pool_id}"
        }
      }
    },
    {
      "Sid": "DenyNonCloudWANTransitGateway",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateTransitGateway",
        "ec2:CreateTransitGatewayVpcAttachment"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyVPCPeering",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateVpcPeeringConnection",
        "ec2:AcceptVpcPeeringConnection"
      ],
      "Resource": "*"
    },
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
          "aws:PrincipalOrgID": "${var.network_account_id}"
        }
      }
    }
  ]
}
```

#### 2. Region Restriction SCP

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllOutsideAllowedRegions",
      "Effect": "Deny",
      "NotAction": [
        "cloudfront:*",
        "iam:*",
        "route53:*",
        "support:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "us-east-1",
            "us-west-2",
            "us-east-2"
          ]
        }
      }
    }
  ]
}
```

## Implementation Architecture

### Phase 6A: IPAM Setup

```hcl
# modules/ipam/main.tf
resource "aws_vpc_ipam" "main" {
  description = "Centralized IP Address Management"

  operating_regions {
    region_name = "us-east-1"
  }

  operating_regions {
    region_name = "us-west-2"
  }

  operating_regions {
    region_name = "us-east-2"
  }

  tags = {
    Name = "global-wan-ipam"
  }
}

# Private scope for RFC1918
resource "aws_vpc_ipam_scope" "private" {
  ipam_id     = aws_vpc_ipam.main.id
  description = "Private RFC1918 address space"

  tags = {
    Name = "private-scope"
  }
}

# Top-level pools
resource "aws_vpc_ipam_pool" "production" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam_scope.private.id
  locale         = "None"  # Top-level pool

  cidr {
    cidr = "10.0.0.0/8"
  }

  allocation_min_netmask_length = 16
  allocation_max_netmask_length = 24
  allocation_default_netmask_length = 20

  auto_import = true

  tags = {
    Name        = "production-pool"
    Environment = "production"
  }
}

resource "aws_vpc_ipam_pool" "non_production" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam_scope.private.id
  locale         = "None"

  cidr {
    cidr = "172.16.0.0/12"
  }

  allocation_min_netmask_length = 18
  allocation_max_netmask_length = 24
  allocation_default_netmask_length = 22

  auto_import = true

  tags = {
    Name        = "non-production-pool"
    Environment = "non-production"
  }
}

resource "aws_vpc_ipam_pool" "shared_services" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam_scope.private.id
  locale         = "None"

  cidr {
    cidr = "192.168.0.0/16"
  }

  allocation_min_netmask_length = 20
  allocation_max_netmask_length = 24
  allocation_default_netmask_length = 24

  tags = {
    Name        = "shared-services-pool"
    Environment = "shared"
  }
}

resource "aws_vpc_ipam_pool" "inspection" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam_scope.private.id
  locale         = "None"

  cidr {
    cidr = "100.64.0.0/16"  # CGNAT range, good for inspection
  }

  allocation_min_netmask_length = 16
  allocation_max_netmask_length = 20
  allocation_default_netmask_length = 20

  tags = {
    Name        = "inspection-pool"
    Environment = "inspection"
  }
}

# Regional pools (example for us-east-1)
resource "aws_vpc_ipam_pool" "production_useast1" {
  address_family      = "ipv4"
  ipam_scope_id       = aws_vpc_ipam_scope.private.id
  locale              = "us-east-1"
  source_ipam_pool_id = aws_vpc_ipam_pool.production.id

  cidr {
    cidr = "10.0.0.0/12"
  }

  tags = {
    Name        = "production-useast1-pool"
    Environment = "production"
    Region      = "us-east-1"
  }
}
```

### Phase 6B: Control Tower Account Factory

```hcl
# modules/control-tower-account/main.tf
resource "aws_servicecatalog_provisioned_product" "account" {
  name                       = var.account_name
  product_name              = "AWS Control Tower Account Factory"
  provisioning_artifact_name = "AWS Control Tower Account Factory"

  provisioning_parameters {
    key   = "AccountName"
    value = var.account_name
  }

  provisioning_parameters {
    key   = "AccountEmail"
    value = var.account_email
  }

  provisioning_parameters {
    key   = "ManagedOrganizationalUnit"
    value = var.organizational_unit
  }

  provisioning_parameters {
    key   = "SSOUserFirstName"
    value = var.sso_user_first_name
  }

  provisioning_parameters {
    key   = "SSOUserLastName"
    value = var.sso_user_last_name
  }

  provisioning_parameters {
    key   = "SSOUserEmail"
    value = var.sso_user_email
  }

  tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Type      = "ControlTowerAccount"
  })
}

# Wait for account creation
resource "time_sleep" "wait_for_account" {
  create_duration = "120s"

  depends_on = [aws_servicecatalog_provisioned_product.account]
}

# Get account ID
data "aws_organizations_organization" "main" {}

data "aws_organizations_account" "created" {
  name = var.account_name

  depends_on = [time_sleep.wait_for_account]
}
```

### Phase 6C: Landing Zone with IPAM and Control Tower

```hcl
# modules/landing-zone-vpc-ipam/main.tf
resource "aws_vpc" "landing_zone" {
  ipv4_ipam_pool_id   = var.ipam_pool_id
  ipv4_netmask_length = var.netmask_length

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name              = var.vpc_name
    Segment           = var.segment_name
    "CloudWAN:Segment" = var.segment_name
    ManagedBy         = "Terraform"
    IPAMManaged       = "true"
    ControlTowerManaged = "true"
  })

  lifecycle {
    ignore_changes = [
      cidr_block  # IPAM manages this
    ]
  }
}

# Subnets also use IPAM pools
resource "aws_subnet" "private" {
  count = local.az_count

  vpc_id            = aws_vpc.landing_zone.id
  cidr_block        = cidrsubnet(aws_vpc.landing_zone.cidr_block, 4, count.index)
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name        = "${var.vpc_name}-private-${local.azs[count.index]}"
    Type        = "private"
    IPAMManaged = "true"
  })
}
```

## Control Tower Customizations

### Account Baseline (CloudFormation StackSet)

```yaml
# control-tower-customizations/baseline/vpc-flow-logs.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Enable VPC Flow Logs for all VPCs

Resources:
  VPCFlowLogRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: vpc-flow-logs.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/CloudWatchLogsFullAccess

  VPCFlowLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: /aws/vpc/flowlogs
      RetentionInDays: 30

  VPCFlowLog:
    Type: AWS::EC2::FlowLog
    Properties:
      ResourceType: VPC
      ResourceIds:
        - !Ref VPC
      TrafficType: ALL
      LogDestinationType: cloud-watch-logs
      LogGroupName: !Ref VPCFlowLogGroup
      DeliverLogsPermissionArn: !GetAtt VPCFlowLogRole.Arn
```

## Benefits of IPAM + Control Tower Integration

### IPAM Benefits

1. **Centralized IP Management**
   - No more spreadsheet tracking
   - Automatic CIDR allocation
   - Prevents IP conflicts

2. **Compliance & Governance**
   - Enforced allocation rules
   - Required tagging
   - Audit trail of all allocations

3. **Multi-Region & Multi-Account**
   - Consistent addressing across organization
   - Regional pool isolation
   - Cross-account visibility

4. **Automation**
   - VPCs request CIDRs from pools
   - No manual CIDR calculation
   - Auto-reclamation of unused space

### Control Tower Benefits

1. **Account Governance**
   - Automated account provisioning
   - Guardrails via SCPs
   - Centralized logging and auditing

2. **Landing Zone Automation**
   - Baseline configurations
   - Network connectivity
   - Security controls

3. **Multi-Account Strategy**
   - Workload isolation
   - Blast radius containment
   - Cost allocation by account

4. **Compliance**
   - Pre-configured security controls
   - AWS Config Rules
   - Centralized audit logging

## Implementation Plan

### Phase 6A: IPAM Foundation (Week 1)
1. Deploy IPAM in Network Account
2. Create IPAM scopes and top-level pools
3. Create regional pools for each region
4. Share IPAM pools with organization

### Phase 6B: Convert Existing VPCs (Week 2)
1. Import existing inspection VPCs to IPAM
2. Import existing landing zone VPCs to IPAM
3. Verify CIDR allocations
4. Test IPAM-based VPC creation

### Phase 6C: Control Tower Setup (Week 3)
1. Enable Control Tower (if not already)
2. Configure OUs and SCPs
3. Set up Account Factory
4. Deploy baseline StackSets

### Phase 6D: Integration (Week 4)
1. Update landing-zone module for IPAM
2. Create Control Tower account provisioning workflow
3. Test end-to-end account creation
4. Document runbooks

## Cost Considerations

| Service | Monthly Cost |
|---------|--------------|
| AWS IPAM | $0 (no charge for IPAM itself) |
| IPAM CIDRs monitored | $0.00001 per IP per month * IPs |
| Control Tower | $0 (uses underlying services) |
| **Estimated IPAM cost** | **~$10-50/month** (depending on IP count) |

## Next Steps

Would you like me to:
1. Implement the IPAM module?
2. Update existing modules to use IPAM?
3. Create Control Tower account factory module?
4. Set up SCPs for network governance?
5. All of the above?
