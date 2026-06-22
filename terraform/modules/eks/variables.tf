variable "cluster_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "gha_deploy_role_arn" {
  type = string
}

variable "dev_user_arns" {
  type        = list(string)
  default     = []
  description = "IAM user ARNs granted edit access to the observability namespace (enables kubectl port-forward)"
}
