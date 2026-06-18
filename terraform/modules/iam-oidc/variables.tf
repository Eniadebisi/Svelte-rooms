variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "github_org" {
  type        = string
  description = "GitHub organization or user name (case-sensitive)"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (case-sensitive)"
}

variable "ecr_repository_arn" {
  type = string
}

variable "tf_state_bucket" {
  type = string
}

variable "ecs_execution_role_arn" {
  type = string
}
