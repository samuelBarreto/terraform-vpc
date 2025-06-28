variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "profile" {
  description = "AWS profile"
  type        = string
}

variable "name" {
  description = "Nome base dos recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
}

variable "availability_zones" {
  description = "Lista de AZs"
  type        = list(string)
}

variable "public_subnets" {
  description = "Lista de CIDRs das subnets públicas"
  type        = list(string)
}

variable "private_subnets" {
  description = "Lista de CIDRs das subnets privadas"
  type        = list(string)
}

variable "create_nat_gateway" {
  description = "Se deve criar NAT Gateway"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Ambiente (ex: dev, staging, prod)"
  type        = string
}

# =============================================================================
# EKS VARIABLES
# =============================================================================

variable "cluster_version" {
  description = "Versão do Kubernetes para o cluster EKS"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_private_access" {
  description = "Habilitar acesso privado ao endpoint do cluster"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Habilitar acesso público ao endpoint do cluster"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs permitidos para acesso público ao cluster"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "service_ipv4_cidr" {
  description = "CIDR para serviços Kubernetes"
  type        = string
  default     = "172.20.0.0/16"
}

variable "node_groups" {
  description = "Configuração dos node groups gerenciados"
  type = map(object({
    name                    = string
    instance_types         = list(string)
    capacity_type          = string
    min_size               = number
    max_size               = number
    desired_size           = number
    disk_size              = number
    ami_type               = string
    force_update_version   = bool
    labels                 = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {
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
      }
      taints = []
    }
  }
}

variable "aws_auth_users" {
  description = "Usuários para configurar no aws-auth ConfigMap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_roles" {
  description = "Roles para configurar no aws-auth ConfigMap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "helm_releases" {
  description = "Configuração dos Helm releases para instalar automaticamente"
  type = map(object({
    name             = string
    repository       = string
    chart            = string
    version          = string
    namespace        = string
    create_namespace = bool
    values           = any
    set = list(object({
      name  = string
      value = string
    }))
  }))
  default = {}
}

# =============================================================================
# CONFIGURAÇÕES DO EKS
# =============================================================================

# Variável opcional para subnets específicas do Ingress Controller
# Se não definida, usa as subnets públicas automaticamente
variable "ingress_subnets" {
  description = "Subnets específicas para o Ingress Controller"
  type        = list(string)
  default     = null
}
