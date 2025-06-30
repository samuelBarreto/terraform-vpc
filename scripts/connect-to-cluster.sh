#!/bin/bash

# Script para conectar ao cluster EKS
# Uso: ./scripts/connect-to-cluster.sh [CLUSTER_NAME] [AWS_REGION] [AWS_PROFILE]
# Exemplo: ./scripts/connect-to-cluster.sh my-eks-cluster us-east-1 default

set -e

# Parâmetros via linha de comando com valores padrão
CLUSTER_NAME=${1:-"my-eks-cluster"}
AWS_REGION=${2:-"us-east-1"}
AWS_PROFILE=${3:-"default"}

echo "🔗 Conectando ao cluster EKS..."
echo ""
echo "📋 Parâmetros utilizados:"
echo "   Cluster: $CLUSTER_NAME"
echo "   Região: $AWS_REGION"
echo "   Perfil AWS: $AWS_PROFILE"
echo ""

# Verificar se o cluster existe
echo "🔍 Verificando se o cluster existe..."
aws eks describe-cluster \
  --region $AWS_REGION \
  --profile $AWS_PROFILE \
  --name $CLUSTER_NAME \
  --query 'cluster.status' \
  --output text

# Atualizar kubeconfig
echo "⚙️  Atualizando kubeconfig..."
aws eks update-kubeconfig \
  --region $AWS_REGION \
  --profile $AWS_PROFILE \
  --name $CLUSTER_NAME

# Verificar conexão
echo "✅ Testando conexão com o cluster..."
kubectl get nodes

echo "🎉 Conectado com sucesso ao cluster EKS!"
echo ""
echo "📝 Comandos úteis:"
echo "   kubectl get nodes                    # Ver nodes do cluster"
echo "   kubectl get pods --all-namespaces    # Ver todos os pods"
echo "   kubectl get svc --all-namespaces     # Ver todos os serviços"
echo "   kubectl get ingress --all-namespaces # Ver ingress resources" 