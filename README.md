# AWS Global WAN Network Architecture

Enterprise-grade multi-account, multi-region networking infrastructure using AWS Cloud WAN with **microsegmentation**, centralized inspection, and automated compliance.

## Overview

This repository provides a complete **Zero Trust Network Architecture** for AWS using:

- **AWS Cloud WAN**: Software-defined global network with policy-based routing
- **Microsegmentation**: 12+ fine-grained network segments (PCI, API, Database, Dev/Test/Staging, Shared Services, B2B)
- **Centralized Inspection**: Network Firewall with segment-specific rules
- **IPAM**: Automated IP address management with no-overlap guarantees
- **Control Tower Integration**: Multi-account governance with Service Control Policies
- **RAM Sharing**: Share Core Network and IPAM across 100+ accounts
- **3-Tier Security**: Defense in depth (routing + security groups + firewall)

## Architecture Phases

This architecture has been built in phases, with each phase adding capabilities:

| Phase | Status | Description | Documentation |
|-------|--------|-------------|---------------|
| **Phase 1** | ✅ Complete | Core Network with basic segments | [QUICK_START.md](./QUICK_START.md) |
| **Phase 2** | ✅ Complete | IPAM with automated CIDR allocation | Integrated in modules |
| **Phase 3** | ✅ Complete | Inspection VPC with Network Firewall | [modules/inspection-vpc/](./modules/inspection-vpc/) |
| **Phase 4** | ✅ Complete | Landing Zone VPC with Cloud WAN attachment | [modules/landing-zone-vpc/](./modules/landing-zone-vpc/) |
| **Phase 5** | ✅ Complete | DNS automation with Route 53 Resolver | [modules/dns-automation/](./modules/dns-automation/) |
| **Phase 6** | ✅ Complete | Multi-region with us-east-1, us-west-2, eu-west-1 | [modules/core-network/](./modules/core-network/) |
| **Phase 7** | ✅ Complete | Control Tower + RAM for multi-account | [CONTROL_TOWER_RAM_ARCHITECTURE.md](./CONTROL_TOWER_RAM_ARCHITECTURE.md) |
| **Phase 8** | ✅ Complete | **Microsegmentation** with fine-grained isolation | [MICROSEGMENTATION_ARCHITECTURE.md](./MICROSEGMENTATION_ARCHITECTURE.md) |
| **Phase 9** | 📋 Planned | Ingress filtering with AWS WAF | [FUTURE_ROADMAP.md](./FUTURE_ROADMAP.md) |
| **Phase 10** | 📋 Planned | B2B access via Cloudflare Tunnels | [FUTURE_ROADMAP.md](./FUTURE_ROADMAP.md) |
| **Phase 11** | 📋 Planned | Per-VPC custom DNS with Route 53 | [FUTURE_ROADMAP.md](./FUTURE_ROADMAP.md) |

## Key Features

### 🔒 Zero Trust Microsegmentation (Phase 8 - NEW!)

Instead of broad prod/non-prod segments, we now have **12+ specialized segments**:

```
Production Segments:
├── prod-pci          ← PCI-DSS compliant payment processing (isolated)
├── prod-general      ← Standard production applications
├── prod-api          ← API gateway layer
└── prod-data         ← Database tier (NO internet access)

Non-Production Segments:
├── nonprod-dev       ← Development
├── nonprod-test      ← Testing/QA
└── nonprod-staging   ← Pre-production staging

Shared Services Segments:
├── shared-dns        ← Route 53 Resolver endpoints
├── shared-monitoring ← CloudWatch, Prometheus, Grafana
├── shared-security   ← GuardDuty, Security Hub
└── shared-cicd       ← Jenkins, GitLab, CodePipeline

B2B Partner Segments:
├── b2b-partners      ← External partner integrations
└── b2b-vendors       ← Vendor access (limited, audited)
```

**Benefits**:
- ✅ PCI workloads completely isolated (whitelist-only egress)
- ✅ Databases cannot access internet (even if compromised)
- ✅ Dev/test cannot accidentally reach production
- ✅ B2B partners limited to specific API endpoints
- ✅ Defense in depth: 3 layers (routing + SGs + firewall)

### 🛡️ 3-Tier Security Architecture

Every application uses a standardized 3-tier architecture:

```
Internet → ALB → Web Tier → API Tier → Database Tier
                    ↓          ↓            ↓
                  SG: ALB    SG: Web     SG: API
                  only       only        only
                                            ↓
                                         NO EGRESS
```

**Security Group Automation**:
- ALB accepts HTTPS from internet/CloudFront
- Web tier accepts from ALB only, talks to API only
- API tier accepts from Web only, talks to Database only
- Database accepts from API only, **has ZERO egress rules**

See: [modules/security-groups-3tier/](./modules/security-groups-3tier/)

### 🔥 Segment-Specific Firewall Rules

Network Firewall rules tailored to each segment:

| Segment | Firewall Action | Purpose |
|---------|----------------|---------|
| **prod-pci** | ALERT on unexpected | PCI compliance logging |
| **prod-api** | Domain allowlist | Only Stripe, Twilio, etc. |
| **prod-data** | DROP all egress | Database isolation |
| **nonprod-*** | BLOCK production CIDRs | Prevent prod access |
| **b2b-***  | ALLOW API HTTPS only | Partner isolation |
| **All** | Threat intel blocklist | Malware/phishing protection |

See: [modules/network-firewall-microsegments/](./modules/network-firewall-microsegments/)

### 💰 Cost Optimization via RAM Sharing

**Without RAM sharing** (50 accounts):
- Core Network: 50 × $255 = $12,750/month
- IPAM: 50 × $18 = $900/month
- **Total: $13,650/month**

**With RAM sharing** (Phase 7):
- Core Network: 1 × $255 = $255/month
- IPAM: 1 × $18 = $18/month
- **Total: $273/month**

**Savings: $13,377/month (98% reduction)**

See: [CONTROL_TOWER_RAM_ARCHITECTURE.md](./CONTROL_TOWER_RAM_ARCHITECTURE.md#cost-comparison)

## Quick Start

### 1. Deploy Central Networking (Networking Team)

```bash
# Initialize Terraform
terraform init

# Deploy Core Network with microsegmentation
terraform apply

# Outputs:
# - core_network_id: Use for VPC attachments
# - ipam_pool_ids: One pool per segment
# - inspection_vpc_id: Centralized firewall
```

### 2. Deploy Landing Zone (Application Team)

Choose a template based on compliance requirements:

**Option A: PCI-Compliant Application**
```bash
cd examples/microsegmented-landing-zone-pci
terraform init
terraform apply -var="app_name=payment-processor" \
                -var="global_network_id=core-network-xxxxx"
```

**Option B: General Production Application**
```bash
cd examples/microsegmented-landing-zone-general
terraform init
terraform apply -var="app_name=web-app" \
                -var="global_network_id=core-network-xxxxx"
```

See: [examples/](./examples/) for full deployment guides.

## Repository Structure

```
.
├── modules/
│   ├── core-network/                    # Phase 1: Core Network
│   ├── ipam/                            # Phase 2: IP Address Management
│   ├── inspection-vpc/                  # Phase 3: Centralized Firewall
│   ├── landing-zone-vpc/                # Phase 4: Standard VPC Template
│   ├── dns-automation/                  # Phase 5: Route 53 Resolver
│   ├── control-tower-scps/              # Phase 7: Service Control Policies
│   ├── ram-sharing/                     # Phase 7: Resource Sharing
│   ├── control-tower-account-factory/   # Phase 7: Account Provisioning
│   ├── core-network-microsegments/      # Phase 8: Microsegmentation Policy
│   ├── security-groups-3tier/           # Phase 8: Security Group Automation
│   └── network-firewall-microsegments/  # Phase 8: Segment-Specific Firewall
│
├── examples/
│   ├── microsegmented-landing-zone-pci/       # PCI-compliant app example
│   └── microsegmented-landing-zone-general/   # General production app example
│
├── QUICK_START.md                       # Getting started guide
├── CONTROL_TOWER_RAM_ARCHITECTURE.md    # Phase 7 documentation
├── MICROSEGMENTATION_ARCHITECTURE.md    # Phase 8 documentation (NEW!)
└── FUTURE_ROADMAP.md                    # Phases 9-11 roadmap
```

## Use Cases

### ✅ PCI-DSS Compliant Payment Processing

Deploy payment processing infrastructure with **complete database isolation**:

```hcl
module "payment_app" {
  source = "./examples/microsegmented-landing-zone-pci"

  app_name           = "payment-processor"
  global_network_id  = module.core_network.id
  cloudfront_cidr    = "0.0.0.0/0"  # Use CloudFront prefix list in prod
  corporate_vpn_cidr = "203.0.113.0/24"
}
```

**Compliance features**:
- ✅ Database has NO egress (even to other VPCs)
- ✅ VPC Flow Logs (90-day retention)
- ✅ Network Firewall logs all PCI traffic
- ✅ GuardDuty with malware protection
- ✅ Isolated segment with whitelist-only egress

See: [examples/microsegmented-landing-zone-pci/](./examples/microsegmented-landing-zone-pci/)

### ✅ Multi-Account SaaS Platform

Deploy SaaS platform across 50 AWS accounts with centralized networking:

```hcl
# Central networking account
module "core_network" {
  source = "./modules/core-network-microsegments"

  enable_pci_segment        = true
  enable_b2b_segments       = true
  enable_inspection_routing = true
}

# Share with organization
module "ram_sharing" {
  source = "./modules/ram-sharing"

  core_network_arn = module.core_network.core_network_arn
  share_with_organization = true
}

# Application accounts automatically get access via RAM
# Deploy landing zones using examples/microsegmented-landing-zone-*
```

See: [CONTROL_TOWER_RAM_ARCHITECTURE.md](./CONTROL_TOWER_RAM_ARCHITECTURE.md)

### ✅ B2B Partner Integrations

Allow external partners to access specific APIs without VPN:

```hcl
# Partner VPC in b2b-partners segment
# Can ONLY reach prod-api segment on port 443
# All other traffic blocked by firewall

module "partner_access" {
  source = "./modules/core-network-microsegments"

  enable_b2b_segments = true

  b2b_microsegments = {
    partners = {
      allowed_segments = ["prod-api"]  # Can only reach API tier
      no_internet      = true
    }
  }
}
```

See: [FUTURE_ROADMAP.md](./FUTURE_ROADMAP.md#phase-10-b2b-partner-access)

## Security & Compliance

### Defense in Depth

Microsegmentation enforced at **3 layers**:

1. **Layer 1: Cloud WAN Routing**
   - Segment isolation at network layer
   - No route exists between unauthorized segments
   - Enforced by AWS (cannot be bypassed)

2. **Layer 2: Security Groups**
   - Instance-level firewall
   - 3-tier architecture (ALB → Web → API → DB)
   - Database has ZERO egress rules

3. **Layer 3: Network Firewall**
   - Application-layer inspection (HTTP/TLS)
   - Domain allowlists/blocklists
   - Threat intelligence feeds

**Result**: Even if attacker compromises web server, they cannot:
- ❌ Reach database (security group blocks it)
- ❌ Reach PCI segment (no Cloud WAN route)
- ❌ Exfiltrate to internet (firewall blocks it)

### Compliance Frameworks

| Framework | Status | Evidence |
|-----------|--------|----------|
| **PCI-DSS** | ✅ Supported | VPC Flow Logs, Network Firewall logs, database isolation |
| **SOC 2** | ✅ Supported | Automated audit trails, centralized logging |
| **HIPAA** | ⚠️ Partial | Requires additional PHI encryption controls |
| **FedRAMP** | ⚠️ Partial | Requires GovCloud deployment |

See: [MICROSEGMENTATION_ARCHITECTURE.md](./MICROSEGMENTATION_ARCHITECTURE.md#compliance-automation)

## Cost Breakdown

**Central Networking (one-time setup)**:

| Component | Monthly Cost |
|-----------|--------------|
| Core Network (3 regions) | $255 |
| IPAM (3 pools) | $18 |
| Inspection VPC (Network Firewall) | $395 |
| Route 53 Resolver (2 endpoints) | $0.50 |
| **Total** | **$668.50/month** |

**Per-Application Cost** (using landing zone templates):

| Component | Monthly Cost |
|-----------|--------------|
| VPC (no charge) | $0 |
| Cloud WAN Attachment | $255 |
| NAT Gateway (optional) | $32 |
| VPC Flow Logs | ~$5-10 |
| **Total** | **$260-297/month** |

**Scaling**: 50 applications = $668 (central) + (50 × $260) = **$13,668/month**

**Alternative** (without Cloud WAN): 50 VPCs × $395 (firewall) = **$19,750/month**

**Savings: $6,082/month (31% reduction)**

See: [MICROSEGMENTATION_ARCHITECTURE.md](./MICROSEGMENTATION_ARCHITECTURE.md#cost-impact)

## Prerequisites

### AWS Account Setup

- **Permissions**: IAM role with network admin permissions
- **Control Tower**: Enabled with organizational units configured
- **OIDC**: HCP Terraform workspace configured with OIDC
- **Regions**: us-east-1 (primary), us-west-2, eu-west-1

### Terraform

- Terraform >= 1.5.0
- AWS Provider ~> 5.0

### HCP Terraform

- **Workspace**: aws-global-wan
- **Organization**: vitalemazo
- **Auto-apply**: Enabled
- **IAM Role**: hcp-oidc-role-aws-oidc-demo

## Documentation

- **[QUICK_START.md](./QUICK_START.md)** - Getting started with basic deployment
- **[CONTROL_TOWER_RAM_ARCHITECTURE.md](./CONTROL_TOWER_RAM_ARCHITECTURE.md)** - Multi-account governance (Phase 7)
- **[MICROSEGMENTATION_ARCHITECTURE.md](./MICROSEGMENTATION_ARCHITECTURE.md)** - Fine-grained isolation (Phase 8)
- **[FUTURE_ROADMAP.md](./FUTURE_ROADMAP.md)** - Planned features (Phases 9-11)

## Examples

- **[examples/microsegmented-landing-zone-pci/](./examples/microsegmented-landing-zone-pci/)** - PCI-compliant application
- **[examples/microsegmented-landing-zone-general/](./examples/microsegmented-landing-zone-general/)** - General production application

## Resources

- [AWS Cloud WAN Documentation](https://docs.aws.amazon.com/vpc/latest/cloudwan/)
- [AWS Network Firewall Documentation](https://docs.aws.amazon.com/network-firewall/)
- [AWS IPAM Documentation](https://docs.aws.amazon.com/vpc/latest/ipam/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [PCI-DSS Requirements](https://www.pcisecuritystandards.org/)
