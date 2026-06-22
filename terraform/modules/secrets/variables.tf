variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "rds_password" {
  type      = string
  sensitive = true
}

variable "jwt_access_secret" {
  type      = string
  sensitive = true
}

variable "auth_email" {
  type      = string
  sensitive = true
}

variable "auth_email_pw" {
  type      = string
  sensitive = true
}

variable "ecs_execution_role_id" {
  type        = string
  description = "ID (name) of the ECS task execution role to attach the SSM read policy to"
}
