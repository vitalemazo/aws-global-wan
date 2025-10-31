# Core Network Module

## Overview

This module creates the AWS Cloud WAN Global Network and Core Network with multi-segment architecture. It serves as the foundation for all network connectivity across regions.

## Features

- Global Network for worldwide reach
- Core Network with 3 segments (prod, non-prod, shared)
- Network policies for routing and segmentation
- Support for future Direct Connect Gateway attachments
- Inspection VPC routing via network function groups

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│ Global Network                                           │
│ ├── Core Network (Policy-based routing)                 │
│ │   ├── Segment: Production (prod)                      │
│ │   │   └── Isolated, inspect all traffic               │
│ │   ├── Segment: Non-Production (non-prod)             │
│ │   │   └── Isolated, inspect all traffic               │
│ │   └── Segment: Shared Services (shared)              │
│ │       └── Accessible from prod & non-prod             │
│ └── Attachments (Future Phases)                         │
│     ├── VPC Attachments (Inspection & Landing Zones)    │
│     ├── Direct Connect Gateway (On-prem connectivity)   │
│     └── VPN Attachments (Branch offices)                │
└──────────────────────────────────────────────────────────┘
```

## Segment Strategy

### Production Segment
- **CIDR**: 10.0.0.0/8
- **Isolation**: Full isolation from non-prod
- **Inspection**: All traffic routed through inspection VPC
- **Use Case**: Production workloads, customer-facing applications

### Non-Production Segment
- **CIDR**: 172.16.0.0/12
- **Isolation**: Full isolation from prod
- **Inspection**: All traffic routed through inspection VPC
- **Use Case**: Dev, test, staging environments

### Shared Services Segment
- **CIDR**: 192.168.0.0/16
- **Isolation**: Accessible from both prod and non-prod
- **Inspection**: All traffic routed through inspection VPC
- **Use Case**: DNS, AD, logging, monitoring, shared tools

## Network Policy Highlights

The Core Network policy implements:

1. **Segment Attachments**: VPCs attach to specific segments based on tags
2. **Segment Actions**: Traffic routing rules between segments
3. **Network Function Groups**: Inspection VPC group for security
4. **Attachment Policies**: Automatic acceptance for trusted accounts

## Direct Connect Integration (Future)

This module supports future Direct Connect Gateway attachments for hybrid connectivity:

```
On-Premises Network
  → Direct Connect
  → Direct Connect Gateway
  → Cloud WAN Core Network Attachment
  → Segments (based on policy)
```

### Planned DX Architecture
- Single Direct Connect Gateway for all on-prem connectivity
- Attach to shared segment for centralized access
- Route on-prem traffic through inspection VPCs
- BGP for dynamic routing

## Usage

### Basic Deployment

```hcl
module "core_network" {
  source = "../../modules/core-network"

  global_network_name = "my-global-wan"
  core_network_name   = "my-core-network"

  regions = [
    "us-east-1",
    "us-west-2",
    "us-east-2"
  ]

  segments = {
    prod = {
      cidr_blocks = ["10.0.0.0/8"]
      isolate     = true
      description = "Production segment for customer workloads"
    }
    non-prod = {
      cidr_blocks = ["172.16.0.0/12"]
      isolate     = true
      description = "Non-production development and testing"
    }
    shared = {
      cidr_blocks = ["192.168.0.0/16"]
      isolate     = false
      description = "Shared services accessible from all segments"
    }
  }

  inspection_vpc_cidrs = {
    "us-east-1" = "10.1.0.0/16"
    "us-west-2" = "10.2.0.0/16"
    "us-east-2" = "10.3.0.0/16"
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "GlobalWAN"
  }
}
```

### Advanced Configuration with Inspection Routing

```hcl
module "core_network" {
  source = "../../modules/core-network"

  # ... basic config ...

  # Enable inspection for all segments
  enable_inspection_routing = true

  # Network function group for inspection VPCs
  inspection_vpc_attachment_ids = [
    # Added in Phase 2
  ]

  # Require manual attachment acceptance
  require_attachment_acceptance = false

  # Enable edge locations (for global reach)
  edge_locations = ["us-east-1", "us-west-2"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| global_network_name | Name of the Global Network | `string` | n/a | yes |
| core_network_name | Name of the Core Network | `string` | n/a | yes |
| regions | List of AWS regions for the Core Network | `list(string)` | n/a | yes |
| segments | Map of network segments | `map(object)` | n/a | yes |
| inspection_vpc_cidrs | Map of region to inspection VPC CIDR | `map(string)` | `{}` | no |
| enable_inspection_routing | Route all traffic through inspection | `bool` | `true` | no |
| require_attachment_acceptance | Require manual approval for attachments | `bool` | `false` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| global_network_id | ID of the Global Network |
| global_network_arn | ARN of the Global Network |
| core_network_id | ID of the Core Network |
| core_network_arn | ARN of the Core Network |
| core_network_policy_document | The network policy as JSON |
| segment_names | List of segment names |

## Network Policy Structure

The module generates a policy similar to:

```json
{
  "version": "2021.12",
  "core-network-configuration": {
    "vpn-ecmp-support": false,
    "asn-ranges": ["64512-64555"],
    "edge-locations": [
      {"location": "us-east-1"},
      {"location": "us-west-2"}
    ]
  },
  "segments": [
    {
      "name": "prod",
      "require-attachment-acceptance": false,
      "isolate-attachments": true,
      "edge-locations": ["us-east-1", "us-west-2"]
    },
    {
      "name": "non-prod",
      "require-attachment-acceptance": false,
      "isolate-attachments": true,
      "edge-locations": ["us-east-1", "us-west-2"]
    },
    {
      "name": "shared",
      "require-attachment-acceptance": false,
      "isolate-attachments": false,
      "edge-locations": ["us-east-1", "us-west-2"]
    }
  ],
  "segment-actions": [
    {
      "action": "send-via",
      "segment": "prod",
      "mode": "attachment-route",
      "when-sent-to": {"segments": ["*"]},
      "via": {
        "network-function-groups": ["inspection"]
      }
    }
  ],
  "attachment-policies": [
    {
      "rule-number": 100,
      "condition-logic": "or",
      "conditions": [
        {"type": "tag-value", "key": "segment", "value": "prod"}
      ],
      "action": {
        "association-method": "tag",
        "segment": "prod"
      }
    }
  ]
}
```

## Cost

**Phase 1 Only:**
- Global Network: No charge
- Core Network: ~$0.35/hour = ~$255/month
- No attachments yet (added in later phases)

**Estimated: $255/month**

## Dependencies

None - this is the foundation module.

## Deployment Order

1. **Phase 1**: Deploy this module first
2. **Phase 2**: Add inspection VPCs and attachments
3. **Phase 3**: Add landing zone VPCs
4. **Phase 4**: Add Direct Connect Gateway (optional)

## Validation

After deployment, verify:

```bash
# List Global Networks
aws networkmanager describe-global-networks

# Get Core Network details
aws networkmanager get-core-network \
  --core-network-id <core-network-id>

# View policy
aws networkmanager get-core-network-policy \
  --core-network-id <core-network-id>

# Check segments
aws networkmanager list-core-network-policy-versions \
  --core-network-id <core-network-id>
```

## Troubleshooting

### Policy Validation Errors
If policy fails to apply:
1. Check JSON syntax
2. Verify segment names match attachment tags
3. Ensure CIDR blocks don't overlap
4. Check region availability for Cloud WAN

### Segment Attachment Issues
If VPCs won't attach:
1. Verify tag-based attachment rules
2. Check `require-attachment-acceptance` setting
3. Ensure VPC CIDR is within segment CIDR range
4. Verify IAM permissions for Cloud WAN

## References

- [AWS Cloud WAN Documentation](https://docs.aws.amazon.com/vpc/latest/cloudwan/)
- [Network Policy Reference](https://docs.aws.amazon.com/vpc/latest/cloudwan/cloudwan-policy-change-sets.html)
- [Direct Connect Integration](https://aws.amazon.com/blogs/networking-and-content-delivery/simplify-global-hybrid-connectivity-with-aws-cloud-wan-and-aws-direct-connect-integration/)
- [Terraform AWS Provider - Cloud WAN](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_core_network)

## Future Enhancements

- [ ] Add Direct Connect Gateway attachment support
- [ ] Implement Site-to-Site VPN attachments
- [ ] Add Transit Gateway peering for migration scenarios
- [ ] Support for multiple network function groups
- [ ] Advanced routing based on performance/latency
