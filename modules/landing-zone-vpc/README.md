# Landing Zone VPC Module

## Overview

This module creates application landing zone VPCs with Cloud WAN attachment for workload deployment. Includes optional EC2 test instances (t2.micro, free tier eligible) for connectivity validation across network segments.

## Architecture

```
┌────────────────────────────────────────────────────┐
│ Landing Zone VPC (e.g., 10.10.0.0/16)              │
│                                                    │
│  ┌──────────────────┐    ┌──────────────────────┐│
│  │ Private Subnet   │    │ Cloud WAN Attachment ││
│  │ (App Workloads)  │    │ Subnet               ││
│  │                  │    │                      ││
│  │ • EC2 Instances │    │                      ││
│  │ • Test Instance  │    │                      ││
│  └────────┬─────────┘    └──────────┬───────────┘│
│           │                         │            │
│           └──────────┬──────────────┘            │
│                      │                            │
│                 ┌────▼────┐                       │
│                 │ Cloud   │                       │
│                 │ WAN     │                       │
│                 │Attachment                       │
│                 └─────────┘                       │
└──────────────────────┬─────────────────────────────┘
                       │
                   Cloud WAN
                  Core Network
                  (Segment: prod/non-prod/shared)
```

## Traffic Flow

### Internet-Bound Traffic
1. EC2 Instance → Private Subnet
2. Private Subnet → Cloud WAN (via route table default route)
3. Cloud WAN → Inspection VPC (via segment-action send-via)
4. Inspection VPC → Network Firewall → NAT Gateway → Internet

### Inter-Segment Communication
1. Source VPC → Cloud WAN (segment A)
2. Cloud WAN → Inspection VPC (via network function group)
3. Inspection VPC → Network Firewall (inspection)
4. Network Firewall → Cloud WAN
5. Cloud WAN → Destination VPC (segment B)

**Note**: Prod and Non-Prod segments are isolated by Core Network policy. They cannot communicate with each other, but both can access shared services.

## Features

- **Segment-Based Attachment**: Automatically attaches to correct Cloud WAN segment via tags
- **Free Tier EC2 Instances**: Optional t2.micro instances for connectivity testing
- **Single or Multi-AZ**: Deploy across 1 or 2 availability zones
- **Security Groups**: Pre-configured for ICMP (ping) and optional SSH
- **User Data Script**: Installs networking tools for troubleshooting
- **Cost Optimized**: Single-AZ default configuration

## Usage

### Production Landing Zone

```hcl
module "landing_zone_prod" {
  source = "../../modules/landing-zone-vpc"

  vpc_name     = "prod-useast1-app"
  region       = "us-east-1"
  vpc_cidr     = "10.10.0.0/16"
  segment_name = "prod"

  core_network_id  = module.core_network.core_network_id
  core_network_arn = module.core_network.core_network_arn

  # Single-AZ for cost savings
  multi_az = false

  # Test instance
  create_test_instance = true

  tags = {
    Environment = "production"
    Segment     = "prod"
  }
}
```

### Non-Production Landing Zone

```hcl
module "landing_zone_nonprod" {
  source = "../../modules/landing-zone-vpc"

  vpc_name     = "nonprod-uswest2-app"
  region       = "us-west-2"
  vpc_cidr     = "172.16.0.0/16"
  segment_name = "non-prod"

  core_network_id  = module.core_network.core_network_id
  core_network_arn = module.core_network.core_network_arn

  # Multi-AZ for availability
  multi_az = true

  # Test instance
  create_test_instance = true
  enable_ssh           = true  # Allow SSH from RFC1918

  tags = {
    Environment = "non-production"
    Segment     = "non-prod"
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
| vpc_name | Name for the landing zone VPC | string | yes | - |
| region | AWS region for deployment | string | yes | - |
| vpc_cidr | VPC CIDR block | string | yes | - |
| segment_name | Cloud WAN segment (prod, non-prod, shared) | string | yes | - |
| core_network_id | Cloud WAN Core Network ID | string | yes | - |
| core_network_arn | Cloud WAN Core Network ARN | string | yes | - |
| multi_az | Deploy across 2 availability zones | bool | no | false |
| create_test_instance | Create t2.micro test instance | bool | no | true |
| enable_ssh | Allow SSH from RFC1918 ranges | bool | no | false |
| enable_cloudwatch_logs | Enable CloudWatch Logs | bool | no | false |
| tags | Additional resource tags | map(string) | no | {} |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | Landing zone VPC ID |
| vpc_arn | Landing zone VPC ARN |
| private_subnet_ids | Private subnet IDs |
| cloudwan_attachment_id | Cloud WAN attachment ID |
| segment_name | Attached segment name |
| test_instance_id | Test instance ID (if created) |
| test_instance_private_ip | Test instance private IP (if created) |
| deployment_summary | Complete deployment summary |

## Resources Created

### Networking
- 1 VPC
- 1-2 Private Subnets (depends on multi_az)
- 1-2 Cloud WAN Attachment Subnets
- 2-4 Route Tables

### Compute (Optional)
- 1 EC2 Instance (t2.micro, Amazon Linux 2023)
- 1 Security Group
- 1 CloudWatch Log Group (if enabled)

### Cloud WAN
- 1 VPC Attachment (tagged with segment)

## Cost Estimate (per VPC)

| Resource | Quantity | Monthly Cost |
|----------|----------|--------------|
| Cloud WAN Attachment | 1 | ~$5 |
| EC2 t2.micro (free tier eligible) | 1 | $0-$8 |
| CloudWatch Logs (if enabled) | 1 | ~$1 |
| **Total (single-AZ)** | - | **~$6-$14/month** |

*Free tier: 750 hours/month of t2.micro (1 instance running 24/7)*

## Deployment Time

- Initial Apply: ~5-10 minutes
- Cloud WAN attachment: ~2-3 minutes
- EC2 instance launch: ~2-3 minutes
- Route propagation: ~1-2 minutes

## Test Instance Details

### Installed Tools
- tcpdump - Network packet analyzer
- nmap-ncat - Network testing
- bind-utils - DNS tools
- traceroute - Route tracing
- curl/wget - HTTP clients
- jq - JSON processor

### Connectivity Testing

**From Test Instance:**
```bash
# Test internet connectivity
curl https://api.ipify.org  # Returns public NAT Gateway IP
ping 8.8.8.8

# Test inter-segment connectivity
ping <other-segment-ip>

# View routes
ip route

# DNS testing
nslookup amazon.com

# Check instance info
cat /root/instance-info.txt
```

### Accessing Test Instances

**Via AWS Systems Manager Session Manager (Recommended):**
```bash
# Production instance
aws ssm start-session --target <instance-id>

# Non-production instance (different region)
aws ssm start-session --target <instance-id> --region us-west-2
```

**Via SSH (if enabled):**
```bash
# From another instance in RFC1918 range
ssh ec2-user@<private-ip>
```

## Connectivity Testing Scenarios

### Scenario 1: Test Internet Egress
```bash
# From any test instance
curl https://api.ipify.org
# Should return NAT Gateway public IP
# Traffic flow: Instance → Cloud WAN → Inspection → NAT → Internet
```

### Scenario 2: Test Segment Isolation
```bash
# From prod instance
ping <non-prod-instance-ip>
# Should FAIL - prod and non-prod are isolated
```

### Scenario 3: Test Shared Services Access
```bash
# From prod or non-prod instance
ping <shared-services-instance-ip>
# Should WORK - shared segment is accessible from all
```

### Scenario 4: Verify Inspection
```bash
# Check Network Firewall logs
aws logs tail /aws/network-firewall/useast1-inspection --follow

# Look for your instance's private IP in logs
```

## Security Considerations

### Security Group Rules
- **ICMP Ingress**: Allowed from all RFC1918 ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
- **SSH Ingress**: Optionally allowed from RFC1918 ranges
- **All Egress**: Allowed to 0.0.0.0/0

### IMDSv2 Required
All EC2 instances enforce IMDSv2 (Instance Metadata Service v2) for improved security.

### No Public IPs
Test instances are deployed in private subnets with no public IP addresses. Internet access is via Cloud WAN → Inspection VPC → NAT Gateway.

## Important Notes

### Segment Tagging
The VPC attachment includes a `segment` tag that determines which Cloud WAN segment it's attached to. Ensure your Core Network policy includes tag-based attachment rules:

```hcl
attachment-policies = [
  {
    rule-number = 100
    condition-logic = "or"
    conditions = [
      {
        type = "tag-value"
        key = "segment"
        operator = "equals"
        value = "prod"
      }
    ]
    action = {
      association-method = "tag"
      segment = "prod"
    }
  }
]
```

### Single-AZ vs Multi-AZ
- **Single-AZ**: Lower cost (~$6-14/month per VPC), suitable for dev/test
- **Multi-AZ**: Higher availability, creates subnets in 2 AZs, suitable for production

### CIDR Planning
Ensure VPC CIDR ranges don't overlap:
- **Production**: 10.0.0.0/8 range
- **Non-Production**: 172.16.0.0/12 range
- **Shared Services**: 192.168.0.0/16 range

## Troubleshooting

### Attachment Stays Pending
**Issue**: Cloud WAN attachment in "PENDING" state

**Solution**:
- Verify Core Network policy includes tag-based attachment rules
- Check `segment` tag on attachment matches policy
- Wait 2-3 minutes for attachment to process

### No Internet Connectivity
**Issue**: Cannot reach internet from test instance

**Solution**:
- Verify route table has default route to Cloud WAN (`core_network_arn`)
- Check inspection VPC has NAT Gateway and Network Firewall
- Verify Network Firewall rules allow traffic
- Check security group allows outbound traffic

### Cannot Ping Between Segments
**Expected**: Prod and Non-Prod segments are isolated by design

**If you need connectivity**:
- Modify Core Network policy to allow specific segment-to-segment communication
- Or route traffic through shared services segment

### SSH Connection Fails
**Issue**: Cannot SSH to test instance

**Solution**:
- Verify `enable_ssh = true`
- Use AWS Systems Manager Session Manager (doesn't require SSH)
- Check security group allows SSH from your source IP

## Examples

See the `environments/dev` directory for complete deployment examples.

## Module Structure

```
landing-zone-vpc/
├── main.tf                    # VPC and subnets
├── cloudwan-attachment.tf     # Cloud WAN integration
├── route-tables.tf            # Route tables
├── security-groups.tf         # Security groups
├── ec2.tf                     # Test instances
├── user-data.sh               # Instance user data
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
└── README.md                  # This file
```

## Related Documentation

- [AWS Cloud WAN](https://docs.aws.amazon.com/vpc/latest/cloudwan/)
- [VPC Attachments](https://docs.aws.amazon.com/vpc/latest/cloudwan/cloudwan-vpc-attachments.html)
- [Tag-Based Routing](https://docs.aws.amazon.com/vpc/latest/cloudwan/cloudwan-policy-network-attachments.html)

## Version History

- **v1.0.0** (Phase 4) - Initial release with test instances
