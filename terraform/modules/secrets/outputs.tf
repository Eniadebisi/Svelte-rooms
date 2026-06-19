output "db_password_arn" {
  value = aws_ssm_parameter.db_password.arn
}

output "jwt_secret_arn" {
  value = aws_ssm_parameter.jwt_secret.arn
}

output "auth_email_arn" {
  value = aws_ssm_parameter.auth_email.arn
}

output "auth_email_pw_arn" {
  value = aws_ssm_parameter.auth_email_pw.arn
}
