# =============================================================================
# CONFIGURAÇÕES GERAIS
# =============================================================================

aws_region = "us-east-1"
profile    = "admin-samuel"
name       = "my-eks-cluster"
environment = "dev"

# =============================================================================
# CONFIGURAÇÕES DA VPC
# =============================================================================

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

private_subnets = [
  "10.0.11.0/24",
  "10.0.12.0/24",
  "10.0.13.0/24"
]

create_nat_gateway = true

# =============================================================================
# CONFIGURAÇÕES DO EKS
# =============================================================================

cluster_version = "1.29"

cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

service_ipv4_cidr = "172.20.0.0/16"

# =============================================================================
# CONFIGURAÇÕES DOS NODE GROUPS
# =============================================================================

node_groups = {
  default = {
    name                   = "default"
    instance_types         = ["t3.medium"]
    capacity_type          = "ON_DEMAND"
    min_size               = 1
    max_size               = 3
    desired_size           = 2
    disk_size              = 20
    ami_type               = "AL2_x86_64"
    force_update_version   = true
    labels = {
      "node.kubernetes.io/role" = "worker"
      "environment"             = "dev"
    }
    taints = []
  }
  
  # Exemplo de node group para aplicações críticas
  critical = {
    name                   = "critical"
    instance_types         = ["t3.large"]
    capacity_type          = "ON_DEMAND"
    min_size               = 1
    max_size               = 2
    desired_size           = 1
    disk_size              = 30
    ami_type               = "AL2_x86_64"
    force_update_version   = true
    labels = {
      "node.kubernetes.io/role" = "worker"
      "environment"             = "dev"
      "node-type"               = "critical"
    }
    taints = [
      {
        key    = "dedicated"
        value  = "critical"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}

# =============================================================================
# CONFIGURAÇÕES DO AWS AUTH
# =============================================================================

# Exemplo de usuários para acesso ao cluster
aws_auth_users = [
  {
    userarn  = "arn:aws:iam::123456789012:user/admin-user"
    username = "admin-user"
    groups   = ["system:masters"]
  }
]

# Exemplo de roles para acesso ao cluster
aws_auth_roles = [
  {
    rolearn  = "arn:aws:iam::123456789012:role/eks-admin-role"
    username = "eks-admin"
    groups   = ["system:masters"]
  }
]

# =============================================================================
# CONFIGURAÇÕES DOS HELM RELEASES
# =============================================================================

# Helm releases vazios por enquanto - você pode adicionar depois
helm_releases = {}

