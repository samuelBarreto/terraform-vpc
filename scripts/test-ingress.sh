#!/bin/bash

# Script de teste rápido para o Ingress Controller
# Uso: ./scripts/test-ingress.sh [NAMESPACE] [SERVICE_NAME] [TIMEOUT]
# Exemplo: ./scripts/test-ingress.sh ingress-nginx nginx-ingress-ingress-nginx-controller 60

set -e

# Parâmetros via linha de comando com valores padrão
NAMESPACE=${1:-"ingress-nginx"}
SERVICE_NAME=${2:-"nginx-ingress-ingress-nginx-controller"}
TIMEOUT=${3:-60}

echo "🧪 TESTE RÁPIDO DO INGRESS CONTROLLER"
echo "====================================="
echo ""
echo "📋 Parâmetros utilizados:"
echo "   Namespace: $NAMESPACE"
echo "   Serviço: $SERVICE_NAME"
echo "   Timeout: ${TIMEOUT}s"
echo ""

echo "🔍 Verificando se o serviço existe..."

# Verificar se o serviço existe
if ! kubectl get service $SERVICE_NAME -n $NAMESPACE >/dev/null 2>&1; then
    echo "❌ Serviço $SERVICE_NAME não existe!"
    echo "   Execute primeiro: ./scripts/validate-ingress.sh"
    exit 1
fi

echo "✅ Serviço existe"

echo ""
echo "🔍 Obtendo endereço do Load Balancer..."

# Obter endereço do Load Balancer
LB_HOSTNAME=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$LB_HOSTNAME" ]; then
    echo "❌ Load Balancer não tem endereço ainda"
    echo "   Aguardando..."
    
    # Aguardar o Load Balancer ficar pronto
    kubectl wait --for=condition=Ready service/$SERVICE_NAME -n $NAMESPACE --timeout=${TIMEOUT}s
    
    # Tentar novamente
    LB_HOSTNAME=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -z "$LB_HOSTNAME" ]; then
        echo "❌ Ainda não foi possível obter o endereço"
        exit 1
    fi
fi

echo "✅ Load Balancer: $LB_HOSTNAME"

echo ""
echo "🌐 Testando conectividade..."

# Testar conectividade
if curl -s --max-time 10 "http://$LB_HOSTNAME" >/dev/null 2>&1; then
    echo "✅ Load Balancer está respondendo"
else
    echo "⚠️  Load Balancer não está respondendo ainda"
    echo "   Isso é normal nos primeiros minutos após a criação"
fi

echo ""
echo "📊 Status dos recursos:"

echo "   Pods do Ingress Controller:"
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx

echo ""
echo "   Serviços no namespace:"
kubectl get services -n $NAMESPACE

echo ""
echo "🎉 Teste concluído!"
echo "   Endereço do Load Balancer: $LB_HOSTNAME" 