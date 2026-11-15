output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS account ID"
}

output "region" {
  value       = data.aws_region.current.name
  description = "AWS region"
}

output "vpc_id" {
  value       = var.vpc_id
  description = "VPC ID for MGN staging"
}

output "staging_subnet_ids" {
  value       = var.staging_subnet_ids
  description = "Subnet IDs to use in MGN replication templates"
}

output "staging_security_group_id" {
  value       = try(aws_security_group.mgn_staging[0].id, null)
  description = "Staging security group ID (if created)"
}
