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

variable "environments" {
  type    = list(string)
  default = ["dev", "qa", "prod"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
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
