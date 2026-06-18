# ============================================================
# Svelte Rooms — Platform (Ephemeral) Stack
#
# Safe to destroy and re-apply at any time.
# Persistent resources (VPC, ECR, OIDC, SSM) live in
# terraform/global and are referenced via remote state.
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "svelte-rooms-tf-state"
    key          = "svelte-rooms/platform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================
# GLOBAL STATE — read persistent outputs
# ============================================================

data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "svelte-rooms-tf-state"
    key    = "svelte-rooms/terraform.tfstate-v2"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}

locals {
  g = data.terraform_remote_state.global.outputs
}

# ============================================================
# EKS Cluster
# ============================================================

module "eks" {
  source = "../modules/eks"

  cluster_name        = var.cluster_name
  project_name        = var.project_name
  aws_region          = var.aws_region
  account_id          = data.aws_caller_identity.current.account_id
  vpc_id              = local.g.vpc_id
  private_subnet_ids  = local.g.private_subnet_ids
  gha_deploy_role_arn = local.g.gha_deploy_role_arn
}

# Tag private subnets for EKS (can't do this in global since cluster name is ephemeral)
resource "aws_ec2_tag" "private_subnet_eks" {
  count       = length(local.g.private_subnet_ids)
  resource_id = local.g.private_subnet_ids[count.index]
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

# ============================================================
# fck-nat — cheap NAT for private subnet egress (~$3/mo vs $33 for NAT GW)
# ============================================================

module "fck_nat" {
  source  = "RaJiska/fck-nat/aws"
  version = "~> 1.3"

  name      = "${var.project_name}-nat"
  vpc_id    = local.g.vpc_id
  subnet_id = local.g.public_subnet_ids[0]

  update_route_tables = true
  route_tables_ids    = { private = local.g.private_route_table_id }
}

# ============================================================
# RDS MySQL — destroy-when-idle; final snapshot retained on destroy
# ============================================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = local.g.private_subnet_ids

  tags = { Project = var.project_name }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow MySQL from within VPC"
  vpc_id      = local.g.vpc_id

  ingress {
    description = "MySQL from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = var.project_name }
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "svelte_rooms"
  username = "admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                  = false
  backup_retention_period   = 7
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-final-snapshot"

  # Stop billing when idle: aws rds stop-db-instance --db-instance-identifier <id>
  tags = { Project = var.project_name }
}

# ============================================================
# IRSA role for nightly backup CronJob — s3:PutObject only
# ============================================================

data "aws_iam_policy_document" "backup_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:prod:svelte-rooms-backup"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "${var.cluster_name}-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
  tags               = { Project = var.project_name }
}

resource "aws_iam_role_policy" "backup_s3" {
  name = "backup-s3-putobject"
  role = aws_iam_role.backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = "arn:aws:s3:::${local.g.backups_bucket_name}/*"
    }]
  })
}

# SSM params — all envs share one RDS instance; secrets are per-env for RBAC isolation
resource "aws_ssm_parameter" "db_host" {
  for_each = toset(var.environments)

  name  = "/svelte-rooms/${each.key}/db-host"
  type  = "String"
  value = aws_db_instance.main.address

  tags = { Project = var.project_name, Environment = each.key }
}

resource "aws_ssm_parameter" "db_password_env" {
  for_each = toset(var.environments)

  name        = "/svelte-rooms/${each.key}/db-password"
  type        = "SecureString"
  value       = var.db_password
  description = "RDS password for ${each.key}"

  tags = { Project = var.project_name, Environment = each.key }
}

resource "aws_ssm_parameter" "jwt_secret_env" {
  for_each = toset(var.environments)

  name        = "/svelte-rooms/${each.key}/jwt-access-secret"
  type        = "SecureString"
  value       = var.jwt_access_secret
  description = "JWT secret for ${each.key}"

  tags = { Project = var.project_name, Environment = each.key }
}

resource "aws_ssm_parameter" "auth_email_env" {
  for_each = toset(var.environments)

  name        = "/svelte-rooms/${each.key}/auth-email"
  type        = "SecureString"
  value       = var.auth_email
  description = "Auth email for ${each.key}"

  tags = { Project = var.project_name, Environment = each.key }
}

resource "aws_ssm_parameter" "auth_email_pw_env" {
  for_each = toset(var.environments)

  name        = "/svelte-rooms/${each.key}/auth-email-pw"
  type        = "SecureString"
  value       = var.auth_email_pw
  description = "Auth email password for ${each.key}"

  tags = { Project = var.project_name, Environment = each.key }
}
