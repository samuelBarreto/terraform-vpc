#!/bin/bash

# Script para atualizar o cluster EKS diretamente (ignorando recursos Kubernetes problemáticos)
# Uso: ./scripts/update-cluster-direct.sh [CLUSTER_NAME] [AWS_REGION] [AWS_PROFILE]

set -e

# Configurações padrão
CLUSTER_NAME=${1:-"my-eks-cluster"}
AWS_REGION=${2:-"us-east-1"}
AWS_PROFILE=${3:-"default"}

echo "🚀 Iniciando atualização direta do cluster EKS..."
echo "📋 Configurações:"
echo "   Cluster: $CLUSTER_NAME"
echo "   Região: $AWS_REGION"
echo "   Profile: $AWS_PROFILE"
echo ""

# 1. Atualizar kubeconfig
echo "🔧 Atualizando configuração do kubectl..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME --profile $AWS_PROFILE

# 2. Verificar conectividade
echo "🔍 Verificando conectividade com o cluster..."
kubectl get nodes

# 3. Configurar variáveis de ambiente para o Terraform
echo "⚙️ Configurando ambiente para Terraform..."
export AWS_PROFILE=$AWS_PROFILE
export AWS_REGION=$AWS_REGION

# 4. Executar terraform plan apenas para recursos AWS (ignorando Kubernetes)
echo "📋 Executando terraform plan para recursos AWS..."
echo "💡 Este método atualiza apenas o cluster EKS e node groups, ignorando recursos Kubernetes"

# Executar plan com target específico para evitar recursos Kubernetes
terraform plan -target=module.eks.aws_eks_cluster.this -target=module.eks.aws_eks_node_group.this

# 5. Perguntar se deseja aplicar
echo ""
read -p "❓ Deseja aplicar as mudanças do cluster? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Aplicando mudanças do cluster..."
    terraform apply -auto-approve -target=module.eks.aws_eks_cluster.this -target=module.eks.aws_eks_node_group.this
    echo "✅ Atualização do cluster concluída!"
    
    # 6. Aguardar cluster ficar pronto
    echo "⏳ Aguardando cluster ficar pronto..."
    aws eks wait cluster-active --name $CLUSTER_NAME --region $AWS_REGION --profile $AWS_PROFILE
    echo "✅ Cluster está ativo!"
    
    # 7. Atualizar kubeconfig novamente
    echo "🔧 Atualizando kubeconfig após atualização..."
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME --profile $AWS_PROFILE
    
    # 8. Verificar se tudo está funcionando
    echo "🔍 Verificando status do cluster após atualização..."
    kubectl get nodes
    
    # 9. Perguntar se deseja atualizar os recursos Kubernetes
    echo ""
    read -p "❓ Deseja atualizar os recursos Kubernetes (aws-auth, helm releases)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🚀 Atualizando recursos Kubernetes..."
        terraform apply -auto-approve
        echo "✅ Atualização completa concluída!"
    else
        echo "ℹ️ Recursos Kubernetes não foram atualizados"
    fi
else
    echo "❌ Aplicação cancelada."
fi 