# Core Network Microsegmentation Module Outputs

output "global_network_id" {
  description = "ID of the Global Network"
  value       = aws_networkmanager_global_network.main.id
}

output "global_network_arn" {
  description = "ARN of the Global Network"
  value       = aws_networkmanager_global_network.main.arn
}

output "core_network_id" {
  description = "ID of the Core Network"
  value       = aws_networkmanager_core_network.main.id
}

output "core_network_arn" {
  description = "ARN of the Core Network"
  value       = aws_networkmanager_core_network.main.arn
}

output "microsegment_names" {
  description = "List of all microsegment names"
  value       = keys(local.microsegments)
}

output "microsegments" {
  description = "Map of all microsegments with their configurations"
  value = {
    for name, config in local.microsegments : name => {
      description      = config.description
      environment      = config.environment
      tier             = config.tier
      isolate          = config.isolate
      require_approval = config.require_approval
      allowed_segments = lookup(config, "allowed_segments", [])
      no_internet      = lookup(config, "no_internet", false)
    }
  }
}

output "production_microsegments" {
  description = "List of production microsegment names"
  value       = [for name, config in local.microsegments : name if config.environment == "production"]
}

output "nonproduction_microsegments" {
  description = "List of non-production microsegment names"
  value       = [for name, config in local.microsegments : name if config.environment == "non-production"]
}

output "shared_microsegments" {
  description = "List of shared services microsegment names"
  value       = [for name, config in local.microsegments : name if config.environment == "shared"]
}

output "b2b_microsegments" {
  description = "List of B2B partner microsegment names"
  value       = [for name, config in local.microsegments : name if config.environment == "b2b"]
}

output "edge_locations" {
  description = "Regions where Core Network operates"
  value       = var.edge_locations
}

output "inspection_enabled" {
  description = "Whether inspection routing is enabled"
  value       = var.enable_inspection_routing
}

output "pci_segment_enabled" {
  description = "Whether dedicated PCI segment is enabled"
  value       = var.enable_pci_segment
}

output "policy_document" {
  description = "The Core Network policy document"
  value       = local.policy_document
  sensitive   = false
}

output "microsegmentation_summary" {
  description = "Summary of microsegmentation configuration"
  value = {
    total_segments        = length(local.microsegments)
    production_segments   = length([for name, config in local.microsegments : name if config.environment == "production"])
    nonproduction_segments = length([for name, config in local.microsegments : name if config.environment == "non-production"])
    shared_segments       = length([for name, config in local.microsegments : name if config.environment == "shared"])
    b2b_segments          = length([for name, config in local.microsegments : name if config.environment == "b2b"])

    isolated_segments     = length([for name, config in local.microsegments : name if config.isolate])
    internet_restricted   = length([for name, config in local.microsegments : name if lookup(config, "no_internet", false)])

    inspection_enabled    = var.enable_inspection_routing
    pci_segment_enabled   = var.enable_pci_segment
    b2b_segments_enabled  = var.enable_b2b_segments
  }
}
