#!/bin/bash

# Script para atualizar o cluster EKS com configuração correta de autenticação
# Uso: ./scripts/update-cluster.sh [CLUSTER_NAME] [AWS_REGION] [AWS_PROFILE]

set -e

# Configurações padrão
CLUSTER_NAME=${1:-"my-eks-cluster"}
AWS_REGION=${2:-"us-east-1"}
AWS_PROFILE=${3:-"default"}

echo "🚀 Iniciando atualização do cluster EKS..."
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

# 4. Verificar se o aws-auth configmap existe e está correto
echo "🔐 Verificando aws-auth configmap..."
if kubectl get configmap aws-auth -n kube-system > /dev/null 2>&1; then
    echo "✅ aws-auth configmap existe"
else
    echo "⚠️ aws-auth configmap não encontrado, será criado pelo Terraform"
fi

# 5. Verificar se o namespace ingress-nginx existe
echo "🔍 Verificando namespace ingress-nginx..."
if kubectl get namespace ingress-nginx > /dev/null 2>&1; then
    echo "✅ namespace ingress-nginx existe"
else
    echo "⚠️ namespace ingress-nginx não encontrado, será criado pelo Terraform"
fi

# 6. Executar terraform plan com configuração específica
echo "📋 Executando terraform plan..."
echo "💡 Dica: Se houver erros de autenticação, o Terraform tentará recriar os recursos Kubernetes"

# Tentar executar o plan
if terraform plan; then
    echo "✅ terraform plan executado com sucesso!"
else
    echo "⚠️ terraform plan falhou, mas isso pode ser normal para recursos Kubernetes"
    echo "💡 Tentando aplicar diretamente..."
fi

# 7. Perguntar se deseja aplicar
echo ""
read -p "❓ Deseja aplicar as mudanças? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Aplicando mudanças..."
    terraform apply -auto-approve
    echo "✅ Atualização concluída!"
    
    # 8. Verificar se tudo está funcionando
    echo "🔍 Verificando status do cluster após atualização..."
    kubectl get nodes
    kubectl get pods -n kube-system | grep aws-auth
    kubectl get pods -n ingress-nginx 2>/dev/null || echo "Namespace ingress-nginx não encontrado (normal se não configurado)"
else
    echo "❌ Aplicação cancelada."
fi 