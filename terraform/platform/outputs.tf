output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "rds_identifier" {
  value       = aws_db_instance.main.identifier
  description = "Use with: aws rds stop-db-instance --db-instance-identifier <value>"
}

output "backup_role_arn" {
  value       = aws_iam_role.backup.arn
  description = "IRSA role ARN for the nightly backup CronJob — pass to helm --set backup.roleArn"
}
