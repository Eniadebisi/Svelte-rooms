output "role_arn" {
  value       = aws_iam_role.gha_deploy.arn
  description = "ARN of the gha-deploy role — store as GHA_DEPLOY_ROLE_ARN in GitHub secrets"
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}
