variable "name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes para o cluster EKS"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID da VPC onde o cluster será criado"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets onde o cluster será criado"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas para os node groups"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs das subnets públicas para load balancers"
  type        = list(string)
}

variable "ingress_subnets" {
  description = "Subnets específicas para o Ingress Controller (opcional, sobrescreve public_subnet_ids)"
  type        = list(string)
  default     = null
}

variable "kms_key_arn" {
  description = "ARN da KMS key para criptografia"
  type        = string
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

variable "tags" {
  description = "Tags para aplicar aos recursos"
  type        = map(string)
  default     = {}
} 