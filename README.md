# AWS Global WAN Network Architecture

Terraform configuration for managing AWS Global WAN infrastructure.

## Overview

This repository manages:
- AWS Cloud WAN core network
- Network segments and route tables
- VPC and Transit Gateway attachments
- Cross-region connectivity
- Global network policies

## Architecture

AWS Global WAN provides a centralized network management solution for connecting VPCs, on-premises networks, and branch offices across AWS Regions.

## Getting Started

This workspace is managed by HCP Terraform:
- **Workspace**: aws-global-wan
- **Organization**: vitalemazo
- **Auto-apply**: Enabled
- **Region**: us-east-1 (primary)

## Prerequisites

- AWS account with appropriate permissions
- HCP Terraform workspace configured with OIDC authentication
- AWS IAM role: `hcp-oidc-role-aws-oidc-demo`

## Resources

- [AWS Cloud WAN Documentation](https://docs.aws.amazon.com/vpc/latest/cloudwan/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
