# ============================================================
# EKS Cluster — Fargate-only, ephemeral (destroy when idle)
# ============================================================

# --- Cluster IAM role ---

resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# --- EKS Cluster ---

# trivy:ignore:AVD-AWS-0039
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = "1.31"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true # trivy:ignore:AVD-AWS-0040 # trivy:ignore:AVD-AWS-0041
  }

  access_config {
    authentication_mode = "API"
  }

  # Control-plane logging off to save CloudWatch cost
  enabled_cluster_log_types = []

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]

  tags = { Project = var.project_name }
}

# --- EKS OIDC provider (for IRSA — addons use service account roles) ---

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]

  tags = { Project = var.project_name }
}

# --- Fargate execution role ---

resource "aws_iam_role" "fargate_execution" {
  name = "${var.cluster_name}-fargate-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks-fargate-pods.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "fargate_execution" {
  role       = aws_iam_role.fargate_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# --- Fargate profiles ---

# kube-system: needed for CoreDNS and kube-proxy to run on Fargate
resource "aws_eks_fargate_profile" "kube_system" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.fargate_execution.arn
  subnet_ids             = var.private_subnet_ids

  selector { namespace = "kube-system" }

  depends_on = [aws_iam_role_policy_attachment.fargate_execution]
}

# apps: covers all app namespaces + observability
resource "aws_eks_fargate_profile" "apps" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "apps"
  pod_execution_role_arn = aws_iam_role.fargate_execution.arn
  subnet_ids             = var.private_subnet_ids

  selector { namespace = "qa" }
  selector { namespace = "prod" }
  selector { namespace = "observability" }

  depends_on = [aws_iam_role_policy_attachment.fargate_execution]
}

# --- vpc-cni IRSA role ---

data "aws_iam_policy_document" "vpc_cni_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.cluster.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.cluster.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_cni" {
  name               = "${var.cluster_name}-vpc-cni"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume.json
  tags               = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# --- EKS Addons ---

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  service_account_role_arn    = aws_iam_role.vpc_cni.arn
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_fargate_profile.kube_system]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"

  # Fargate patch: remove the ec2 compute-type annotation so CoreDNS schedules on Fargate
  configuration_values = jsonencode({
    tolerations = [
      {
        key      = "eks.amazonaws.com/compute-type"
        operator = "Equal"
        value    = "fargate"
        effect   = "NoSchedule"
      }
    ]
  })

  depends_on = [aws_eks_fargate_profile.kube_system]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_fargate_profile.kube_system]
}

# --- EKS Access entry — gives gha-deploy cluster-admin via API auth mode ---

resource "aws_eks_access_entry" "gha_deploy" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.gha_deploy_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "gha_deploy" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.gha_deploy_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.gha_deploy]
}

# --- Dev user access — edit on observability namespace (allows kubectl port-forward) ---

resource "aws_eks_access_entry" "dev_users" {
  for_each      = toset(var.dev_user_arns)
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "dev_users_observability" {
  for_each      = toset(var.dev_user_arns)
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["observability"]
  }

  depends_on = [aws_eks_access_entry.dev_users]
}
