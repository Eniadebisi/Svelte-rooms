output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL — store as ECR_REPOSITORY in GitHub secrets"
}

output "ecr_repository_arn" {
  value = module.ecr.repository_arn
}

output "gha_deploy_role_arn" {
  value       = module.iam_oidc.role_arn
  description = "gha-deploy IAM role ARN"
}

output "oidc_provider_arn" {
  value = module.iam_oidc.oidc_provider_arn
}

output "backups_bucket_name" {
  value = module.backups.bucket_name
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "private_route_table_id" {
  value = module.network.private_route_table_id
}

output "ecs_security_group_ids" {
  value = module.network.ecs_security_group_ids
}

output "ecs_task_execution_role_arn" {
  value = data.aws_iam_role.ecs_task_execution.arn
}

output "rds_password_arn" {
  value = module.secrets.rds_password_arn
}

output "jwt_secret_arn" {
  value = module.secrets.jwt_secret_arn
}

output "auth_email_arn" {
  value = module.secrets.auth_email_arn
}

output "auth_email_pw_arn" {
  value = module.secrets.auth_email_pw_arn
}
