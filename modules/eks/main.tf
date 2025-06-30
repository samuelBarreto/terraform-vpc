# =============================================================================
# IAM ROLES
# =============================================================================

# IAM Role para o Cluster EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
  tags = var.tags
}

# IAM Role para os Node Groups
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.name}-eks-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
  tags = var.tags
}

# Attach policies to cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Attach policies to node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# =============================================================================
# IAM POLICY DOCUMENTS
# =============================================================================

data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# =============================================================================
# EKS CLUSTER
# =============================================================================

resource "aws_eks_cluster" "this" {
  name     = var.name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = merge(var.tags, {
    "Name" = "${var.name}-cluster"
  })
}

# =============================================================================
# MANAGED NODE GROUPS
# =============================================================================

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.value.name
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnet_ids
  version         = var.cluster_version

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  ami_type       = each.value.ami_type
  disk_size      = each.value.disk_size

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  force_update_version = each.value.force_update_version

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
  ]

  tags = merge(var.tags, {
    "Name" = "${var.name}-${each.value.name}-node-group"
  })
}

# =============================================================================
# EKS ADDONS
# =============================================================================

# VPC CNI Addon
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "vpc-cni"
  addon_version = "v1.19.6-eksbuild.1"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}

# CoreDNS Addon
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"
  addon_version = "v1.11.4-eksbuild.14"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}

# kube-proxy Addon
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"
  addon_version = "v1.31.9-eksbuild.2"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}

# =============================================================================
# AWS AUTH CONFIGMAP
# =============================================================================

locals {
  aws_auth_configmap_yaml = <<-EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks_node_group_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    %{for role in var.aws_auth_roles~}
    - rolearn: ${role.rolearn}
      username: ${role.username}
      groups:
        %{for group in role.groups~}
        - ${group}
        %{endfor~}
    %{endfor~}
  mapUsers: |
    %{for user in var.aws_auth_users~}
    - userarn: ${user.userarn}
      username: ${user.username}
      groups:
        %{for group in user.groups~}
        - ${group}
        %{endfor~}
    %{endfor~}
EOT
}

resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_node_group_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes"
        ]
      }
    ])
    mapUsers = yamlencode(var.aws_auth_users)
  }

  depends_on = [aws_eks_cluster.this]
}

# =============================================================================
# HELM PROVIDER CONFIGURATION
# =============================================================================

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

# =============================================================================
# HELM RELEASES
# =============================================================================

resource "helm_release" "apps" {
  for_each = var.helm_releases

  name             = each.value.name
  repository       = each.value.repository
  chart            = each.value.chart
  version          = each.value.version
  namespace        = each.value.namespace
  create_namespace = each.value.create_namespace

  dynamic "set" {
    for_each = each.value.set
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  values = each.value.values != null ? [yamlencode(each.value.values)] : []

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this,
    aws_eks_addon.vpc_cni,
    aws_eks_addon.coredns,
    aws_eks_addon.kube_proxy
  ]
}
