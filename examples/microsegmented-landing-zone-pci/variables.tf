# Variables for PCI-Compliant Landing Zone Example

variable "aws_region" {
  description = "AWS region for PCI application"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name of the PCI application"
  type        = string
  default     = "payment-processor"
}

variable "global_network_id" {
  description = "ID of the AWS Cloud WAN Global Network"
  type        = string
}

variable "cloudfront_cidr" {
  description = "CloudFront CIDR for ALB ingress (use CloudFront managed prefix list in production)"
  type        = string
  default     = "0.0.0.0/0" # Replace with CloudFront prefix list
}

variable "corporate_vpn_cidr" {
  description = "Corporate VPN CIDR for bastion access"
  type        = string
  default     = "10.0.0.0/8"
}
