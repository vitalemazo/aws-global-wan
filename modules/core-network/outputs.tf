# Core Network Module Outputs

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

output "core_network_policy_document" {
  description = "The Core Network policy document as JSON"
  value       = jsonencode(local.policy_document)
}

output "segment_names" {
  description = "List of segment names"
  value       = keys(var.segments)
}

output "edge_locations" {
  description = "List of edge locations where Core Network operates"
  value       = var.edge_locations
}

output "inspection_routing_enabled" {
  description = "Whether inspection routing is enabled"
  value       = var.enable_inspection_routing
}
