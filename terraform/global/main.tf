# ============================================================
# Svelte Rooms — Global (Persistent) Stack
#
# Contains: networking, ECR, secrets, OIDC/IAM, backups, budget,
# and ECS resources (temporary — removed in Phase 7 EKS cutover).
#
# State key intentionally kept as terraform.tfstate-v2 to match
# the existing root main.tf state; rename to global.tfstate in
# Phase 4 once the root main.tf is deleted.
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "svelte-rooms-tf-state"
    key          = "svelte-rooms/terraform.tfstate-v2"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_caller_identity" "current" {}

# Pre-existing AWS-managed role; verify with:
#   aws iam get-role --role-name ecsTaskExecutionRole
data "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"
}

# ============================================================
# MODULES
# ============================================================

module "network" {
  source               = "../modules/network"
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  environments         = var.environments
  container_port       = var.container_port
}

module "ecr" {
  source       = "../modules/ecr"
  project_name = var.project_name
  app_name     = var.app_name
}

module "secrets" {
  source                = "../modules/secrets"
  project_name          = var.project_name
  aws_region            = var.aws_region
  account_id            = data.aws_caller_identity.current.account_id
  rds_password          = var.rds_password
  jwt_access_secret     = var.jwt_access_secret
  auth_email            = var.auth_email
  auth_email_pw         = var.auth_email_pw
  ecs_execution_role_id = data.aws_iam_role.ecs_task_execution.id
}

module "iam_oidc" {
  source                 = "../modules/iam-oidc"
  project_name           = var.project_name
  aws_region             = var.aws_region
  account_id             = data.aws_caller_identity.current.account_id
  github_org             = var.github_org
  github_repo            = var.github_repo
  ecr_repository_arn     = module.ecr.repository_arn
  tf_state_bucket        = "svelte-rooms-tf-state"
  ecs_execution_role_arn = data.aws_iam_role.ecs_task_execution.arn
}

module "backups" {
  source              = "../modules/backups"
  project_name        = var.project_name
  notification_email  = var.budget_notification_email
  budget_limit_amount = "15"
}

# ============================================================
# MOVED BLOCKS
# Maps root-module resource addresses (old root main.tf) to their
# new module paths so Terraform updates state without destroying
# and recreating any existing resources.
# ============================================================

moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.main
}

moved {
  from = aws_internet_gateway.main
  to   = module.network.aws_internet_gateway.main
}

moved {
  from = aws_subnet.public
  to   = module.network.aws_subnet.public
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route_table_association.public
  to   = module.network.aws_route_table_association.public
}

moved {
  from = aws_security_group.ecs_tasks
  to   = module.network.aws_security_group.ecs_tasks
}

moved {
  from = aws_ecr_repository.app
  to   = module.ecr.aws_ecr_repository.app
}

moved {
  from = aws_ecr_lifecycle_policy.app
  to   = module.ecr.aws_ecr_lifecycle_policy.app
}

moved {
  from = aws_ssm_parameter.db_password
  to   = module.secrets.aws_ssm_parameter.db_password
}

moved {
  from = aws_ssm_parameter.jwt_secret
  to   = module.secrets.aws_ssm_parameter.jwt_secret
}

moved {
  from = aws_ssm_parameter.auth_email_pw
  to   = module.secrets.aws_ssm_parameter.auth_email_pw
}

moved {
  from = aws_iam_role_policy.ecs_task_execution_ssm
  to   = module.secrets.aws_iam_role_policy.ecs_task_execution_ssm
}
