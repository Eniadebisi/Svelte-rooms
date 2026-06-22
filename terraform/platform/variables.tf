variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "cicd-gh-action-test"
}

variable "cluster_name" {
  type    = string
  default = "svelte-rooms"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "environments" {
  type    = list(string)
  default = ["qa", "prod"]
}

variable "jwt_access_secret" {
  type = map(string)
}

variable "auth_email" {
  type = map(string)
}

variable "auth_email_pw" {
  type = map(string)
}

variable "rds_password" {
  type      = string
  sensitive = true
  description = "RDS master password — shared across all environments (single DB instance)"
}

variable "dev_user_arns" {
  type        = list(string)
  default     = []
  description = "IAM user ARNs granted kubectl access to the observability namespace"
}
