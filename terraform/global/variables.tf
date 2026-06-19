variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type        = string
  default     = "cicd-gh-action-test"
  description = "Project name prefix — do NOT rename; it is baked into ECR repo path and the qa→prod retag chain"
}

variable "app_name" {
  type    = string
  default = "svelte-rooms"
}

variable "environments" {
  type    = list(string)
  default = ["dev", "qa", "prod"]
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
  description = "Private subnets for EKS Fargate (pods must not be in public subnets)"
}

variable "db_password" {
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

variable "github_org" {
  type    = string
  default = "Eniadebisi"
}

variable "github_repo" {
  type    = string
  default = "Svelte-rooms"
}

variable "budget_notification_email" {
  type    = string
  default = "eniadebisi@nhneatl.org"
}
