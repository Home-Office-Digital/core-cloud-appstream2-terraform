output "fleet_instance_role_arn" {
  description = "IAM role ARN attached to AppStream fleets for streaming instance AWS API access."
  value       = local.fleet_instance_role_arn
}
