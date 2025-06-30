#!/bin/bash

# Script para testar a configuração do Route53
# Uso: ./scripts/test-route53.sh [DOMAIN_NAME] [AWS_REGION] [AWS_PROFILE]
# Exemplo: ./scripts/test-route53.sh name.com us-east-1 default

set -e

# Parâmetros via linha de comando com valores padrão
DOMAIN_NAME=${1:-"name.com"}
AWS_REGION=${2:-"us-east-1"}
AWS_PROFILE=${3:-"default"}

echo "🌐 TESTE DA CONFIGURAÇÃO ROUTE 53"
echo "================================="
echo ""
echo "📋 Parâmetros utilizados:"
echo "   Domínio: $DOMAIN_NAME"
echo "   Região: $AWS_REGION"
echo "   Perfil AWS: $AWS_PROFILE"
echo ""

echo "📋 Verificando zona hospedada..."

# Verificar se a zona hospedada existe
ZONE_ID=$(aws route53 list-hosted-zones --profile $AWS_PROFILE --query "HostedZones[?Name=='$DOMAIN_NAME.'].Id" --output text)

if [ -z "$ZONE_ID" ]; then
    echo "❌ Zona hospedada para $DOMAIN_NAME não encontrada!"
    echo "   Certifique-se de que o domínio está configurado no Route 53"
    exit 1
fi

echo "✅ Zona hospedada encontrada: $ZONE_ID"

echo ""
echo "🔍 Verificando registros DNS..."

# Verificar registros A existentes
echo "   Registros A para $DOMAIN_NAME:"
aws route53 list-resource-record-sets \
  --profile $AWS_PROFILE \
  --hosted-zone-id $ZONE_ID \
  --query "ResourceRecordSets[?Name=='$DOMAIN_NAME.' && Type=='A']" \
  --output table

echo ""
echo "   Registros A para www.$DOMAIN_NAME:"
aws route53 list-resource-record-sets \
  --profile $AWS_PROFILE \
  --hosted-zone-id $ZONE_ID \
  --query "ResourceRecordSets[?Name=='www.$DOMAIN_NAME.' && Type=='A']" \
  --output table

echo ""
echo "🔍 Obtendo endereço do Load Balancer..."

# Obter endereço do Load Balancer
LB_HOSTNAME=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$LB_HOSTNAME" ]; then
    echo "❌ Não foi possível obter o endereço do Load Balancer"
    echo "   Execute primeiro: ./scripts/validate-ingress.sh"
    exit 1
fi

echo "✅ Load Balancer: $LB_HOSTNAME"

echo ""
echo "🌐 Testando resolução DNS..."

# Testar resolução DNS
echo "   Testando $DOMAIN_NAME..."
if nslookup $DOMAIN_NAME >/dev/null 2>&1; then
    echo "✅ $DOMAIN_NAME resolve corretamente"
else
    echo "⚠️  $DOMAIN_NAME não resolve ainda (pode levar alguns minutos)"
fi

echo "   Testando www.$DOMAIN_NAME..."
if nslookup www.$DOMAIN_NAME >/dev/null 2>&1; then
    echo "✅ www.$DOMAIN_NAME resolve corretamente"
else
    echo "⚠️  www.$DOMAIN_NAME não resolve ainda (pode levar alguns minutos)"
fi

echo ""
echo "🔍 Verificando conectividade..."

# Testar conectividade HTTP
echo "   Testando HTTP para $DOMAIN_NAME..."
if curl -s --max-time 10 "http://$DOMAIN_NAME" >/dev/null 2>&1; then
    echo "✅ $DOMAIN_NAME está respondendo via HTTP"
else
    echo "⚠️  $DOMAIN_NAME não está respondendo via HTTP"
fi

echo "   Testando HTTP para www.$DOMAIN_NAME..."
if curl -s --max-time 10 "http://www.$DOMAIN_NAME" >/dev/null 2>&1; then
    echo "✅ www.$DOMAIN_NAME está respondendo via HTTP"
else
    echo "⚠️  www.$DOMAIN_NAME não está respondendo via HTTP"
fi

echo ""
echo "🎉 Teste do Route53 concluído!"
echo "=============================="
echo "📝 Resumo:"
echo "   ✅ Zona hospedada: $ZONE_ID"
echo "   ✅ Load Balancer: $LB_HOSTNAME"
echo "   ✅ Domínio: $DOMAIN_NAME"
echo "   ✅ Subdomínio: www.$DOMAIN_NAME"
echo ""
echo "🌐 URLs para testar:"
echo "   http://$DOMAIN_NAME"
echo "   http://www.$DOMAIN_NAME" 