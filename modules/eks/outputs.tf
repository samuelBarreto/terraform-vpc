output "cluster_id" {
  description = "ID do cluster EKS"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "ARN do cluster EKS"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.this.name
}

output "cluster_version" {
  description = "Versão do Kubernetes do cluster EKS"
  value       = aws_eks_cluster.this.version
}

output "cluster_certificate_authority_data" {
  description = "Dados do certificado de autoridade do cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "URL do issuer OIDC do cluster"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_oidc_provider_arn" {
  description = "ARN do provider OIDC do cluster"
  value       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
}

output "cluster_iam_role_name" {
  description = "Nome da IAM role do cluster"
  value       = aws_iam_role.eks_cluster_role.name
}

output "cluster_iam_role_arn" {
  description = "ARN da IAM role do cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "node_groups" {
  description = "Informações dos node groups"
  value = {
    for k, v in aws_eks_node_group.this : k => {
      id           = v.id
      arn          = v.arn
      name         = v.node_group_name
      status       = v.status
      scaling_config = v.scaling_config
      instance_types = v.instance_types
      subnet_ids   = v.subnet_ids
    }
  }
}

output "node_group_iam_role_name" {
  description = "Nome da IAM role dos node groups"
  value       = aws_iam_role.eks_node_group_role.name
}

output "node_group_iam_role_arn" {
  description = "ARN da IAM role dos node groups"
  value       = aws_iam_role.eks_node_group_role.arn
}

output "kubeconfig" {
  description = "Configuração kubectl para o cluster"
  value = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [
      {
        name = aws_eks_cluster.this.name
        cluster = {
          server                     = aws_eks_cluster.this.endpoint
          certificate-authority-data = aws_eks_cluster.this.certificate_authority[0].data
        }
      }
    ]
    contexts = [
      {
        name = aws_eks_cluster.this.name
        context = {
          cluster = aws_eks_cluster.this.name
          user    = aws_eks_cluster.this.name
        }
      }
    ]
    users = [
      {
        name = aws_eks_cluster.this.name
        user = {
          exec = {
            apiVersion = "client.authentication.k8s.io/v1beta1"
            command    = "aws"
            args = [
              "eks",
              "get-token",
              "--cluster-name",
              aws_eks_cluster.this.name,
              "--region",
              data.aws_region.current.id
            ]
          }
        }
      }
    ]
  })
  sensitive = true
}

output "helm_releases" {
  description = "Informações dos Helm releases instalados"
  value = {
    for k, v in helm_release.apps : k => {
      name      = v.name
      namespace = v.namespace
      version   = v.version
      status    = v.status
    }
  }
}

# Data sources para informações da conta AWS
data "aws_caller_identity" "current" {}
data "aws_region" "current" {} 