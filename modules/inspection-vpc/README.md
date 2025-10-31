# Inspection VPC Module

## Overview

This module creates an inspection VPC with AWS Network Firewall and NAT Gateway for centralized network inspection and internet egress. Designed for use with AWS Cloud WAN for multi-region, multi-segment network architectures.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Inspection VPC (e.g., 10.1.0.0/16)                          │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐│
│  │ Public Subnet  │  │Firewall Subnet │  │Attach. Subnet  ││
│  │ (NAT Gateway)  │  │(Network FW)    │  │(Cloud WAN)     ││
│  │ 10.1.0.0/24   │  │ 10.1.1.0/24    │  │ 10.1.2.0/24    ││
│  └────────┬───────┘  └────────┬───────┘  └────────┬───────┘│
│           │                   │                    │         │
│        ┌──┴──┐            ┌───┴────┐          ┌───┴────┐   │
│        │ NAT │            │  NFW   │          │Cloud   │   │
│        │ GW  │            │Endpoint│          │WAN     │   │
│        └──┬──┘            └───┬────┘          │Attach  │   │
│           │                   │               └───┬────┘   │
│       ┌───┴────┐              │                   │         │
│       │  IGW   │◄─────────────┘                   │         │
│       └────────┘                                  │         │
└──────────┬─────────────────────────────────────┬──┘         │
           │                                     │            │
        Internet                          Cloud WAN          │
                                         Core Network         │
```

## Traffic Flow

### Outbound Internet Traffic (from Cloud WAN workloads)
1. Workload VPC → Cloud WAN Core Network
2. Core Network → Inspection VPC (Attachment Subnet)
3. Attachment Subnet → Network Firewall (inspection)
4. Network Firewall → Firewall Subnet → NAT Gateway
5. NAT Gateway → Public Subnet → Internet Gateway
6. Internet Gateway → Internet

### Inter-Segment Traffic
1. Source Segment → Cloud WAN Core Network
2. Core Network → Inspection VPC (Attachment Subnet)
3. Attachment Subnet → Network Firewall (inspection)
4. Network Firewall → Firewall Subnet → Cloud WAN
5. Cloud WAN → Destination Segment

## Features

- **Single-AZ Deployment**: Cost-optimized for lab environments
- **AWS Network Firewall**: Stateful traffic inspection
- **NAT Gateway**: Centralized internet egress
- **Cloud WAN Integration**: Automatic attachment with network function group tagging
- **Flexible Routing**: Complete route table configuration for all traffic flows
- **Optional Logging**: S3-based firewall logging with lifecycle policies

## Usage

### Basic Example

```hcl
module "inspection_vpc_useast1" {
  source = "../../modules/inspection-vpc"

  vpc_name   = "useast1-inspection"
  region     = "us-east-1"
  vpc_cidr   = "10.1.0.0/16"

  public_subnet_cidr     = "10.1.0.0/24"
  firewall_subnet_cidr   = "10.1.1.0/24"
  attachment_subnet_cidr = "10.1.2.0/24"

  core_network_id  = module.core_network.core_network_id
  core_network_arn = module.core_network.core_network_arn

  tags = {
    Environment = "dev"
    Region      = "us-east-1"
    Phase       = "2-InspectionVPC"
  }
}
```

### With Firewall Logging Enabled

```hcl
module "inspection_vpc_uswest2" {
  source = "../../modules/inspection-vpc"

  vpc_name   = "uswest2-inspection"
  region     = "us-west-2"
  vpc_cidr   = "10.2.0.0/16"

  public_subnet_cidr     = "10.2.0.0/24"
  firewall_subnet_cidr   = "10.2.1.0/24"
  attachment_subnet_cidr = "10.2.2.0/24"

  core_network_id  = module.core_network.core_network_id
  core_network_arn = module.core_network.core_network_arn

  # Enable logging
  enable_firewall_logging = true

  # Specify AZ
  availability_zone = "us-west-2a"

  tags = {
    Environment = "dev"
    Region      = "us-west-2"
    Phase       = "3-SecondRegion"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Required Providers

- `hashicorp/aws` - AWS provider for resource creation
- `hashicorp/time` - Time provider for wait conditions

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| vpc_name | Name for the inspection VPC | string | yes | - |
| region | AWS region for deployment | string | yes | - |
| vpc_cidr | VPC CIDR block | string | yes | - |
| public_subnet_cidr | Public subnet CIDR | string | yes | - |
| firewall_subnet_cidr | Firewall subnet CIDR | string | yes | - |
| attachment_subnet_cidr | Attachment subnet CIDR | string | yes | - |
| core_network_id | Cloud WAN Core Network ID | string | yes | - |
| core_network_arn | Cloud WAN Core Network ARN | string | yes | - |
| availability_zone | Specific AZ (empty for auto) | string | no | "" |
| segment_name | Cloud WAN segment name | string | no | "shared" |
| network_function_group_name | Network function group | string | no | "inspection" |
| enable_firewall_logging | Enable firewall logging | bool | no | false |
| tags | Additional resource tags | map(string) | no | {} |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | Inspection VPC ID |
| vpc_arn | Inspection VPC ARN |
| nat_gateway_public_ip | Public IP of NAT Gateway |
| firewall_id | Network Firewall ID |
| firewall_endpoint_id | Firewall endpoint for routing |
| cloudwan_attachment_id | Cloud WAN attachment ID |
| deployment_summary | Complete deployment summary |

## Resources Created

### Networking
- 1 VPC
- 3 Subnets (public, firewall, attachment)
- 1 Internet Gateway
- 1 NAT Gateway
- 1 Elastic IP
- 4 Route Tables (public, firewall, attachment, IGW edge)

### Security
- 1 AWS Network Firewall
- 1 Firewall Policy
- 1 Firewall Rule Group
- 1 S3 Bucket for logs (if enabled)

### Cloud WAN
- 1 VPC Attachment

## Cost Estimate (per region)

| Resource | Quantity | Monthly Cost |
|----------|----------|--------------|
| Network Firewall | 1 | ~$378 |
| Network Firewall (data processing) | - | ~$30 |
| NAT Gateway | 1 | ~$32 |
| NAT Gateway (data processing) | - | ~$9 |
| S3 (logs, if enabled) | 1 | ~$5 |
| **Total** | - | **~$430-$454/month** |

*Costs based on us-east-1 pricing, low traffic volume (100GB/month)*

## Deployment Time

- Initial Apply: ~10-15 minutes
- Network Firewall creation: ~8-10 minutes
- Cloud WAN attachment: ~2-3 minutes
- Route propagation: ~1-2 minutes

## Dependencies

This module requires:
1. AWS Cloud WAN Core Network (from core-network module)
2. Core Network policy with network function group configured
3. AWS provider with appropriate permissions

## Important Notes

### Single-AZ Design
This module deploys all resources in a single Availability Zone for cost optimization. For production use, consider:
- Multiple AZs for high availability
- Multiple NAT Gateways (one per AZ)
- Network Firewall endpoints in multiple subnets

### Firewall Rules
The default firewall policy allows ALL traffic for lab environments. For production:
- Implement specific allow/deny rules
- Add domain filtering
- Configure IPS/IDS rules
- Enable TLS inspection

### Logging Costs
Enabling firewall logging adds ~$5-10/month in S3 costs. Logs are automatically deleted after 30 days via lifecycle policy.

### Network Function Group
The `network-function` tag on the Cloud WAN attachment enables inspection routing. Ensure your Core Network policy includes:
```hcl
segment-actions = [
  {
    action = "send-via"
    segment = "*"
    mode = "attachment-route"
    via = {
      network-function-groups = ["inspection"]
    }
  }
]
```

## Troubleshooting

### Firewall Endpoint Not Available
**Issue**: Routes to firewall endpoint fail during creation

**Solution**:
- Network Firewall takes 8-10 minutes to create
- Endpoint ID becomes available after firewall is ready
- Dependencies are configured automatically
- Wait for `terraform apply` to complete

### Cloud WAN Attachment Pending
**Issue**: Attachment stays in "PENDING_ATTACHMENT_ACCEPTANCE" state

**Solution**:
- Set `require_attachment_acceptance = false` in Core Network module
- Or manually accept attachment in AWS Console

### Routes Not Propagating
**Issue**: Traffic not flowing through inspection VPC

**Solution**:
1. Verify `network-function` tag on attachment
2. Check Core Network policy has `send-via` segment actions
3. Wait 2-3 minutes for route propagation
4. Use VPC Reachability Analyzer to troubleshoot

## Examples

See the `environments/dev` directory for complete deployment examples.

## Module Structure

```
inspection-vpc/
├── main.tf                    # VPC, subnets, IGW
├── nat-gateway.tf             # NAT Gateway and EIP
├── network-firewall.tf        # AWS Network Firewall
├── cloudwan-attachment.tf     # Cloud WAN integration
├── route-tables.tf            # All route tables
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
└── README.md                  # This file
```

## Related Documentation

- [AWS Cloud WAN](https://docs.aws.amazon.com/vpc/latest/cloudwan/)
- [AWS Network Firewall](https://docs.aws.amazon.com/network-firewall/)
- [Centralized Inspection Architecture](https://aws.amazon.com/blogs/networking-and-content-delivery/deployment-models-for-aws-network-firewall/)

## Version History

- **v1.0.0** (Phase 2) - Initial release with single-AZ deployment
