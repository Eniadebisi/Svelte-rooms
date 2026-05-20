# ============================================================
# Reusable CI/CD Framework - AWS Infrastructure
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "svelte-rooms-tf-state"
    key    = "svelte-rooms/terraform.tfstate-v2"
    region = "us-east-1"
    #dynamodb_table = "svelte-tf-state-lock"
    use_lockfile = "false"
    encrypt      = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================
# VARIABLES
# ============================================================

variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy resources"
}

variable "project_name" {
  type        = string
  default     = "cicd-gh-action-test"
  description = "Project name used as a prefix for all resources"
}

variable "github_username" {
  type        = string
  description = "GitHub username"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo"
}

variable "environments" {
  type        = list(string)
  default     = ["dev", "qa", "prod"]
  description = "List of environments to create ECS clusters for"
}

variable "app_name" {
  type        = string
  default     = "svelte-rooms"
  description = "Application/service name (used in ECR repo and ECS service)"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "ECS task CPU units (256, 512, 1024, 2048, 4096)"
  type        = map(number)
  default = {
    dev  = 256
    qa   = 256
    prod = 512
  }
}

variable "task_memory" {
  type = map(number)
  default = {
    dev  = 512
    qa   = 512
    prod = 1024
  }
  description = "ECS task memory in MiB"
}

variable "desired_count" {
  type = map(number)
  default = {
    dev  = 1
    qa   = 1
    prod = 2
  }
  description = "Desired number of ECS tasks per environment"
}

variable "log_retention_days" {
  type = map(number)
  default = {
    dev  = 7
    qa   = 14
    prod = 30
  }
  description = "CloudWatch log retention in days"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "CIDR blocks for public subnets (one per AZ)"
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# ============================================================
# VPC & NETWORKING
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-subnet-${count.index + 1}"
    Project = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# SECURITY GROUPS
# ============================================================

resource "aws_security_group" "ecs_tasks" {
  for_each    = toset(var.environments)
  name        = "${var.project_name}-${each.key}-ecs-tasks-sg"
  description = "Allow inbound traffic for ECS tasks in ${each.key}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "App port"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${each.key}-ecs-tasks-sg"
    Project     = var.project_name
    Environment = each.key
  }
}

# ============================================================
# ECR 
# ============================================================

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}/${var.app_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep dev images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["qa-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 3
        description  = "Keep prod images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod-"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 10
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      }
    ]
  })
}

# ============================================================
# IAM 
# ============================================================

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ============================================================
# IAM - ECS Task Role (permissions FOR your app container)
# ============================================================

resource "aws_iam_role" "ecs_task" {
  for_each = toset(var.environments)
  name     = "${var.project_name}-${each.key}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Project     = var.project_name
    Environment = each.key
  }
}

resource "aws_iam_role_policy" "ecs_task_logs" {
  for_each = toset(var.environments)
  name     = "CloudWatchLogsWrite"
  role     = aws_iam_role.ecs_task[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.ecs[each.key].arn}:*"
    }]
  })
}

# ============================================================
# IAM - GitHub Actions Deployer Role
# ============================================================

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Project = var.project_name
  }
}


resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_repo}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name = "CICDDeployPolicy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = aws_ecr_repository.app.arn
      },
      {
        Sid    = "ECSDeployRead"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:ListTaskDefinitions",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECSDeployWrite"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:DeregisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Sid    = "PassRoleToECS"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          aws_iam_role.ecs_task_execution.arn,
          "arn:aws:iam:::role/*"
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================
# ECS CLUSTERS
# ============================================================

resource "aws_ecs_cluster" "env" {
  for_each = toset(var.environments)
  name     = "${var.project_name}-${each.key}"

  setting {
    name  = "containerInsights"
    value = each.key == "prod" ? "enabled" : "disabled"
  }

  tags = {
    Project     = var.project_name
    Environment = each.key
  }
}

resource "aws_ecs_cluster_capacity_providers" "env" {
  for_each     = toset(var.environments)
  cluster_name = aws_ecs_cluster.env[each.key].name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight            = 1
    base              = 1
  }
}

# ============================================================
# CLOUDWATCH LOG GROUPS
# ============================================================

resource "aws_cloudwatch_log_group" "ecs" {
  for_each          = toset(var.environments)
  name              = "/ecs/${var.project_name}/${each.key}/${var.app_name}"
  retention_in_days = var.log_retention_days[each.key]

  tags = {
    Project     = var.project_name
    Environment = each.key
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks" {
  for_each            = toset(var.environments)
  alarm_name          = "${var.project_name}-${each.key}-running-tasks-zeroed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "ECS ${each.key} running task count dropped below 1"
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.env[each.key].name
    ServiceName = "${var.project_name}-${each.key}-${var.app_name}"
  }

  tags = {
    Project     = var.project_name
    Environment = each.key
  }
}

# ============================================================
# ECS TASK DEFINITIONS
# ============================================================

resource "aws_ecs_task_definition" "app" {
  for_each                 = toset(var.environments)
  family                   = "${var.project_name}-${each.key}-${var.app_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu[each.key]
  memory                   = var.task_memory[each.key]

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task[each.key].arn

  container_definitions = jsonencode([
    {
      name      = var.app_name
      image     = "${aws_ecr_repository.app.repository_url}:${each.key}-latest"
      essential = true

      portMappings = [{
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }]

      environment = [
        { name = "ENVIRONMENT", value = each.key },
        { name = "PORT", value = tostring(var.container_port) }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs[each.key].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Project     = var.project_name
    Environment = each.key
  }
}

# ============================================================
# ECS SERVICES
# ============================================================

resource "aws_ecs_service" "app" {
  for_each        = toset(var.environments)
  name            = "${var.project_name}-${each.key}-${var.app_name}"
  cluster         = aws_ecs_cluster.env[each.key].id
  task_definition = aws_ecs_task_definition.app[each.key].arn
  desired_count   = var.desired_count[each.key]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  capacity_provider_strategy {
    capacity_provider = each.key == "prod" ? "FARGATE" : "FARGATE_SPOT"
    weight            = 1
    base              = 1
  }

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks[each.key].id]
    assign_public_ip = true
  }

  deployment_minimum_healthy_percent = each.key == "prod" ? 100 : 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Project     = var.project_name
    Environment = each.key
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution]
}

# ============================================================
# OUTPUTS
# ============================================================

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR repository URL — use in GitHub Actions to push images"
}

output "ecr_repository_arn" {
  value       = aws_ecr_repository.app.arn
  description = "ECR repository ARN"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM role ARN to use in GitHub Actions (configure as AWS_ROLE_ARN secret)"
}

output "ecs_cluster_names" {
  value       = { for env in var.environments : env => aws_ecs_cluster.env[env].name }
  description = "ECS cluster names per environment"
}

output "ecs_service_names" {
  value       = { for env in var.environments : env => aws_ecs_service.app[env].name }
  description = "ECS service names per environment"
}

output "cloudwatch_log_groups" {
  value       = { for env in var.environments : env => aws_cloudwatch_log_group.ecs[env].name }
  description = "CloudWatch log group names per environment"
}

output "task_definition_families" {
  value       = { for env in var.environments : env => aws_ecs_task_definition.app[env].family }
  description = "ECS task definition family names (used by CI/CD to register new revisions)"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs"
}
