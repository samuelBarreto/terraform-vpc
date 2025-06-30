# =============================================================================
# VPC OUTPUTS
# =============================================================================

output "vpc_id" {
  description = "ID da VPC"
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value = module.vpc.private_subnet_ids
}

# =============================================================================
# KMS OUTPUTS
# =============================================================================

output "kms_key_arn" {
  description = "ARN da KMS key para criptografia do EKS"
  value       = aws_kms_key.eks.arn
}

output "kms_key_id" {
  description = "ID da KMS key para criptografia do EKS"
  value       = aws_kms_key.eks.key_id
}

# =============================================================================
# EKS OUTPUTS
# =============================================================================

output "cluster_id" {
  description = "ID do cluster EKS"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "ARN do cluster EKS"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_version" {
  description = "Versão do Kubernetes do cluster EKS"
  value       = module.eks.cluster_version
}

output "cluster_oidc_issuer_url" {
  description = "URL do issuer OIDC do cluster"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_oidc_provider_arn" {
  description = "ARN do provider OIDC do cluster"
  value       = module.eks.cluster_oidc_provider_arn
}

output "cluster_iam_role_name" {
  description = "Nome da IAM role do cluster"
  value       = module.eks.cluster_iam_role_name
}

output "cluster_iam_role_arn" {
  description = "ARN da IAM role do cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "node_groups" {
  description = "Informações dos node groups"
  value       = module.eks.node_groups
}

output "node_group_iam_role_name" {
  description = "Nome da IAM role dos node groups"
  value       = module.eks.node_group_iam_role_name
}

output "node_group_iam_role_arn" {
  description = "ARN da IAM role dos node groups"
  value       = module.eks.node_group_iam_role_arn
}

output "kubeconfig" {
  description = "Configuração kubectl para o cluster"
  value       = module.eks.kubeconfig
  sensitive   = true
}

output "helm_releases" {
  description = "Informações dos Helm releases instalados"
  value       = module.eks.helm_releases
}