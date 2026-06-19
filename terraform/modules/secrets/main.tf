resource "aws_iam_role_policy" "ecs_task_execution_ssm" {
  name = "${var.project_name}-ecs-task-execution-ssm"
  role = var.ecs_execution_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ssm:GetParameters", "ssm:GetParameter"]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/${var.project_name}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "arn:aws:kms:${var.aws_region}:${var.account_id}:alias/aws/ssm"
      }
    ]
  })
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_name}/db-password"
  description = "Database password"
  type        = "SecureString"
  value       = var.db_password

  tags = { Project = var.project_name }
}

resource "aws_ssm_parameter" "jwt_secret" {
  name        = "/${var.project_name}/jwt-access-secret"
  description = "JWT access secret"
  type        = "SecureString"
  value       = var.jwt_access_secret

  tags = { Project = var.project_name }
}

# auth_email moved from plaintext task-def env var to SecureString (Phase 2 security fix)
resource "aws_ssm_parameter" "auth_email" {
  name        = "/${var.project_name}/auth-email"
  description = "Auth email address"
  type        = "SecureString"
  value       = var.auth_email

  tags = { Project = var.project_name }
}

resource "aws_ssm_parameter" "auth_email_pw" {
  name        = "/${var.project_name}/auth-email-pw"
  description = "Auth email password"
  type        = "SecureString"
  value       = var.auth_email_pw

  tags = { Project = var.project_name }
}
