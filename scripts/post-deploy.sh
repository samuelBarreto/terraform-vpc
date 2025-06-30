#!/bin/bash

# =============================================================================
# SCRIPT DE PÓS-DEPLOY - EKS CLUSTER
# =============================================================================
# Este script configura o kubectl e verifica o cluster após o deploy

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar se as variáveis de ambiente estão definidas
if [ -z "$CLUSTER_NAME" ]; then
    print_error "CLUSTER_NAME não está definido"
    print_message "Defina a variável CLUSTER_NAME ou use: export CLUSTER_NAME=seu-cluster"
    exit 1
fi

if [ -z "$AWS_REGION" ]; then
    print_error "AWS_REGION não está definido"
    print_message "Defina a variável AWS_REGION ou use: export AWS_REGION=us-east-1"
    exit 1
fi

# Definir perfil AWS padrão se não especificado
if [ -z "$AWS_PROFILE" ]; then
    AWS_PROFILE="default"
    print_warning "AWS_PROFILE não definido, usando: $AWS_PROFILE"
fi

print_header "CONFIGURAÇÃO PÓS-DEPLOY - EKS CLUSTER"
print_message "Cluster: $CLUSTER_NAME"
print_message "Região: $AWS_REGION"
print_message "Profile: $AWS_PROFILE"

# =============================================================================
# 1. CONFIGURAR KUBECTL
# =============================================================================

print_header "1. CONFIGURANDO KUBECTL"

print_message "Atualizando kubeconfig..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME --profile $AWS_PROFILE

if [ $? -eq 0 ]; then
    print_message "Kubeconfig atualizado com sucesso!"
else
    print_error "Falha ao atualizar kubeconfig"
    exit 1
fi

# =============================================================================
# 2. VERIFICAR CONEXÃO COM O CLUSTER
# =============================================================================

print_header "2. VERIFICANDO CONEXÃO COM O CLUSTER"

print_message "Testando conexão com o cluster..."
kubectl cluster-info

if [ $? -eq 0 ]; then
    print_message "Conexão com o cluster estabelecida!"
else
    print_error "Falha ao conectar com o cluster"
    print_message "Tentando reconectar..."
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME --profile $AWS_PROFILE
    kubectl cluster-info
    if [ $? -ne 0 ]; then
        print_error "Ainda não foi possível conectar ao cluster"
        print_message "Verifique se o cluster está ativo:"
        print_message "aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --profile $AWS_PROFILE"
        exit 1
    fi
fi

# =============================================================================
# 3. VERIFICAR NODES
# =============================================================================

print_header "3. VERIFICANDO NODES"

print_message "Listando nodes do cluster..."
kubectl get nodes -o wide

NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
print_message "Total de nodes: $NODE_COUNT"

# Verificar se todos os nodes estão prontos
READY_NODES=$(kubectl get nodes --no-headers | grep -c "Ready")
if [ "$NODE_COUNT" -eq "$READY_NODES" ]; then
    print_message "Todos os nodes estão prontos!"
else
    print_warning "Alguns nodes não estão prontos. Verifique o status."
    kubectl get nodes
fi

# =============================================================================
# 4. VERIFICAR NAMESPACES
# =============================================================================

print_header "4. VERIFICANDO NAMESPACES"

print_message "Listando namespaces..."
kubectl get namespaces

# =============================================================================
# 5. VERIFICAR PODS DO SISTEMA
# =============================================================================

print_header "5. VERIFICANDO PODS DO SISTEMA"

print_message "Verificando pods no namespace kube-system..."
kubectl get pods -n kube-system

# Verificar se os addons estão funcionando
print_message "Verificando addons do EKS..."

# CoreDNS
COREDNS_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-dns --no-headers | wc -l)
if [ "$COREDNS_PODS" -gt 0 ]; then
    print_message "CoreDNS: $COREDNS_PODS pods encontrados"
else
    print_warning "CoreDNS não encontrado"
fi

# AWS VPC CNI
CNI_PODS=$(kubectl get pods -n kube-system -l k8s-app=aws-node --no-headers | wc -l)
if [ "$CNI_PODS" -gt 0 ]; then
    print_message "AWS VPC CNI: $CNI_PODS pods encontrados"
else
    print_warning "AWS VPC CNI não encontrado"
fi

# kube-proxy
PROXY_PODS=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers | wc -l)
if [ "$PROXY_PODS" -gt 0 ]; then
    print_message "kube-proxy: $PROXY_PODS pods encontrados"
else
    print_warning "kube-proxy não encontrado"
fi

# =============================================================================
# 6. VERIFICAR HELM RELEASES
# =============================================================================

print_header "6. VERIFICANDO HELM RELEASES"

if command -v helm &> /dev/null; then
    print_message "Verificando Helm releases..."
    helm list --all-namespaces
else
    print_warning "Helm não está instalado. Instale o Helm para verificar releases."
fi

# =============================================================================
# 7. VERIFICAR AWS AUTH CONFIGMAP
# =============================================================================

print_header "7. VERIFICANDO AWS AUTH CONFIGMAP"

print_message "Verificando aws-auth ConfigMap..."
kubectl get configmap aws-auth -n kube-system -o yaml

# =============================================================================
# 8. TESTE DE CONECTIVIDADE
# =============================================================================

print_header "8. TESTE DE CONECTIVIDADE"

print_message "Criando pod de teste..."
kubectl run test-pod --image=busybox --restart=Never -- sleep 30

print_message "Aguardando pod ficar pronto..."
kubectl wait --for=condition=Ready pod/test-pod --timeout=60s

if [ $? -eq 0 ]; then
    print_message "Pod de teste criado com sucesso!"
    
    print_message "Testando conectividade de rede..."
    kubectl exec test-pod -- nslookup kubernetes.default
    
    print_message "Limpando pod de teste..."
    kubectl delete pod test-pod
else
    print_warning "Pod de teste não ficou pronto no tempo esperado"
fi

# =============================================================================
# 9. INFORMAÇÕES ÚTEIS
# =============================================================================

print_header "9. INFORMAÇÕES ÚTEIS"

print_message "Comandos úteis:"
echo "  kubectl get nodes                    # Listar nodes"
echo "  kubectl get pods --all-namespaces    # Listar todos os pods"
echo "  kubectl get services --all-namespaces # Listar todos os services"
echo "  kubectl cluster-info                 # Informações do cluster"
echo "  kubectl config view                  # Ver configuração kubectl"

print_message "Para acessar o cluster de outros locais:"
echo "  aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME"

print_message "Para verificar logs do cluster:"
echo "  aws logs describe-log-groups --log-group-name-prefix /aws/eks/$CLUSTER_NAME"

# =============================================================================
# 10. VERIFICAÇÃO FINAL
# =============================================================================

print_header "10. VERIFICAÇÃO FINAL"

print_message "Verificando status geral do cluster..."
kubectl get componentstatuses

print_message "Verificando eventos recentes..."
kubectl get events --sort-by='.lastTimestamp' | tail -10

print_header "DEPLOY CONCLUÍDO COM SUCESSO! 🎉"

print_message "Seu cluster EKS está pronto para uso!"
print_message "Cluster: $CLUSTER_NAME"
print_message "Região: $AWS_REGION"

print_warning "Lembre-se de:"
echo "  - Configurar RBAC adequado"
echo "  - Implementar políticas de segurança"
echo "  - Configurar monitoramento e alertas"
echo "  - Fazer backup regular dos dados"
echo "  - Manter o cluster atualizado"

print_message "Para mais informações, consulte a documentação no README.md" 