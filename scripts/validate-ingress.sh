#!/bin/bash

# Script para validar o Ingress Controller
# Uso: ./scripts/validate-ingress.sh [NAMESPACE] [SERVICE_NAME] [TIMEOUT]
# Exemplo: ./scripts/validate-ingress.sh ingress-nginx nginx-ingress-ingress-nginx-controller 300

set -e

# Parâmetros via linha de comando com valores padrão
NAMESPACE=${1:-"ingress-nginx"}
SERVICE_NAME=${2:-"nginx-ingress-ingress-nginx-controller"}
TIMEOUT=${3:-300}

echo "🔍 VALIDANDO INGRESS CONTROLLER"
echo "================================="
echo ""
echo "📋 Parâmetros utilizados:"
echo "   Namespace: $NAMESPACE"
echo "   Serviço: $SERVICE_NAME"
echo "   Timeout: ${TIMEOUT}s"
echo ""

echo "📋 Verificando namespace $NAMESPACE..."

# Verificar se o namespace existe
if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    echo "❌ Namespace $NAMESPACE não existe!"
    echo "   Execute: kubectl get namespaces"
    exit 1
fi

echo "✅ Namespace $NAMESPACE existe"

echo ""
echo "🔍 Verificando se o serviço $SERVICE_NAME existe..."

# Verificar se o serviço existe
if ! kubectl get service $SERVICE_NAME -n $NAMESPACE >/dev/null 2>&1; then
    echo "❌ Serviço $SERVICE_NAME não existe no namespace $NAMESPACE!"
    echo "   Verificando todos os serviços no namespace:"
    kubectl get services -n $NAMESPACE
    exit 1
fi

echo "✅ Serviço $SERVICE_NAME existe"

echo ""
echo "🔍 Verificando status do Load Balancer..."

# Verificar se o Load Balancer já tem um endereço
LB_HOSTNAME=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -n "$LB_HOSTNAME" ]; then
    echo "✅ Load Balancer já está pronto!"
    echo "   Endereço: $LB_HOSTNAME"
    echo ""
    echo "🌐 Testando conectividade..."
    
    # Testar se o endereço responde
    if curl -s --max-time 10 "http://$LB_HOSTNAME" >/dev/null 2>&1; then
        echo "✅ Load Balancer está respondendo"
    else
        echo "⚠️  Load Balancer não está respondendo ainda (pode levar alguns minutos)"
    fi
else
    echo "⏳ Load Balancer ainda não está pronto, aguardando..."
    
    # Aguardar o Load Balancer ficar pronto
    echo "   Aguardando até $TIMEOUT segundos..."
    if kubectl wait --for=condition=Ready service/$SERVICE_NAME -n $NAMESPACE --timeout=${TIMEOUT}s; then
        echo "✅ Load Balancer ficou pronto!"
        
        # Obter o endereço final
        LB_HOSTNAME=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        echo "   Endereço: $LB_HOSTNAME"
    else
        echo "❌ Timeout aguardando Load Balancer ficar pronto"
        echo "   Verificando status do serviço:"
        kubectl describe service $SERVICE_NAME -n $NAMESPACE
        exit 1
    fi
fi

echo ""
echo "🔍 Verificando pods do Ingress Controller..."

# Verificar se os pods estão rodando
PODS_READY=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx --no-headers | grep -c "Running" || echo "0")
TOTAL_PODS=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx --no-headers | wc -l || echo "0")

echo "   Pods rodando: $PODS_READY/$TOTAL_PODS"

if [ "$PODS_READY" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
    echo "✅ Todos os pods do Ingress Controller estão rodando"
else
    echo "⚠️  Nem todos os pods estão rodando"
    kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx
fi

echo ""
echo "🎉 VALIDAÇÃO CONCLUÍDA!"
echo "========================="
echo "📝 Resumo:"
echo "   ✅ Namespace: $NAMESPACE"
echo "   ✅ Serviço: $SERVICE_NAME"
echo "   ✅ Load Balancer: $LB_HOSTNAME"
echo "   ✅ Pods: $PODS_READY/$TOTAL_PODS rodando"
echo ""
echo "🌐 Para testar o ingress, use:"
echo "   curl -H 'Host: seu-dominio.com' http://$LB_HOSTNAME" 