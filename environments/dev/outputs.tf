# Development Environment Outputs

output "global_network_id" {
  description = "ID of the Global Network"
  value       = module.core_network.global_network_id
}

output "core_network_id" {
  description = "ID of the Core Network"
  value       = module.core_network.core_network_id
}

output "core_network_arn" {
  description = "ARN of the Core Network"
  value       = module.core_network.core_network_arn
}

output "segment_names" {
  description = "List of network segment names"
  value       = module.core_network.segment_names
}

output "edge_locations" {
  description = "Regions where Core Network operates"
  value       = module.core_network.edge_locations
}

output "next_steps" {
  description = "Next steps for deployment"
  value       = <<-EOT
    Phase 1 Complete! ✅

    Core Network is deployed with ${length(module.core_network.segment_names)} segments.

    Next Steps:
    1. Verify in AWS Console:
       - Navigate to VPC > Cloud WAN > Core Networks
       - Check policy is active
       - Verify segments are created

    2. CLI Verification:
       aws networkmanager get-core-network --core-network-id ${module.core_network.core_network_id}

    3. Ready for Phase 2:
       - Deploy inspection VPC in us-east-1
       - See: DEPLOYMENT_PLAN.md > Phase 2

    Current Monthly Cost: ~$255 (Core Network only)
  EOT
}
